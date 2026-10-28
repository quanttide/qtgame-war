# studio ROADMAP

> 核心机制、架构约束与分层结构见 [docs/dev-guide/](../../docs/dev-guide/index.md)。

## v0.1.0 — 通用引擎核心

**目标**：建立跨剧本的核心——战场模型 + CommandExecutor + 可注入的战斗/胜负/地形，不绑任何剧本。

**验收**：核心代码检索不到剧本专名；Task/Command/translator/执行原语全部落在核心层；一个虚构最小剧本可驱动核心跑通一回合。

### 0. 核心 / 剧本边界清单（后续剥离以此为准）

不再逐项现场判断「这个算核心还是算帝丘店」，以此表为准：

| 归核心 | 归剧本 |
|--------|--------|
| 战场状态、移动/攻击原语、战斗结算框架、胜负判断框架 | 具体地图尺寸与坐标、地形 catalog、地名文案 |
| 命令执行与守卫（已亡/不归我方/不在场/空令） | 决心卡内容与触发时机 |
| AI 重部署的机制（轮换、找掩体、占领） | 哪个单位蹲教堂、哪个守桥头（帝丘店坐标） |
| 疲劳/混乱/伏击/意图等状态转移 | 兵力表文案（"4纵 11旅"） |
| 战报事件类型 | 剧本注入的特殊规则（爆破、炮兵、纵火） |

### 待做（顺序即依赖）

- [x] 1. **模型签名去 Campaign 化**：`Unit.effectiveMoveRange` / `resolveCombat` 收注入修正标量，解绑 `Campaign`
- [x] 2. **CommandExecutor** — 命令序列 → 通用原语 → 战报。守卫逻辑（已亡/不归我方/不在场/空令）收进执行器，**停止在每个新入口内联复制**。建在已去 Campaign 化的签名上，立即可做
- [x] 3. **帝丘店数据剥离**（一并处理，不再拆项）：
  - 地形数据化：`TerrainType` enum + 全局 `terrainProps` → 剧本注入的 terrain catalog（props per id）
  - `Battlefield` 静态 10×7 尺寸 → 剧本提供
  - `createMapTerrain()` 硬编码帝丘店坐标 → 剧本地图数据
  - `checkVictory` 硬编码「帝丘店核心」文案 → 剧本注入
  - terrain id 的 `name` 字段（`帝丘店核心` / `惠济河`）→ 剧本地名
  - 测试数据跟随：直接用 `createMapTerrain()` 的测试同步改造
- [ ] 4. 可注入战斗结算（依赖 3）：纯函数 + 可注入修正，核心只调用
- [ ] 5. 可注入胜负策略（依赖 3）：核心只调用，不预设规则
- [ ] 6. `applyMove` / `applyAttack` 拆为「通用原语（进核心）」+「帝丘店修正（降为注入）」（依赖 2 的原语）；同批把 `GameController` 中剩余帝丘店专属逻辑注入化：
  - **守卫唯一化**：`applyMove`/`applyAttack` 去守卫，降为「假定输入合法」的纯原语；守卫全部由 CommandExecutor 承担。点击路径改为构造 Command 走执行器——与「明确淘汰」里「逐子微操降级为发令的一种方式」对齐，点击只是发令的一种渠道。守卫现状是双份（执行器 + 原语各一份 `!alive`/`side != blue`/`hasActed`），根因是原语建于点击路径时代自带守卫，本项一并纠正
  - `_recomputeExhaustion` 敌军自动重部署的帝丘店坐标 → 剧本注入部署表
  - `initialPlanViewData` 兵力表文案 → 剧本数据
  - `updateUnitIntent` 伏击部署的场景绑定 → 剧本数据
- [ ] 7. **剧本资产收尾**（做完 3 才暴露的问题；在 4–6 大改 config 之前做，减小返工）：
  - `CampaignConfig.load` 拆为纯函数 `fromJson(campaignJson, mapJson, unitsJson)` + 薄 IO 壳；新增测试解析**真实帝丘店 JSON 资产**——目前真实资产零测试，map.json 写错（非法转义/字段缺失/键不匹配）只能在启动 App 时发现；item 5 龙王店走纯 JSON 剧本，schema 无测试等于注入机制裸奔
  - JSON key `initial_huaye_power` 含「华野」专名 → 改通用名并同步 campaign.json——「核心检索不到剧本专名」的验收要覆盖 JSON schema，不只 Dart 代码
  - `hexSize` 双源归一：`config.hexSize` 与 `Battlefield.hexSize`（static 27）并存但几何只读后者，config 那份是死的——item 3 的「尺寸归剧本」只走了 cols/rows，此项补完：几何改收注入值，或删 config 字段并明记为跨剧本常量

