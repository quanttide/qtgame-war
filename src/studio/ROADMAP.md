# studio ROADMAP

> **当前版本：v0.1**（玩法竖切线），进行中：**v0.1.0 通用引擎核心**。
>
> 本文件是 qtgame-war 的**工作记忆**：任务随工作动态调整，开工前读、变化即改。版本基线在主仓 `data/roadmap/qtgame-war/`（v0.2.0+ 亦见彼处），设计共识在创始人档案仓 `qtgame-war/` 分区；三层互动规则见 [CONTRIBUTING.md](CONTRIBUTING.md)。模块规格在本目录 `doc/models/`。

## v0.1.0 — 通用引擎核心（进行中）

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

- [ ] 胜负判断抽为注入策略（核心只调用，不预设规则）
- [ ] 帝丘店现有「占领核心」降为注入实现

### 3. `applyMove`/`applyAttack` 拆分 + `GameController` 注入化

- [ ] 原语去守卫，降为「假定输入合法」的纯原语
- [ ] 守卫唯一化：全部由 CommandExecutor 承担（消除执行器与原语的双份守卫）
- [ ] 点击路径改为构造 Command 走执行器——点击只是发令的一种渠道
- [ ] `_recomputeExhaustion` 敌军重部署的帝丘店坐标 → 剧本注入部署表
- [ ] `initialPlanViewData` 兵力表文案 → 剧本数据
- [ ] `updateUnitIntent` 伏击部署的场景绑定 → 剧本数据

### 4. 剧本资产收尾（宜在大改 config 前做，减小返工）

- [ ] `CampaignConfig.load` 拆纯函数 `fromJson(campaignJson, mapJson, unitsJson)` + 薄 IO 壳
- [ ] 新增测试解析真实帝丘店 JSON 资产——目前真实资产零测试，map.json 写错只能启动 App 时发现；v0.1.1 龙王店走纯 JSON 剧本，schema 无测试等于注入机制裸奔
- [ ] JSON key `initial_huaye_power` 含「华野」专名 → 改通用名并同步 campaign.json
- [ ] `hexSize` 双源归一：`config.hexSize` 与 `Battlefield.hexSize`（static 27）并存但几何只读后者——几何改收注入值，或删 config 字段并明记为跨剧本常量

## v0.1.1 — 龙王店剧本（未开始）

**目标**：龙王店作为第一个剧本注入核心，跑通「矛盾 → 决心卡 → 翻译 → 执行 → 战报 → 新态势」闭环，同时证明核心可被剧本驱动。

**验收**：玩家不逐子微操；位置/地形真实影响后果；一回合闭环可推进；核心仍检索不到龙王店专名。原型的决策冲突（卡互斥、攻城/阻援两难、疲劳代价）在此成立。

- [ ] 地图注入：8×7 + 地名（龙王店[要塞]、铁佛寺、帝丘店、田花园、杨拐）+ 地形 props
- [ ] 单位注入：4 纵队（1/4/6纵[assault]、11纵[reserve]）+ 守军 + 整25师
- [ ] 战斗修正：疲劳（`fat`≥4 惩罚、standby 恢复），取代战力标量
- [ ] 胜负策略：克据点 / 两部失去战斗力 / 时限未决
- [ ] 指挥官决策：矛盾从战局派生（援军距离/疲劳/工事），决心卡 = 给一组纵队各指派 Task
- [ ] 一回合闭环集成验证

**玩法事实源**：`examples/prototype/龙王店战斗.html`——决策层照此，静态地图与写死卡脚本按 v0.1.3「明确淘汰」处理。

## v0.1.2 — 帝丘店剧本（未开始）

**目标**：现有帝丘店搬到核心上作第二个剧本——两场景共用一个核心，才真正证明核心通用。

- [ ] 帝丘店作为剧本注入：`playerPower` 标量、`fortStrength`、核心占领胜负、地形数据全归剧本
- [ ] `headquarters_screen` 点击路径改在核心 + 帝丘店注入之上
- [ ] 现有 74 测试回归不砸

## v0.1.3 — 完整龙王店 + 指挥官界面（未开始）

**目标**：v0.1.x 收口——完整剧本内容 + 玩家可玩的指挥官界面。

- [ ] 完整 5 回合史实时间轴 + 逐回合事件文案（20:00→03:00）
- [ ] 全套决心卡（从战局状态派生，非 turn 脚本）
- [ ] 整25师推进链（阻击/包抄/诱敌/佯攻修正、冒进遭伏、抵近冲阵）——**过渡物**：v0.2.2 信念驱动敌军指挥官落地时替换，不扩建
- [ ] 决心卡面板 + 算子点击换档、战报渐进披露、回合横幅、胜负结算与重开

### 明确淘汰（避免回到旧范式）

- 原型的静态地图与不动单位；原型的批量抽象 d6 结算（无视位置，被位置结算取代）
- 原型写死的逐回合卡脚本（`cardFor()` 按 turn 分支）——卡从状态派生，这是机制不是剧本
- 逐子微操交互降级为「发令的一种方式」，不再是引擎唯一入口
- 死情报/计划装饰面板——不在此版重建

## 跨版本纪律

- 核心检索不到剧本专名（含 JSON schema），每版验收都查
- v0.2.0 起确定性常青：同种子双跑零偏离，不过即回滚（基线见主仓 `v0.2.0.md`）
- 大模型不进结算，只碰文本层
