# 领域层设计

领域层是整个引擎的心脏，所有规则封装在此。它是纯逻辑，不依赖任何 UI 框架，是无状态的规则执行器——每次调用输入当前状态和待执行的动作，输出新的状态和结果。

---

## 核心数据模型

所有模型为不可变数据结构，状态更新时生成新对象。

- **Unit**：单位实体，包含 ID、阵营、坐标、基础属性（攻击/防御/移动/射程）、当前血量、体力/士气/编制完整度/组织韧性、特殊标签、是否已行动。
- **Map**：地形网格（二维数组），每个格子存储地形类型和地形效果（移动消耗、防御加成、视野遮盖）。
- **CampaignState**：全局战役变量——部队体力、弹药储备、工事强度、增援倒计时、崩溃风险等。影响所有单位的攻防属性。
- **GameState**：聚合 Unit 列表、Map、CampaignState、当前回合、阶段、选中状态、高亮范围。
- **IntelligenceReport**：战场情报，包含 observedAt（时间点）、confidence（可信度 0~1）、source（来源：侦察/通报/截获）。
- **CommandIntent**：指挥官当前锁定的指挥意图（如保护平民、积极防御、收集情报），决定哪些决策选项可用。
- **CommandOrder**：命令（目标、时限、方式），由意图生成，经部队红线校验后执行。
- **Consequence**：决策后果——战果、损耗、态势变化、叙事事件。

---

## 六角格坐标系统

采用 Odd-r 偏移坐标系或立方坐标，提供纯函数接口：

- `pixel_to_hex(x, y) -> Hex`
- `hex_to_center(Hex) -> Point`
- `hex_distance(a, b) -> int`
- `neighbors(Hex) -> List<Hex>`
- `calculate_move_range(unit, map, all_units) -> Set<Hex>`：基于移动力、地形消耗和单位阻挡的 BFS 搜索。
- `calculate_attack_targets(unit, map, all_units) -> Set<Hex>`：基于攻击距离和战争迷雾的合法目标筛选。

---

## 战斗结算器

纯函数：`resolve_combat(attacker, defender, terrain, campaign_state) -> CombatResult`

- 命中概率 = 基础命中 + 攻击方修正（含全局体力/编制惩罚） - 地形防御修正 - 距离衰减
- 返回：是否命中、伤害值、消灭信息、可能触发的战役效果（如工事强度下降）
- 结算后不直接修改状态，返回描述变化的数据结构，由调度层应用

---

## 指挥官意图系统

战役模式的核心领域逻辑，三个纯函数：

1. **`filter_options(intent, all_options) -> List<Option>`**：根据意图过滤选项。玩家的立场重塑他能看见的世界——决心保护平民的指挥官看不到"无差别火力覆盖"。
2. **`validate_orders(command, force_state) -> ValidationResult`**：校验命令是否违反部队红线（体力不足时无法进攻、编制过低时强行行军可能溃散）。
3. **`calculate_consequences(command, battlefield_state, intel) -> List<Consequence>`**：计算决策后果，结合已知情报的不确定性产生概率性结果。

---

## 情报不对称模型

战场真实状态由系统推演，玩家消费的是经过处理的情报报告：

- 情报携带时间戳（observedAt）和可信度（confidence 0~1）
- 不同来源（侦察、通报、截获）具有不同的基准可信度
- 过期情报在 UI 上以褪色、闪烁、问号标记提示
- 指挥官永远在"据报"的基础上决策

---

## AI 行为策略

纯函数：`ai_act(state) -> List<Action>`

支持可替换策略（通过 ICommander 接口）：
- **防御性 AI**：固守核心，被动反击
- **进攻性 AI**：主动向薄弱点推进并攻击
- **事件驱动 AI**：检测到援军到达后切换策略

AI 输出动作列表，由调度层逐个应用到状态。
