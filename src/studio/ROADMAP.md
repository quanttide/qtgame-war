# studio ROADMAP

> **当前版本线：v0.0 → v0.1.x**（落地线），进行中：**v0.0.1 可玩 Demo**。
>
> 本文件是 qtgame-war 的**工作记忆**：任务随工作动态调整，开工前读、变化即改。设计共识在创始人档案仓 `qtgame-war/` 分区；三层互动规则见 [CONTRIBUTING.md](CONTRIBUTING.md)。模块规格在本目录 `doc/models/`。
>
> **编号说明**：v0.0.1–v0.1.x 以本文件为准；主仓 `data/roadmap/qtgame-war/` 基线仍为旧编号，待回流对齐——映射：v0.0.2≈旧 v0.1.0、v0.0.3≈旧 v0.1.1+旧 v0.1.3 界面行、v0.0.4≈旧 v0.1.3 内容行、v0.1.0≈旧 v0.1.2、v0.2.0+（主仓）不变；v0.0.1（可玩 Demo）为新增。
>
> **落地主线（2026-10-29 两次修正）**：v0.0.1 可玩 Demo → v0.0.2 引擎收口 → v0.0.3 龙王店可玩竖切 → v0.0.4 完整战役。Demo 建在现状上，零架构改动；引擎让路，先看到能玩。v0.1.0 帝丘店与 v0.0.2 组 5 不在主线，可并行或后置。
>
> **可开工判断**：任务可开工 = 所属任务组组头「前置」声明的组全部完成，且本组内位于它之前的行（含行内「——前置：」注明）已完成；组内除行内注明外无序，可并行。

## v0.0.1 — 可玩 Demo（进行中）

**目标**：把现状变成能玩的一局——帝丘店剧本，微操发令 + 敌军回合 + 胜负结算 + 重开，浏览器可跑。不新增机制、不动架构；决心卡与龙王店归 v0.0.3。

**核实**（2026-10-29 对照代码）：闭环代码已齐——选单位→移动/攻击→结束回合→`_aiStep`→`checkVictory`→结算弹窗（`headquarters_screen.dart` L48 showDialog，L75 重开走 `reset()`）；战报尾 8 条在 `plan_view.dart` L420；回合横幅在顶栏 L232。Demo 缺的是走查与交付，不是功能。

**边界（不做）**：守卫/原语/注入/清专名一律不碰——Demo 建在现状上，清理归 v0.0.2；决心卡不提前塞，它是 v0.0.3 的主角。

- [ ] 一局闭环人工走查：`flutter run -d chrome` 全程——选单位→移动→攻击→结束回合→AI 行动→战报滚动→时限或歼灭→结算→重开；记录卡点
- [ ] 走查卡点修复（按实修，上限 3 处。候选以走查为准：战报仅尾 8 条太挤、AI 500ms 无进度反馈、结算弹窗体验）
- [ ] Demo 交付物：web release 可访问 + `demo.md` 十句操作说明——验收：不看代码的人按说明能打完一局

## v0.0.2 — 通用引擎核心（未开始）

**目标**：战场模型 + CommandExecutor + 可注入的战斗/胜负/地形，不绑任何剧本。

**验收**：核心代码检索不到剧本专名（含 JSON schema）；一个虚构最小剧本可驱动核心跑通一回合。核心 / 剧本边界清单见档案仓 `qtgame-war/constraints.md`。

### 已交付

- [x] Task 七档命令（`lib/models/task.dart` + 测试 + `doc/models/task.md`）
- [x] Command + 翻译层（`lib/models/command.dart` + `lib/controllers/command_translator.dart` + 测试 + `doc/models/command.md`）
- [x] Unit task/fat（`lib/models/unit.dart` + 测试 + `doc/models/unit.md`）
- [x] CommandExecutor（`lib/controllers/command_executor.dart` + 测试 + `doc/models/command.md` 执行规则节）：守卫集中一处，批量汇总战报
- [x] 帝丘店数据剥离（`battlefield.dart`/`combat.dart`/`game.dart` 重写 + `map.json` catalog 段 + `test/fixtures.dart`）：字符串地形 id + 剧本注入 `TerrainBook`；尺寸/地名/胜负文案归剧本；龙王店可纯 JSON 注入

