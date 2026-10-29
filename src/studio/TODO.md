# studio TODO

> 工作记忆的近端待办。版本计划见主仓 `data/roadmap/qtgame-war/`，设计共识见创始人档案仓 `qtgame-war/` 分区，规约见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 进行中：任务 2 — 可注入胜负策略

ROADMAP 两条：胜负判断抽为注入策略（核心只调用，不预设规则）；帝丘店现有「占领核心」降为注入实现。

**现状核实**（四个条件 + 三处落盘点）：
- `game.dart` `checkVictory` 蓝胜两条写死在核心：红方全灭 → `config.victoryClearedText`；蓝方占 isCore 格且 `campaign.fortStrength <= 0` → `config.victoryCoreText`
- `game_controller.dart` `_aiStep` 败北两条写死在控制器：玩家全灭（战报后立判，文案「华野部队已无力再战，帝丘店未能攻克。」，return 不进新回合）；时间耗尽（`newTurn > 12`，详情文案「时间耗尽，援军逼近，华野被迫撤出战斗。」+ 战报「💀时间耗尽，未能攻克帝丘店。」turn 写死 0）
- 调用点：`game_controller.dart` 攻击后（L210）与回合末（L323）两处；构造点：`headquarters_screen.dart` L35 + `command_executor_test.dart`/`game_controller_test.dart` 各一处 `Game(config)`

**方案**：
- 核心新增 `lib/models/victory_policy.dart`：`VictoryResult{victory, detail, dispatches}` + `typedef VictoryPolicy = VictoryResult? Function(List<Unit> units, Campaign campaign, int turn)`，`null` = 未结束。核心只定义形状，不含任何条件
- `Game` 构造器加 `required VictoryPolicy victoryPolicy`；`checkVictory` 改转发：调策略，结果非 null 则落 `campaign.gameOver/victory/victoryDetail` 并返回 `dispatches`（条件判断与文案归策略，状态落盘与战报返回归核心）
- 帝丘店实现 `lib/campaigns/diqiudian_victory.dart`：四条件（红全灭胜、蓝占核心且工事 0 胜、玩家全灭败、`turn > 12` 败）。构造收 `CampaignConfig`（两条胜文案仍读 campaign.json 单一来源），两条败北详情文案 + 超时战报随迁；超时战报 turn 改透传评估回合（修正现写死 0）；`> 12` 魔数仅移文件不改值，改读 `config.maxTurns` 归任务 4
- `_aiStep` 两处失败手写块删除，统一改调 `engine.checkVictory`：战斗后玩家全灭点调 `checkVictory(units, campaign, currentTurn)` 后按 `campaign.gameOver` 转 gameOver 分支（等价性：该时点红方必有活单位、核心占领条件上一回合末已判过，完整评估不多触发）；回合末 `newTurn > 12` 块由 `checkVictory(newTurn)` 一并判
- 注入点：`headquarters_screen.dart` 构造处传 `diqiudianVictory(config)`；两处测试 `Game(config)` 同步补参

**边界（不做）**：`hitMod/moveMod` 阈值表留 v0.1.1；控制器战报专名清理留 v0.1.2（本次随迁仅两条败北详情 + 一条超时战报，「野司/华野」等其余战报不动）；`maxTurns`/`hexSize` 双源归一留任务 4；不动 `applyMove`/`applyAttack`/`CommandExecutor`（任务 3）

**红阶段纪律**：新测试引用尚不存在的 `VictoryPolicy`/`diqiudianVictory`，红就该红在符号缺失；禁止先写空实现占位。

步骤（doc → test → lib）：

- [x] 0. 本文件重写为本分解（任务 3 第 7 条已全绿收尾，进行中位让给任务 2）
- [ ] 1. doc：`doc/models/game.md` 方法表 `checkVictory` 行改签名（返回 `List<Dispatch>`），新增「胜负策略注入」节：`VictoryPolicy` 形状 + 边界（条件判断/文案归剧本策略，状态落盘/战报返回归核心，`campaign.victoryDetail` 等字段保持战役无关）——验收：无「核心预设胜负条件」表述
- [ ] 2. test：新 `test/campaigns/diqiudian_victory_test.dart` 四条件分支 + 两条败北文案 + 超时战报 turn 透传 + 未结束返回 null；`test/models/game_test.dart` `checkVictory` 转发测试（null → campaign 不变；有结果 → 三字段落盘 + dispatches 返回），Game 构造补桩 policy；`test/controllers/game_controller_test.dart` 种子冒烟回归 + 新增（策略返回败 → phase gameOver；超时 dispatch 进 logMessages）——验收：`flutter test` 红在符号缺失/断言失败
- [ ] 3. lib：`lib/models/victory_policy.dart` 定义；`lib/campaigns/diqiudian_victory.dart` 实现；`game.dart` 构造器加参 + `checkVictory` 改转发；`game_controller.dart` `_aiStep` 两处手写块改调 `checkVictory`；`headquarters_screen.dart` 注入帝丘店实现——验收：`flutter test` 全绿（77 回归 + 新增）；`grep -n "isCore\|victory\|12" lib/models/game.dart` 中无条件判断与魔数 12
- [ ] 4. 收尾：ROADMAP 任务 2 两条勾选；已知缺陷索引第 5 条同步（胜负详情/超时战报已迁策略实现，余战报专名留 v0.1.2）；本文件更新（本任务移入已交付，进行中位让给任务 3）——验收：勾选行与缺陷索引一致

## v0.1.0 后续待做（顺序即依赖）

- [ ] 3. `applyMove` / `applyAttack` 拆为通用原语（进核心）+ 帝丘店修正（降为注入）；守卫唯一化（全部收进 CommandExecutor）；`GameController` 剩余帝丘店逻辑注入化（部署表 / 兵力表文案 / 伏击部署）；消除 `_aiStep` 内联射程/掩体规则（改复用 `Game.getAttackTargets`）
- [ ] 4. 剧本资产收尾：`CampaignConfig.load` 拆纯函数 `fromJson` + 薄 IO 壳、真实帝丘店 JSON 测试、`initial_huaye_power` 改通用名、`hexSize` 双源归一、`maxTurns` 双源归一（魔数 12 已在 `diqiudian_victory.dart`，改读 `config.maxTurns`）
- [ ] 5. 控制器层确定性验证：`GameController` 同种子双跑测试（见 ROADMAP 第 5 组）

完成后进入 v0.1.1 龙王店剧本注入（详见 `data/roadmap/qtgame-war/v0.1.1.md`）。
