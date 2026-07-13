# Unit 模块

## 架构：本体-实例分离

兵种静态属性收敛到 `UnitType`（本体），战场状态保留在 `Unit`（实例）。

### UnitType（本体）

| 字段 | 类型 | 说明 |
|------|------|------|
| name | String | 兵种名称 |
| maxHp | int | 最大生命值 |
| baseAttack | int | 基础攻击力 |
| baseDefense | int | 基础防御力 |
| baseMoveRange | int | 基础移动范围（格数） |
| attackRange | int | 攻击范围，1 近战 ≥2 远程 |
| isAssault | bool | 是否具备突击能力，默认 false |

### Unit（实例）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 单位唯一标识 |
| side | Side | 阵营：blue / red |
| type | UnitType | 兵种本体引用 |
| col / row | int | 战场坐标 |
| hp | int | 当前生命值，默认 type.maxHp |
| hasActed | bool | 本回合是否已行动 |
| revealed | bool | 是否已被发现 |
| alive | bool | hp≤0 时自动 false |
| isReinforcement | bool | 是否为增援单位 |

### UnitLibrary（框架通用兵种）

```dart
class UnitLibrary {
  static const lightInfantry = UnitType(name: '轻步兵', maxHp: 3, ...);
  static const heavyInfantry = UnitType(name: '重步兵', maxHp: 4, ...);
  static const artillery     = UnitType(name: '炮兵',   maxHp: 2, ...);
  static const cavalry       = UnitType(name: '骑兵',   maxHp: 3, ...);
  static const assaultInfantry = UnitType(name: '突击步兵', maxHp: 3, isAssault: true, ...);
  static final all = [lightInfantry, heavyInfantry, artillery, cavalry, assaultInfantry];
}
```

### 枚举

```dart
enum Side { blue, red }
```

## 实例操作

- `effectiveMoveRange(Campaign)` — 计算有效移动范围（baseMoveRange - moveMod）
- `moveTo(col, row)` — 修改坐标
- `takeDamage(damage)` — 扣血，hp≤0 时 alive 置 false
- `markActed()` — hasActed = true
- `reveal()` — revealed = true

## 变更记录

- `effectiveMoveRange` 从 getter 改为方法，接受 `Campaign` 参数以接入 `moveMod`
- 移除 `markReinforcement()` 死方法（从未被调用）
- 移除 `Campaign` 循环依赖（显式 import）