### 1. 可注入战斗结算 + 随机源注入

- [x] `resolveCombat` 收注入命中修正标量 `hitMod`（调用方从剧本状态取出传入），不收剧本状态对象
- [x] 结算随机源由调用方注入：`rng` 改 required，`GameController` 持有可注入 `Random`（默认非种子化）——确定性从第一天进门，不等 v0.2.0 重审结算路径
- [x] 测试：同种子双跑结算序列逐项一致；不同种子允许偏离；随机源不被结算层重置

### 2. 可注入胜负策略

**前置**：无——可开工（已完成）

- [x] 胜负判断抽为注入策略（`lib/models/victory_policy.dart` 只定形状；`Game.checkVictory` 降为调用+落盘+返回战报，`gameOver` 已置位不再评估）
- [x] 帝丘店现有「占领核心」降为注入实现（`lib/campaigns/diqiudian_victory.dart` 四条件 + 文案 + 超时战报；`_aiStep` 两处手写失败块删除，胜负出口收敛到 `checkVictory`）

### 3. 原语拆分 + 状态所有权收口

**前置**：无——组内除行内注明外无序，可并行开工

**主题**：本组两线——守卫归 CommandExecutor 一处、状态事实（评估时机 / 结束标志）归单源。第二线是任务 2 复盘的根因修复，随守卫唯一化同批做。

- [ ] 原语去守卫，降为「假定输入合法」的纯原语
- [ ] 守卫唯一化：全部由 CommandExecutor 承担（消除执行器与原语的双份守卫）——前置：原语去守卫，与之同批做
- [ ] 点击路径改为构造 Command 走执行器——点击只是发令的一种渠道——前置：守卫唯一化
- [ ] 胜负评估收敛 +「战役结束」单源：`checkVictory` 从三处调用点收敛为状态变更后统一评估。现为推模式，靠调用点时序契约维持，重复评估不报错只静默丢战报（任务 2 实现中当场踩中）。`campaign.gameOver`（策略守卫读）与 `phase == gameOver`（交互闸门读）双标志归一为单源，另一处改派生。——前置：守卫唯一化（同为状态所有权收敛）——验收：`checkVictory` 调用点唯一；只写一个标志时测试变红
- [ ] 消除 `_aiStep` 内联射程/掩体规则：`game_controller.dart` 目标筛选改复用 `Game.getAttackTargets`（side 过滤参数化，现手抄 `d > attackRange` / `fullCover && d > 1`）——验收：射程/fullCover 规则只在 `game.dart` 一处；补敌军目标筛选与引擎查询一致的测试
- [x] 敌军攻击走结算应用原语：`game_controller.dart` `_aiStep` 攻击结算后落 `takeDamage`/`markActed`/战报（原只写战报文本，现玩家/敌军两路共用 `combat.dart` 的 `applyCombatOutcome`）——验收：敌军攻击命中后玩家单位 hp 下降；补敌军攻击落伤害的测试

（原「部署表 / 兵力表文案 / 伏击部署」三行已于 2026-10-29 删除：`_recomputeExhaustion`/`initialPlanViewData`/`updateUnitIntent` 经全仓检索与 `git log -S` 全历史核对从未存在于代码，系幽灵任务；对应文案硬编码归 v0.1.0「清文案层剧本专名」条。）

### 4. 剧本资产收尾

**前置**：无——宜先于组 3 的收口大改与 v0.0.3「战力换算规则降为注入」开工，减小返工