### 已交付（本就通用，归位核心层）

- **Task**（`lib/models/task.dart` + 测试 + `doc/models/task.md`）：指挥官层姿态词汇，七档命令 + 角色档位 + 疲劳规则。
- **Command + 翻译层**（`lib/models/command.dart` + `lib/controllers/command_translator.dart` + 测试 + `doc/models/command.md`）：Task + 战场态势 → 带坐标指令。纯函数，不掷骰不改状态。
- **Unit task/fat**（`lib/models/unit.dart` + 测试 + `doc/models/unit.md`）：指挥官层姿态与疲劳已归到 Unit，只持有状态，消费留给可注入结算层。
- **CommandExecutor**（`lib/controllers/command_executor.dart` + 测试 + `doc/models/command.md` 执行规则节）：命令序列 → 引擎原语（applyMove/applyAttack）→ 战报。守卫（过期/不在场/已亡/不归我方/已行动/空令）集中一处，逐条独立，批量汇总战报。
- **帝丘店数据剥离**（`battlefield.dart`/`combat.dart`/`game.dart` 重写 + `map.json` catalog 段 + `test/fixtures.dart`，见 `doc/models/battlefield.md`）：`TerrainType` 枚举 + 全局 `terrainProps` → 字符串 id + 剧本注入 `TerrainBook`；网格尺寸/画布随 config 自适应；地名（惠济河/帝丘店核心）、胜负文案归剧本；图例由 catalog 生成；`TerrainProps.assaultOnly` 取代 coreFort 硬编码分支。龙王店剧本自此可纯 JSON 注入。

## v0.1.1 — 龙王店剧本（第一个场景，竖切）

**目标**：龙王店作为**第一个剧本**注入核心，跑通完整矛盾闭环——同时证明核心可被剧本驱动。

**验收**：玩家不逐子微操；位置/地形真实影响后果；一回合闭环可推进；核心仍检索不到龙王店专名。原型的决策冲突（卡互斥、攻城/阻援两难、疲劳代价）在此成立。

- [ ] 龙王店注入：8×7 地图 + 地名（龙王店[要塞]、铁佛寺、帝丘店、田花园、杨拐）、4 纵队（1/4/6纵[assault]、11纵[reserve]）+ 守军 + 整25师、地形 props
- [ ] 龙王店战斗修正：疲劳（`fat`≥4 惩罚、standby 恢复），取代战力标量
- [ ] 龙王店胜负策略：克据点 / 两部失去战斗力 / 时限未决
- [ ] 指挥官决策：矛盾从战局派生（援军距离/疲劳/工事），决心卡 = 给一组纵队各指派 Task
- [ ] 一个矛盾闭环：矛盾 → 决心卡 → 翻译 → 核心执行 → 战报 → 新态势

## v0.1.2 — 帝丘店剧本（第二个场景，证明核心通用）

**目标**：把现有帝丘店搬到核心上作为**第二个剧本**——两个场景共用一个核心，才真正证明核心通用。

- [ ] 帝丘店作为剧本注入：`playerPower` 标量、`fortStrength`、核心占领胜负、`TerrainType` → 剧本地形数据
- [ ] `headquarters_screen` 点击路径改在核心 + 帝丘店注入之上（点击成为发令的一种方式）
- [ ] 现有 62 测试回归，不砸

## v0.1.3 — 完整龙王店 + 指挥官界面

- [ ] 完整 5 回合史实时间轴 + 逐回合事件文案（20:00→03:00）
- [ ] 全套决心卡（从**战局状态**派生，非 turn 脚本）、整25师推进链（阻击/包抄/诱敌/佯攻修正、冒进遭伏、抵近冲阵）
- [ ] 决心卡面板 + 算子点击换档、战报渐进披露、回合横幅、胜负结算与重开

### 明确淘汰（避免回到旧范式）

- 原型的静态地图与不动单位；原型的批量抽象 d6 结算（无视位置，被位置结算取代）
- 原型写死的逐回合卡脚本（`cardFor()` 按 turn 分支）——卡从状态派生，这是机制不是剧本
- 逐子微操交互降级为「发令的一种方式」，不再是引擎唯一入口
- 死情报/计划装饰面板——不在此版重建

## v0.2.0+ — 合流与上层

- [ ] 合流三栏指挥部界面（`headquarters_screen.dart`）为决策入口，把指挥官循环接进去
- [ ] 情报系统 / LLM 参谋长层（原 Phase C 方向，详见 Git 历史中 `docs/dev-guide/roadmap.md`）
