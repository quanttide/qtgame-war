# Campaign 模块现状

## 当前状态

战役状态容器，可变对象，跟踪华野战力、帝丘店防御、援军状态和胜负判定。提供战力描述和相关修正的计算方法。

## 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| huayePower | int | 华野战力值（0-100+），影响命中修正和移动修正，默认 85 |
| fortStrength | int | 帝丘店防御强度，默认 3，影响攻城战斗 |
| arrived | `Map<String, bool>` | 援军到达标记，key 为 `arrived_flag`，如 `{'qiu_arrived': false, 'hu_arrived': false}` |
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

## 构造方法
- `Campaign({int huayePower = 85, int fortStrength = 3, bool gameOver = false, bool? victory, String victoryDetail = ''})`
  - `arrived` 初始化为空 map `{}`，由 `fromJson` 工厂预填充各援军标记
- `Campaign.fromJson(Map<String, dynamic> json)` — 从 `campaign.json` 构造，自动初始化 `arrived` 键

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

// 直接修改字段
campaign.huayePower -= 10;

// 查询战力状态
print(campaign.powerDesc); // '尚可'（当 huayePower=60）
print(campaign.hitMod);    // 0
print(campaign.moveMod);   // 0
```

## 问题与技术债

| 问题 | 状态 | 说明 |
|------|------|------|
| 命名污染 | ❌ 待解决 | huayePower、qiuReinforceTurn 等拼音+英文混用 |
| 配置/状态混杂 | ✅ 已解决 | qiuReinforceTurn/huReinforceTurn（配置）已移至 CampaignConfig，arrived（状态）保留在 Campaign |
| 硬编码阈值 | ❌ 待解决 | hitMod/moveMod 的 if-else 链数值写死，无配置化 |
| victory 语义模糊 | ❌ 待解决 | bool? 字段，失败分支在 UI 中未完整实现 |
| 被动无逻辑 | ❌ 待解决 | 只提供数据，不驱动战役推进（援军到达、战力衰减等） |
