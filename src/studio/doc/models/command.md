# Command 模块

执行层载体。翻译层的输出、战棋引擎的输入。Command 把一个纵队的 Task 姿态在**当前战场态势**下具体化为带坐标的指令：移到哪、打谁、本回合是否有效。

## 与 Task 的关系

```
Task      姿态，无坐标     「1纵这回合围困」
   ↓  translateOrders（本模块配套的翻译层）
Command   指令，带坐标     「1纵 移到(4,3) → 攻击(5,4)」
```

Task 回答「干什么」，Command 回答「具体怎么干」。同一 Task 在不同态势下翻译出不同 Command（要塞在哪、援军在哪、路上有没有敌军）。故 Command 含坐标与目标，Task 不含。

## 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| unitId | int | 受令纵队 |
| task | TaskType | 溯源：这条命令来自哪个姿态 |
| moveTo | (int,int)? | 移动目标格；null 不移动 |
| attack | (int,int)? | 攻击目标格；null 不攻击 |
| issuedTurn | int | 下令回合 |
| deadlineTurn | int | 时限：最迟生效回合，v0.1.0 恒等于 issuedTurn（单回合令） |
| status | CommandStatus | 执行状态，见下 |
| resultText | String? | 执行后的战报片段 |

一条 Command = 「先 moveTo，若 attack 非空且敌仍在射程则再 attack」。与引擎点击路径「移动后可攻击」的语义一致，故不拆成两条。

## 状态机

```
pending ──执行──> executed      （移动且/或攻击完成）
   │
   ├─无法执行──> blocked        （无路可达 或 目标不在射程）
   └─超时────> expired          （deadlineTurn 已过仍未执行）
```

v0.1.0 单回合内即发即执行，`expired` 只作为跨回合长命令（Phase C3）预留，本版不触发。

## 翻译规则（`translateOrders`）

输入：`assignments`（unitId → Task）+ 存活单位 + 引擎（复用 `getMoveRange`/`hexDistance`）+ 两个目标坐标（要塞格 `fortPos`、援军格 `reliefPos`）。

逐单位：

1. **定目标**：Task 在 `assaultTargets` → 目标 = `fortPos`；在 `reliefTasks` → 目标 = `reliefPos`；`standby` → hold（不移动不攻击）。
2. **选移动**：在 `getMoveRange` 可达格中取距目标 `hexDistance` 最小者。已在目标邻接/射程内则原地不动。无可达格 → `blocked`。
3. **选攻击**：从落位算，取射程内一个「已暴露的红方、且非满掩体隔一格」的敌军。有则填 `attack`，无则只移动。

翻译层不掷骰、不改状态——它是纯函数，产出待执行的 Command 列表。结算由引擎执行时完成。

## 执行规则（CommandExecutor）

`translateOrders` 产出 Command 后，由 `CommandExecutor` 批量执行：命令序列 → 引擎原语（`applyMove`/`applyAttack`）→ 战报。守卫集中在执行器一处，调用方不再各自内联复制。

守卫（按序，命中即拒绝整条命令）：

| 情形 | 结果 |
|------|------|
| `deadlineTurn` 已过 | `expired`（跨回合长命令预留，v0.1.0 不触发） |
| unitId 无对应存活单位 | `blocked` |
| 不归我方（非蓝方） | `blocked` |
| 本回合已行动（含同批前一条命令刚执行过） | `blocked` |
| 空令（无移动无攻击，如 standby） | `executed`：只登记姿态，不算行动 |

执行：

1. 有 `moveTo` → `applyMove`；无路可达 → 整条 `blocked`，不再尝试攻击。**原地不动须表达为 `moveTo: null`**——`getMoveRange` 结尾排除原地格，移到同格会被判「不可达」。
2. 有 `attack` → 找目标格敌军 → `applyAttack`。目标不在射程/已撤离：无移动则整条 `blocked`；有移动则移动算数，`executed` 并记「攻击落空」。
3. 任一动作成功 → 登记姿态（`unit.task`）、标记已行动、`executed`。

逐条独立：一条 `blocked`/`expired` 不影响同批其余命令。`executeAll` 汇总全部战报，追加进战报流并通知一次。

## 归属

- `lib/models/command.dart` — Command / CommandStatus（纯数据）
- `lib/controllers/command_translator.dart` — `translateOrders`（纯函数）
- `lib/controllers/command_executor.dart` — `CommandExecutor`（守卫 + 批量执行）

## 变更记录

- 初版：Command 模型 + 翻译规则；Command 单条含可选 move/attack，对应引擎「移动后攻击」语义
- v0.1.0：新增 CommandExecutor——守卫集中、批量执行、战报汇总（详见「执行规则」节）
