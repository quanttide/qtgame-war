# 架构约束

贯穿 v0.1.x 的三条硬约束。

## 通用核心加剧本注入

引擎核心（战场状态、命令执行、战斗结算、胜负判断）不绑定任何剧本。剧本 = 数据加策略注入：地形、单位模板、战斗修正、胜负条件、指挥官档位全部由剧本提供。帝丘店与龙王店都是核心之上的两个剧本。核心代码里检索不到「帝丘店」「playerPower」这类剧本专属符号。

教训：一开始按帝丘店这一特定剧本建引擎（`playerPower` 0-100 标量、`fortStrength`、硬编码 `checkVictory`、`TerrainType` 枚举带帝丘店名），是方向性错误，早期未能纠正。现在改：先立通用核心，再让剧本注入，不再为核心打剧本补丁。

## 红蓝语义相反

studio `Side.blue` 是华野、是玩家方，`Side.red` 是国军；而龙王店原型与中文战棋惯例均是红方为我方。移植时显式核对敌我，防「敌我颠倒」级错误。

## 模型签名 Campaign-free

`applyMove`/`applyAttack` 已公开、不依赖点击态，但体内仍改 `playerPower`/`fortStrength`、调帝丘店 `checkVictory`。更深一层：`Unit.effectiveMoveRange(Campaign)`、`resolveCombat(..., Campaign, ...)` 的签名里就收 `Campaign`，而 `Campaign` 是帝丘店模型（含 `playerPower` 0-100 标量与 `hitMod`/`moveMod` 派生）。

只要签名还收 `Campaign`，任何调用方（含未来的 CommandExecutor）都被传染帝丘店耦合。通用核心的前提是模型签名 Campaign-free：`effectiveMoveRange`/`resolveCombat` 改收注入的修正标量（int），不收整个剧本状态对象。