- [ ] `CampaignConfig.load` 拆纯函数 `fromJson(campaignJson, mapJson, unitsJson)` + 薄 IO 壳
- [ ] 新增测试解析真实帝丘店 JSON 资产——目前真实资产零测试，map.json 写错只能启动 App 时发现；v0.0.3 龙王店走纯 JSON 剧本，schema 无测试等于注入机制裸奔；顺手抽 `CampaignConfig` 测试构造 builder，消掉七个测试文件手抄 40 行配置
- [ ] JSON key `initial_huaye_power` 含「华野」专名 → 改通用名并同步 campaign.json
- [ ] `hexSize` 双源归一（已决：删 config 字段与 JSON key）：`Battlefield.hexSize`（static 27）被几何与视图读取，`config.hexSize` 解析后无几何读点——假注入。像素尺寸是 UI 渲染参数，非剧本事实，删字段后 `Battlefield.hexSize` 明记为跨剧本表现常量
- [ ] `maxTurns` 双源归一：`diqiudian_victory.dart` 超时判断写死 `turn > 12`（魔数随任务 2 自 `_aiStep` 迁入此处），UI 读 `config.maxTurns`——验收：campaign.json 设 `max_turns: N` 时第 N+1 回合触发时间耗尽；补配置驱动回合上限的测试，与 `hexSize` 同批处理

### 5. 控制器层确定性验证

**前置**：无——可开工；宜在 v0.0.3「endTurn 改可等待」落地后做，否则双跑测试须沿用让拍 hack 并返工一次。**非落地主线**——v0.2.0 确定性常青前补齐即可

- [ ] 补 `GameController` 层同种子双跑测试：新增 `test/controllers/game_controller_test.dart`，固定种子构造 `GameController`，执行同一命令序列两次（覆盖点击路径与 `_aiStep` 异步路径），断言战报序列与单位终态逐项一致——验收：同种子双跑零偏离、不同种子允许偏离；这是 v0.2.0「确定性常青」在控制器层的基线首测

### 已知缺陷索引（2026-10-29 两轮复盘：0df653e 触碰面 + 任务 2 落地复盘；本节只留索引，修复行在任务组，按修复归处排列）

- `_aiStep` 目标筛选手抄射程/掩体规则，不走引擎查询（修复见本版组 3「消除 `_aiStep` 内联射程/掩体规则」条）
- 胜负评估是推模式：`checkVictory` 三处调用点靠时序契约维持，重复评估不报错只静默丢战报；「战役结束」双标志：`campaign.gameOver`（策略守卫读）与 `phase == gameOver`（交互闸门读）成对分离赋值（修复见本版组 3「胜负评估收敛 +『战役结束』单源」条）
- `maxTurns` 双源：`diqiudian_victory.dart` 写死 `12`，UI 读 `config.maxTurns`（修复见本版组 4「maxTurns 双源归一」条）
- `Campaign.hitMod/moveMod` 的 70/45/25 阈值表与战力消耗写死在核心，「收注入修正标量」只做到标量层（修复见 v0.0.3「战力换算规则降为注入」条）
- `Campaign.powerDesc` 把显示文案（充沛/尚可/吃紧/濒临极限）放模型 getter，`plan_view.dart` 直接消费——与 hitMod 阈值表同文件同病（修复见 v0.0.3「战力换算规则降为注入」条）
- 确定性契约仅覆盖 `resolveCombat` 叶子函数，`GameController` 单 `Random` 消耗顺序无双跑测试（修复见本版组 5）
- 「核心检索不到剧本专名」验收在文案层失真：`game_controller.dart` 余 3 处（野司×2/华野回合结束）+ `plan_view.dart`/`main.dart` 写死；胜负详情 2 处与超时战报 1 处已迁 `lib/campaigns/diqiudian_victory.dart`（修复见 v0.1.0「清文案层剧本专名」条）
- 战报无结构：`Dispatch.type` 为裸字符串，`plan_view.dart` 靠 case 字符串匹配分流；剧本文案没有可指认的归属，清专名只能人肉逐条判断（修复见 v0.1.0「战报结构化」条）
- 注入双通道：胜负策略走构造参数，`engine.config` 被控制器自由读取拼战报 9 处（修复见 v0.1.0「注入通道约定」条）

## v0.0.3 — 龙王店可玩竖切（未开始）

**前置**：v0.0.2 组 3、组 4 完成（组 5 非主线，可后置）——落地主线：第二个剧本 + 决心卡玩法

