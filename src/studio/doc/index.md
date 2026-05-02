# 重构路线

## 当前状态

主线已就位（GameBloc + 事件驱动），但底层仍是原型泥潭：
- Unit/Campaign 可变 → 状态不可变无法成立
- Game 类大杂烩（规则+副作用+工厂）
- Bloc 内混杂时序、AI、直接状态修改

## 核心问题

| # | 问题 | 影响 |
|---|------|------|
| 1 | Unit/Campaign 可变 | 回放/测试/撤销受阻 |
| 2 | Game 类职责过重 | 不可控修改 + 硬编码 |
| 3 | Bloc 直接修改状态 | 历史状态污染 |

## 重构步骤

**第1步：Unit/Campaign 不可变**
- Unit 所有字段 final，提供 `moveTo()`、`takeDamage()` 等方法返回新实例
- Campaign 拆分为 Config（不可变配置）+ State（不可变状态）

**第2步：拆解出纯服务，删除 Game 类**
- MovementService、CombatService、VisibilityService
- ReinforcementService、VictoryService
- 地形方法移到 Battlefield 或 TerrainHelper

**第3步：重构 GameBloc**
- 注入服务，消除直接状态修改
- AI 逻辑抽到 AiService
- 移除 Future.delayed（移到 UI 层）

**第4步：优化 GameState/GameEvent**
- 移除 clearSelection 标志，改用显式字段
- props 改用基于不可变对象的比较

**第5步：命名清理**
- `side` → `enum Side { pla, nationalist }`
- `special` → `enum UnitAbility { assault }`
- `huayePower` → `offensivePower`
- 地图/单位数据迁到独立配置

## 目标架构

```
UI → GameBloc (事件→状态)
       ↓ 调用
    MovementService / CombatService / AiService
    ReinforcementService / VictoryService
       ↓ 返回
    新 GameState (不可变)
```

特征：任何 emit 的状态都是独立快照，可序列化、可回放。
