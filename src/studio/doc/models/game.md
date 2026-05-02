# Game 模块现状

## 当前状态

规则工具箱：BFS 移动计算、战斗结算、援军生成、胜利判定。算法清晰，但职责过重，无回合管理。

## 核心问题

1. **违反单一职责** — 地形、移动、战斗、援军、胜负全在一个类
2. **可测试性差** — Random().nextInt(100) 硬编码，副作用直接改对象
3. **无回合管理** — 没有回合状态机，谁行动、何时结束回合全无定义
4. **AI 完全空白** — 敌方只能被动挨打
5. **硬编码严重** — 命中率、系数等魔法数字，单位 ID 写死
6. **地图数据耦合** — createInitialUnits()、spawnReinforcements() 绑定特定剧本

## 改进方向

拆分为纯服务：
- **MovementService** — 计算移动范围
- **CombatService** — 战斗结算（返回 CombatResult，不改对象）
- **ReinforcementService** — 生成援军数据
- **VictoryService** — 检查胜负
- **Battlefield** — 吸纳地形静态方法

完成后可删除 Game 类。
