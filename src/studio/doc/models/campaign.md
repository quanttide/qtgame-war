# Campaign 模块

## 职责

战役运行时状态容器。记录当前战役的全局动态数值，字段名保持战役无关（不包含 "huaye""diqiudian" 等专名）。

## 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| playerPower | int | 己方综合战力（0-100），影响命中修正和移动消耗，默认 85 |
| fortStrength | int | 目标防御工事强度，降为 0 且核心格被占则胜利 |
| arrived | `Map<String, bool>` | 援军到达标记，key 为 arrived_flag |
| gameOver | bool | 战役是否结束 |
| victory | bool? | null=进行中，true=胜，false=败 |
| victoryDetail | String | 胜负详情文本 |

## 计算方法

- `String get powerDesc` — 根据 playerPower 返回战力描述：
  - ≥70 → '充沛'
  - ≥45 → '尚可'
  - ≥25 → '吃紧'
  - <25 → '濒临极限'

- `int get hitMod` — 命中修正值，根据 playerPower：
  - ≥70 → +5
  - ≥45 → 0
  - ≥25 → -5
  - <25 → -12

- `int get moveMod` — 移动消耗修正（越大移动力越少），根据 playerPower：
  - ≥70 → 0
  - ≥45 → 0
  - ≥25 → +1
  - <25 → +2

## 构造方法

```dart
Campaign({
  int playerPower = 85,
  int fortStrength = 3,
  bool gameOver = false,
  bool? victory,
  String victoryDetail = '',
})
```

## 变更记录

- `huayePower` → `playerPower`：通用化命名，不绑定"华野"上下文
- 移除 `Campaign.fromJson` 工厂：未被调用，改由 `CampaignConfig` 加载后直接构造
