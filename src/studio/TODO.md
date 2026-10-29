# studio TODO

> 工作记忆的近端待办。版本计划见主仓 `data/roadmap/qtgame-war/`，设计共识见创始人档案仓 `qtgame-war/` 分区，规约见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 进行中：任务 3 第 7 条 — 敌军攻击走结算应用原语（方案已放行）

**方案约束**：抽侧别中立原语 `applyCombatOutcome`（落 takeDamage + markActed + 产 Dispatch），玩家、敌军两路都调它。禁止放宽 `applyAttack` 侧别守卫直接复用——`applyAttack` 绑定 `playerPower -= 3` 与 isCore→`fortStrength` 削减两条玩家专属语义，敌军走它等于敌人开枪、玩家倒贴战力。守卫归位与战果落盘是同一动作，一并完成，不拆两步；侧别专属资源结算留各调用方。

**核实结论**：`Unit.reveal()` 的读点全在红方侧（getAttackTargets / _aiStep 过滤 enemy.revealed、applyAttack 入守卫），蓝方零读点——enemy→player 方向调 `reveal()` 是笔误。敌军路径动词 = takeDamage + markActed + 战报；`reveal()` 留在玩家路径原地不碰。

**两处修订**：
- 修订一（假时钟）：测试不真实等待。选型 = `GameController` 构造器加 `aiDelay` 可注入时长（默认 500ms 保持现行为），测试注入 `Duration.zero`。fake_async 虽已在依赖（flutter_test 传递），不选它：zone 魔法对 `void async` 的 endTurn 可读性差，注入构造参数与 `rng` 注入同型，一次改动喂两张任务行。
- 修订二（三档跑全）：战报-落盘核对三档（未命中⇒hp 不变、命中⇒降 1、重创⇒降 2 且扣 0 封底）在 `combat_test.dart` 单元层注入桩 rng 各实际执行一遍；控制器种子测试只作集成冒烟（验证异步链路通 + 蓝方 hp 下降），不断文本、不断数值。

**红阶段纪律**：新测试引用尚不存在的 `applyCombatOutcome`，红就该红在符号缺失/断言失败；禁止先写空实现占位把红变绿。

步骤（doc → test → lib）：

- [x] 0. 本文件重写为本分解（执行清单；旧稿「未验证未提交」是假状态，已作废）
- [x] 1. doc：`doc/models/combat.md` 接口节加 `applyCombatOutcome` 签名，边界节改写（`resolveCombat` 纯结算；应用原语负责 takeDamage/markActed/战报；playerPower/fortStrength/reveal 归各调用方）——验收：无「敌军调 applyAttack」表述
- [x] 2. test：`test/models/combat_test.dart` 桩 rng 三档核对 + `applyCombatOutcome` 单元断言（hp 降、hasActed、Dispatch 消息/类型/回合透传）；`test/controllers/game_controller_test.dart` 种子冒烟（`aiDelay: Duration.zero`，断言蓝 1 号 hp 下降）——验收：`flutter test` 全红，红在原语/参数符号缺失或断言失败
- [x] 3. lib：`lib/models/combat.dart` 加 `applyCombatOutcome`；`applyAttack` 改调原语（`playerPower -= 3`、isCore→fortStrength、`reveal` 留原地）；`_aiStep` 改 resolveCombat+原语、战报入 `logMessages`；`GameController` 构造器加 `aiDelay`（默认 500ms）——验收：`flutter test` 全绿（77 回归 + 新增）
- [x] 4. 收尾：ROADMAP 任务 3 第 7 条动词修正（takeDamage/reveal → takeDamage/markActed/战报）并勾选；已知缺陷索引第 1 条同步；跨版本纪律落一行「红方 hasActed 现无代码读取，将来 AI 按 hasActed 做闸门须回合末重置红方」——验收：勾选行无 reveal 字样

## v0.1.0 后续待做（顺序即依赖）

- [ ] 2. 可注入胜负策略：核心只调用，不预设规则
- [ ] 3. `applyMove` / `applyAttack` 拆为通用原语（进核心）+ 帝丘店修正（降为注入）；守卫唯一化（全部收进 CommandExecutor）；`GameController` 剩余帝丘店逻辑注入化（部署表 / 兵力表文案 / 伏击部署）
- [ ] 4. 剧本资产收尾：`CampaignConfig.load` 拆纯函数 `fromJson` + 薄 IO 壳、真实帝丘店 JSON 测试、`initial_huaye_power` 改通用名、`hexSize` 双源归一

完成后进入 v0.1.1 龙王店剧本注入（详见 `data/roadmap/qtgame-war/v0.1.1.md`）。
