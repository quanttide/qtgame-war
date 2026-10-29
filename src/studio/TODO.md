# studio TODO

> 工作记忆的近端待办。版本计划见主仓 `data/roadmap/qtgame-war/`，设计共识见创始人档案仓 `qtgame-war/` 分区，规约见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 已交付

### 任务 2 — 可注入胜负策略（2026-10-29 完成）

- 核心：`lib/models/victory_policy.dart` 定形状（`VictoryPolicy = VictoryResult? Function(List<Unit>, Campaign, int turn, TerrainBook)`——偏差：原分解稿 3 参，执行现场发现占领条件依赖 terrain.isCore，升级 4 参避免 TerrainBook 双源——裁决 2026-10-29）；`Game.checkVictory` 降为调用+落盘+返回战报，`gameOver` 已置位不再评估
- 剧本：`lib/campaigns/diqiudian_victory.dart` 四条件（红全灭胜/占核心且工事 0 胜/蓝全灭败/`turn > 12` 败）+ 文案 + 超时战报（turn 透传，修正原写死 0）
- `game_controller.dart` 两处手写失败块删除，胜负出口收敛到 `checkVictory`；`headquarters_screen.dart` 注入 `diqiudianVictory(config)`
- 测试 77 → 93：策略四条件分支、`checkVictory` 转发/落盘/已结束不评估、控制器判败转 gameOver、超时战报入 logMessages
- 收尾已同步：ROADMAP 任务 2 勾选、已知缺陷索引第 5 条改「控制器余 3 处专名，胜负详情/超时战报已迁策略实现」

## v0.1.0 后续待做（顺序即依赖）

- [ ] 3. `applyMove` / `applyAttack` 拆为通用原语（进核心）+ 帝丘店修正（降为注入）；守卫唯一化（全部收进 CommandExecutor）；`GameController` 剩余帝丘店逻辑注入化（部署表 / 兵力表文案 / 伏击部署）；消除 `_aiStep` 内联射程/掩体规则（改复用 `Game.getAttackTargets`）——开工前先按 ROADMAP 组内任务行分解
- [ ] 4. 剧本资产收尾：`CampaignConfig.load` 拆纯函数 `fromJson` + 薄 IO 壳、真实帝丘店 JSON 测试、`initial_huaye_power` 改通用名、`hexSize` 双源归一、`maxTurns` 双源归一（魔数 12 已在 `diqiudian_victory.dart`，改读 `config.maxTurns`）
- [ ] 5. 控制器层确定性验证：`GameController` 同种子双跑测试（见 ROADMAP 第 5 组）

完成后进入 v0.1.1 龙王店剧本注入（详见 `data/roadmap/qtgame-war/v0.1.1.md`）。
