# studio TODO

> 工作记忆的近端待办。版本计划见主仓 `data/roadmap/qtgame-war/`，设计共识见创始人档案仓 `qtgame-war/` 分区，规约见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 进行中：v0.1.0 任务 1 — 可注入战斗结算 + 随机源注入

三件套已落盘，**未验证、未提交**：

- [x] doc：`doc/models/combat.md`（新增 combat 规格：命中率模型、`rng` 注入接口、确定性契约）+ `doc/index.md` 依赖图同步
- [x] test：`test/models/combat_test.dart` 重写（确定性契约组：同种子双跑序列一致、不同种子允许偏离、随机源不被结算层重置）
- [x] lib：`combat.dart` 的 `resolveCombat` 的 `rng` 改 required，去掉内部 `Random()`；`GameController` 加 `final Random rng`（可注入，默认 `Random()`），`applyAttack` / `_aiStep` 两处调用传入

待办（按序）：

- [ ] 跑 `flutter test`（全绿约 74 项）——本轮终端工具故障未跑成
- [ ] 勾选 `ROADMAP.md` v0.1.0 待做第 1 组子项
- [ ] 提交 `qtgame-war` 子模块（先 `git add` 全部再提交，避免 pre-commit 闸门暂存区/工作区错位；提交信息避开禁用词）
- [ ] bump 父仓指针并推送

## v0.1.0 后续待做（顺序即依赖）

- [ ] 2. 可注入胜负策略：核心只调用，不预设规则
- [ ] 3. `applyMove` / `applyAttack` 拆为通用原语（进核心）+ 帝丘店修正（降为注入）；守卫唯一化（全部收进 CommandExecutor）；`GameController` 剩余帝丘店逻辑注入化（部署表 / 兵力表文案 / 伏击部署）
- [ ] 4. 剧本资产收尾：`CampaignConfig.load` 拆纯函数 `fromJson` + 薄 IO 壳、真实帝丘店 JSON 测试、`initial_huaye_power` 改通用名、`hexSize` 双源归一

完成后进入 v0.1.1 龙王店剧本注入（详见 `data/roadmap/qtgame-war/v0.1.1.md`）。