**目标**：龙王店作为第一个剧本注入核心，跑通「矛盾 → 决心卡 → 翻译 → 执行 → 战报 → 新态势」闭环，并以指挥官界面呈现。

**验收**：玩家不逐子微操；位置/地形真实影响后果；多回合闭环可推进至胜负结算与重开；核心仍检索不到龙王店专名。原型的决策冲突（卡互斥、攻城/阻援两难、疲劳代价）在此成立。

- [ ] 地图注入：8×7 + 地名（龙王店[要塞]、铁佛寺、帝丘店、田花园、杨拐）+ 地形 props
- [ ] 单位注入：4 纵队（1/4/6纵[assault]、11纵[reserve]）+ 守军 + 整25师
- [ ] 战斗修正：疲劳（`fat`≥4 惩罚、standby 恢复）经注入接入 `resolveCombat`，取代战力标量
- [ ] 战力换算规则降为注入：`campaign.dart` 的 `hitMod`/`moveMod` 70/45/25 阈值表与 `game_controller.dart` 的战力消耗（移动 −1 / 攻击 −3 / 每回合 −1，clamp 5..100）改为剧本注入的换算——验收：核心检索不到 70/45/25 阈值常数；`powerDesc` 显示文案（充沛/尚可/吃紧/濒临极限，现为 `Campaign` getter，`plan_view.dart` 直接消费）同批归剧本；补换算由剧本提供的测试
- [ ] 胜负策略：克据点 / 两部失去战斗力 / 时限未决——前置：v0.0.2 组 2「可注入胜负策略」（已完成）
- [ ] 显形死行与幻影单位收口：`game_controller.dart` `applyAttack` 删 `defender.reveal()`（入守卫已要求 `revealed`，死代码），`doc/models/combat.md` 边界写明「目标必须已显形，攻击不负责显形」，`game_controller_test.dart` 补测试钉住现状「units.json 缺省 `revealed: false` 的初始单位不可被攻击」——验收：删后全量测试绿；将来做真雾隐须成对改守卫与显形，此测试变红即提醒
- [ ] 定突击×工事契约：`doc/models/combat.md` 称「突击对 fullCover 必中且伤害 2」，`combat.dart` 分支实际要求先掷命中——二改一（代码实现必中并补必中测试，或 doc 改「命中后必重创」并补该分支测试）——验收：doc 与代码一致，`combat_test.dart` 有该分支锁定测试
- [ ] 战斗测试桩契约化（前置：「定突击×工事契约」先落——若裁定必中免掷骰，「恰掷 1 次」改按分支限定）：`combat_test.dart` 的 `_ScriptedRandom.nextInt` 校验 `0 ≤ v < max`（违约报错指明桩违规）、记录掷骰次数并断言「每次结算恰掷 1 次」，三档 roll 魔数 99/39/9 注明命中率公式来源（55+baseAttack×6+hitMod−def×8）——验收：故意给 `resolveCombat` 加第二次掷骰时，红在「掷骰次数」断言而非 RangeError
- [ ] 补红方 hasActed 回合末重置：`game_controller.dart` `_aiStep` 新回合重置循环现只清蓝方，与 `applyCombatOutcome` 对两侧行动对称置位脱节（现靠无人读红方 hasActed 维持）——验收：连跑两个 AI 回合后红方 `hasActed` 为 false 有测试；敌军行动闸门（按 hasActed 限动）落地前必须先有此重置
- [ ] endTurn 改可等待：`game_controller.dart` `endTurn` 返回 `Future<void>`（视图调用方 fire-and-forget 不改），`game_controller_test.dart` 种子冒烟改 `await c.endTurn()`，删「两个 Duration.zero 让拍」的注册顺序 hack——验收：冒烟测试无任何 `Future.delayed` 让拍，`await endTurn()` 返回后 `_aiStep` 已完成的状态断言成立
- [ ] 指挥官决策：矛盾从战局派生（援军距离/疲劳/工事），决心卡 = 给一组纵队各指派 Task
- [ ] 决心卡面板 + 算子点击换档（战报渐进、回合横幅、胜负结算与重开已随 v0.0.1 Demo 交付，不重建）
- [ ] 闭环集成验证：连续多回合推进至胜负结算——前置：本组其余各行全部完成

