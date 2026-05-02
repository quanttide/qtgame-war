# Campaign 模块现状

## 当前状态

战役状态容器，可变对象，跟踪华野战力、帝丘店防御、援军状态和胜负判定。提供战力描述和相关修正的计算方法。

## 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| huayePower | int | 华野战力值（0-100+），影响命中修正和移动修正，默认 85 |
| fortStrength | int | 帝丘店防御强度，默认 3，影响攻城战斗 |
| qiuReinforceTurn | int | 邱清泉援军到达回合（配置值），默认 8 |
| huReinforceTurn | int | 胡琏援军到达回合（配置值），默认 7 |
| qiuArrived | bool | 邱清泉援军是否已到达，默认 false |
| huArrived | bool | 胡琏援军是否已到达，默认 false |
| gameOver | bool | 游戏是否结束，默认 false |
| victory | bool? | 胜负状态：null=进行中，true=玩家胜利，false=玩家失败 |
| victoryDetail | String | 胜利/失败的详细描述，默认空字符串 |

## 计算方法

- `String get powerDesc` — 根据 huayePower 返回战力描述：
  - ≥70 → '充沛'
  - ≥45 → '尚可'
  - ≥25 → '吃紧'
  - <25 → '濒临极限'

- `int get hitMod` — 命中修正值，根据 huayePower：
  - ≥70 → +5
  - ≥45 → 0
  - ≥25 → -5
  - <25 → -12

- `int get moveMod` — 移动修正值（敌方移动范围加成），根据 huayePower：
  - ≥70 → 0
  - ≥45 → 0
  - ≥25 → +1
  - <25 → +2

## 方法说明

### 构造方法
- `Campaign({int huayePower = 85, int fortStrength = 3, int qiuReinforceTurn = 8, int huReinforceTurn = 7, bool qiuArrived = false, bool huArrived = false, bool gameOver = false, bool? victory, String victoryDetail = ''})`
  - 所有字段均有默认值，可直接 `Campaign()` 创建默认战役状态

### 拷贝方法
- `Campaign copy()` — 返回字段值完全相同的新实例（浅拷贝）

## 使用示例

```dart
// 创建默认战役
final campaign = Campaign();

// 创建自定义战役
final custom = Campaign(
  huayePower: 60,
  fortStrength: 4,
  qiuReinforceTurn: 10,
  huReinforceTurn: 9,
);

// 拷贝并修改（当前需手动逐个字段复制）
final updated = Campaign(
  huayePower: campaign.huayePower - 10,
  fortStrength: campaign.fortStrength,
  qiuReinforceTurn: campaign.qiuReinforceTurn,
  huReinforceTurn: campaign.huReinforceTurn,
  qiuArrived: campaign.qiuArrived,
  huArrived: campaign.huArrived,
  gameOver: campaign.gameOver,
  victory: campaign.victory,
  victoryDetail: campaign.victoryDetail,
);

// 查询战力状态
print(campaign.powerDesc); // '尚可'（当 huayePower=60）
print(campaign.hitMod);    // 0
print(campaign.moveMod);   // 0
```

## 问题与技术债

| 问题 | 状态 | 说明 |
|------|------|------|
| 可变性泛滥 | ❌ 待解决 | 所有字段可变，无 final，副作用难追踪 |
| 命名污染 | ❌ 待解决 | huayePower、qiuReinforceTurn 等拼音+英文混用 |
| 配置/状态混杂 | ❌ 待解决 | qiuReinforceTurn/huReinforceTurn（配置）与 qiuArrived（状态）在同一对象 |
| 硬编码阈值 | ❌ 待解决 | hitMod/moveMod 的 if-else 链数值写死，无配置化 |
| copy() 非 copyWith | ❌ 待解决 | 仅支持全量拷贝，缺少增量更新能力 |
| victory 语义模糊 | ❌ 待解决 | bool? 字段，失败分支在 UI 中未完整实现 |
| 被动无逻辑 | ❌ 待解决 | 只提供数据，不驱动战役推进（援军到达、战力衰减等） |
