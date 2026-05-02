# Unit 模块现状

## 当前状态

不可变数据模型，所有字段 final，通过 copyWith 和操作方法返回新实例。

## 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 单位唯一标识，用于选择和引用 |
| name | String | 显示名称（如"步兵连"、"坦克营"） |
| side | Side | 所属阵营，枚举值：pla（解放军）、nationalist（国民党军） |
| col | int | 当前所在列坐标（0-based） |
| row | int | 当前所在行坐标（0-based） |
| maxHp | int | 最大生命值，创建时设定，战斗中不变 |
| hp | int | 当前生命值，初始等于 maxHp，受伤后减少，≤0 时单位死亡 |
| baseAttack | int | 基础攻击力，战斗计算基准值 |
| baseDefense | int | 基础防御力，战斗计算基准值 |
| baseMoveRange | int | 基础移动范围（格数），effectiveMoveRange 的基准 |
| attackRange | int | 攻击范围（格数），1 为近战，≥2 为远程 |
| special | UnitAbility? | 特殊能力，null 或 UnitAbility.assault（突击） |
| hasActed | bool | 本回合是否已行动（移动/攻击），true 时不可再操作 |
| revealed | bool | 是否已被敌方发现（用于迷雾/隐藏机制） |
| alive | bool | 是否存活，hp≤0 时自动设为 false |
| isReinforcement | bool | 是否为增援单位（影响初始显示/部署逻辑） |

## 枚举定义

```dart
enum Side { pla, nationalist }
enum UnitAbility { assault }
```

## 方法说明

### 构造方法
- `Unit({required id, required name, required side, required col, required row, required maxHp, int? hp, required baseAttack, required baseDefense, required baseMoveRange, required attackRange, UnitAbility? special, bool hasActed = false, bool revealed = false, bool alive = true, bool isReinforcement = false})`
  - hp 可选，未提供时默认等于 maxHp
  - 其他布尔字段默认 false

### 计算方法
- `int get effectiveMoveRange => baseMoveRange`
  - 当前直接返回 baseMoveRange，预留战役/地形修正接口

### 操作方法（均返回新实例，不修改原对象）
- `Unit copyWith({...})` — 通用拷贝方法，可选覆盖任意字段
- `Unit moveTo(int newCol, int newRow)` — 移动到新坐标，返回新实例
- `Unit takeDamage(int damage)` — 承受伤害，hp 减少 damage（下限 0），alive 根据新 hp 自动更新
- `Unit markActed()` — 标记已行动（hasActed = true）
- `Unit reveal()` — 标记为已揭示（revealed = true）
- `Unit markReinforcement()` — 标记为增援单位（isReinforcement = true）

## 使用示例

```dart
// 创建单位
final unit = Unit(
  id: 1,
  name: '步兵连',
  side: Side.pla,
  col: 3, row: 5,
  maxHp: 10, hp: 10,
  baseAttack: 5, baseDefense: 3,
  baseMoveRange: 3, attackRange: 1,
);

// 移动
final moved = unit.moveTo(4, 5);

// 受伤
final damaged = unit.takeDamage(3); // hp=7, alive=true

// 致命伤害
final dead = unit.takeDamage(10); // hp=0, alive=false

// 标记已行动
final acted = unit.markActed();
```

## 现存问题

1. **effectiveMoveRange 摆设** — 直接返回 baseMoveRange，战役/地形修正未接入
2. **初始数据耦合** — createInitialUnits() 硬编码在 Game 类，未外置为模板配置
3. **UnitAbility 单一** — 仅有 assault，未扩展其他特技类型

## 已解决

- ✅ 不可变设计：所有字段 final，操作方法返回新实例
- ✅ Side 枚举化：enum Side { pla, nationalist }
- ✅ UnitAbility 枚举化：enum UnitAbility { assault }
- ✅ copyWith 已运用：所有操作方法基于 copyWith

## 改进方向

- effectiveMoveRange 接入地形/战役修正逻辑
- 单位模板数据外置（JSON/配置），解耦初始数据
- 扩展 UnitAbility 枚举，支持更多特技类型（如防空、侦察、工兵等）
