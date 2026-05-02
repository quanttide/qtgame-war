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
| side | Side | 阵营：blue / red，战役映射为己方命名 |
| type | UnitType | 兵种本体引用 |
| col / row | int | 战场坐标 |
| hp | int | 当前生命值，默认 type.maxHp |
| hasActed | bool | 本回合是否已行动 |
| revealed | bool | 是否已被发现 |
| alive | bool | hp≤0 时自动 false |
| isReinforcement | bool | 是否为增援单位 |

获取类型属性时通过 `unit.type.xxx` 访问，如 `unit.type.name`、`unit.type.baseAttack`。
### UnitLibrary（框架通用兵种）

```dart
class UnitLibrary {
  static const lightInfantry = UnitType(name: '轻步兵', maxHp: 3, ...);
  static const heavyInfantry = UnitType(name: '重步兵', maxHp: 4, ...);
  static const artillery     = UnitType(name: '炮兵',   maxHp: 2, ...);
  static const cavalry       = UnitType(name: '骑兵',   maxHp: 3, ...);
  static const assaultInfantry = UnitType(name: '突击步兵', maxHp: 3, special: assault, ...);
  static final all = [lightInfantry, heavyInfantry, artillery, cavalry, assaultInfantry];
}
```

提供通用模板。战役可自行定义专属 UnitType（如帝丘店的"四纵十二师"）。

## 枚举

```dart
enum Side { blue, red }
```

`blue` / `red` 是通用叫法，各战役映射为己方命名（如帝丘店：蓝色 = 华野，红色 = 国军）。

## 特殊能力

特殊能力用 `bool` 字段表示，当前仅支持一种：

| 字段 | 效果 |
|------|------|
| `isAssault`（突击） | ① 可进入核心阵地（`coreFort`），其他不可；② 对掩体内单位（`fullCover`）造成 2 点伤害（普通为 1）；③ UI 显示 ⚡ 图标 |

## 实例操作（原地变异，无返回值）

- `moveTo(col, row)` — 修改坐标
- `takeDamage(damage)` — 扣血，hp≤0 时 alive 自动置 false
- `markActed()` — hasActed = true
- `reveal()` — revealed = true
- `markReinforcement()` — isReinforcement = true

所有操作均为 void，直接修改字段，不返回新实例。`copyWith` 已移除。

## 战役使用示例

```dart
// 定义兵种
const ziShiEr = UnitType(name: '四纵十二师', maxHp: 2, baseAttack: 2,
    baseDefense: 1, baseMoveRange: 5, attackRange: 1, isAssault: true);

// 创建实例
Unit(id: 1, side: Side.pla, type: ziShiEr, col: 1, row: 2, revealed: true);

// 访问类型属性直接用 unit.type
print(unit.type.name);         // '四纵十二师'
print(unit.type.baseAttack);   // 2
unit.moveTo(2, 3);        // 返回新实例
unit.takeDamage(1);       // 返回新实例，hp=1
```

## 问题与技术债

| 问题 | 说明 |
|------|------|
| effectiveMoveRange 直接返回 baseMoveRange | 预留战役/地形修正接口，尚未接入 |
| 特殊能力用 bool 字段而非扩展表 | 若未来增加多种能力（防空、侦察、工兵），需重构为枚举或位字段 |
| initialUnits 硬编码在 Game 类 | 战役单位配置与框架逻辑耦合 |