**玩法事实源**：`examples/prototype/龙王店战斗.html`——决策层照此，静态地图与写死卡脚本按「明确淘汰」处理。

### 明确淘汰（避免回到旧范式）

- 原型的静态地图与不动单位；原型的批量抽象 d6 结算（无视位置，被位置结算取代）
- 原型写死的逐回合卡脚本（`cardFor()` 按 turn 分支）——卡从状态派生，这是机制不是剧本
- 逐子微操交互降级为「发令的一种方式」，不再是引擎唯一入口
- 死情报/计划装饰面板——不在此版重建

## v0.0.4 — 龙王店完整战役（未开始）

**前置**：v0.0.3 完成

**目标**：落地后的第一个内容版本——完整史实战役，验证内容可以按剧本资产的方式生长。

- [ ] 完整 5 回合史实时间轴 + 逐回合事件文案（20:00→03:00）
- [ ] 全套决心卡（从战局状态派生，非 turn 脚本）
- [ ] 整25师推进链（阻击/包抄/诱敌/佯攻修正、冒进遭伏、抵近冲阵）——**过渡物**：v0.2.2 信念驱动敌军指挥官落地时替换，不扩建

## v0.1.0 — 帝丘店第二剧本（通用性证明）（未开始）

**前置**：v0.0.2 组 3 完成（守卫/单源是注入地基）；可与 v0.0.3/v0.0.4 并行——**非落地主线**：证明两场景共用核心

**目标**：现有帝丘店搬到核心上作第二个剧本——两场景共用一个核心，才真正证明核心通用。

- [ ] 帝丘店作为剧本注入：`playerPower` 运行时换算、`fortStrength`、地形数据全归剧本（核心占领胜负已在 v0.0.2 组 2 归策略）
- [ ] 战报结构化：`Dispatch.type` 裸字符串收枚举（`plan_view.dart` 现靠 case 字符串匹配分流，拼错静默走 default）+ 剧本文案字段改由剧本/策略产出，让「哪些字符串算剧本资产」有可指认的家——验收：type 漏处理显式报错而非静默；清专名不靠人肉逐条判断
- [ ] 注入通道约定：剧本数据只经注入参数/策略流入控制器，不再经引擎转发（现 `engine.config` 被控制器自由读取拼战报 9 处，如 `野司：包围${config.name}`）——验收：`grep "engine.config" lib/controllers/` 零命中
- [ ] 清文案层剧本专名：`game_controller.dart` 余 3 处战报（野司×2/华野回合结束）与 `plan_view.dart`、`main.dart` 写死文案改剧本注入——前置：战报结构化、注入通道约定（先有家，再搬家）——验收：`grep -rn "华野\|帝丘店" lib/` 零命中
- [ ] `headquarters_screen` 点击路径改在核心 + 帝丘店注入之上
- [ ] 现有全量测试（93，随任务增长）回归不砸

## v0.1.x — 收口（未排定）

**前置**：v0.0.4 与 v0.1.0 完成后排定

落地与通用性证明之后的收口版本，任务待排。已知候选：`GameController` 确定性双跑基线（若组 5 未随 v0.0.2 做完）、主仓 v0.2.x 基线回流后的对应任务。

## 跨版本纪律

- 核心检索不到剧本专名（含 JSON schema），每版验收都查
- 状态事实单一属主：新增全局状态（标志、评估时机、文案）先定归属再落字段；要写第二处时改派生，不改复制（任务 2 复盘根因）
- v0.2.0 起确定性常青：同种子双跑零偏离，不过即回滚（基线见主仓 `v0.2.0.md`）——比对范围须含 `GameController` 层 rng 消耗顺序，不只 `resolveCombat` 叶子函数
- 大模型不进结算，只碰文本层
- 红方 `hasActed` 现无代码读取；将来 AI 按 `hasActed` 做闸门须在回合末重置红方
