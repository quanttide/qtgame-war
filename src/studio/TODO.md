# studio TODO

> 工作记忆的近端待办。版本计划见主仓 `data/roadmap/qtgame-war/`，设计共识见创始人档案仓 `qtgame-war/` 分区，规约见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 已交付

### 任务 2 — 可注入胜负策略（2026-10-29 完成）

- 核心：`lib/models/victory_policy.dart` 定形状（`VictoryPolicy` 签名含 `TerrainBook`——核心据点判断要查地形属性，较原分解的三参签名多传一个）；`Game.checkVictory` 降为调用+落盘+返回战报，`gameOver` 已置位不再评估
- 剧本：`lib/campaigns/diqiudian_victory.dart` 四条件（红全灭胜/占核心且工事 0 胜/蓝全灭败/`turn > 12` 败）+ 文案 + 超时战报（turn 透传，修正原写死 0）
- `game_controller.dart` 两处手写失败块删除，胜负出口收敛到 `checkVictory`；`headquarters_screen.dart` 注入 `diqiudianVictory(config)`
- 测试 77 → 93：策略四条件分支、`checkVictory` 转发/落盘/已结束不评估、控制器判败转 gameOver、超时战报入 logMessages
- 收尾已同步：ROADMAP 任务 2 勾选、已知缺陷索引改「控制器余 3 处专名，胜负详情/超时战报已迁策略实现」；复盘四缺陷已登记 ROADMAP（评估时序耦合、gameOver 双标志、战报无结构、注入双通道）

## 进行中：v0.1.0 组 4「剧本资产收尾」（2026-10-29 抽取分解）

**为何是它**：ROADMAP 组 4 组头前置声明「宜先于组 3 的注入化大改与 v0.1.1『战力换算规则降为注入』开工，减小返工」。本组全是 schema 级改动（JSON key 改名、假字段删除、魔数归配置），现在动一次到位，组 3 与 v0.1.1 的注入化就不必二次返工；五行无前置、改动面小、可独立绿。组 3 是大改，留给资产收尾之后。

**现状核实**（2026-10-29 对照代码）：
- `CampaignConfig.load`（`game.dart`）rootBundle IO 与 JSON 解析 inline 混在一起，`fromJson` 无从单测
- 真实资产 `assets/campaigns/diqiudian/{campaign,map,units}.json` 零测试
- `hexSize` 双源实测：`Battlefield.hexSize`（static 27）被几何与 `battlefield_view.dart` 读取；`config.hexSize` 从 JSON 解析后无几何读点——假注入
- 魔数 12 已随任务 2 迁入 `lib/campaigns/diqiudian_victory.dart`（`turn > 12`），ROADMAP 组 4 第 5 条「`_aiStep` 写死 12」描述过期，本次同步
- 手抄 `CampaignConfig` 的测试文件实测 7 个（ROADMAP 写「五个」，一并修正）

**方案决断**（`hexSize` 二选一，已决）：删 `config.hexSize` 字段与 campaign.json 的 `hex_size` key，`Battlefield.hexSize` 明记为跨剧本表现常量。理由：像素尺寸是 UI 渲染参数，不是剧本事实；「几何收注入值」要动 TerrainBook/几何/视图全链，扩大改动面且无剧本差异化需求。

**红阶段纪律**：新测试引用尚不存在的 `fromJson`/`makeTestConfig`，红就该红在符号缺失；禁止先写空实现占位。

步骤（doc → test → lib）：

- [x] 0. 本文件重写为本分解
- [ ] 1. doc：`doc/models/game.md` CampaignConfig 节写明「`fromJson(campaignJson, mapJson, unitsJson)` 纯函数 + `load` 薄 IO 壳」；字段表删 `hexSize` 行；变更记录加 key 改名、`hexSize` 字段删除两条——验收：doc 无 `hex_size` 残留表述
- [ ] 2. test：`fromJson` 单元测试（`dart:io` File 读三份真实 JSON 传入，断言 name/`max_turns`/`initial_player_power`/templates/units 非空/mapGrid 尺寸与 grid_cols、rows 一致/catalog 含 is_core）；`max_turns: N` 驱动第 N+1 回合判败的控制器测试；`test/fixtures.dart` 抽 `makeTestConfig({...覆盖项})` builder 并重构 7 个测试文件改用——验收：`flutter test` 红在符号缺失；故意改坏 map.json 一个地形 id 时真实资产测试变红
- [ ] 3. lib：`game.dart` 拆 `fromJson(c, m, u)` 纯函数，`load` 只留 IO + decode + 调用；JSON key `initial_huaye_power` → `initial_player_power` 并同步 campaign.json；删 `CampaignConfig.hexSize` 字段与解析（`battlefield_view.dart` 已读 static，不动）；`diqiudian_victory.dart` `turn > 12` 改 `turn > config.maxTurns`——验收：`flutter test` 全绿；`grep -rn "hex_size\|huaye" lib/ assets/` 零命中
- [ ] 4. 收尾：ROADMAP 组 4 五条勾选（第 2 条「五个」→「七个」、第 5 条魔数新家同步、`hexSize` 条记录已决方向）；已知缺陷索引 `maxTurns` 条同步；本文件更新——验收：索引与勾选行一致

## v0.1.0 后续待做（顺序已按 ROADMAP 前置声明调整：组 4 → 组 3 → 组 5）

- [ ] 3. 原语拆分 + `GameController` 注入化 + 状态所有权收口（三线详见 ROADMAP 组 3；开工前按组内任务行分解，胜负评估收敛随守卫唯一化同批）
- [ ] 5. 控制器层确定性验证：`GameController` 同种子双跑测试——宜在 v0.1.1「endTurn 改可等待」落地后做

完成后进入 v0.1.1 龙王店剧本注入（详见 `data/roadmap/qtgame-war/v0.1.1.md`）。
