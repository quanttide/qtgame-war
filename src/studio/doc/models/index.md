# 领域模型现状

| 模块 | 评分 | 状态 | 关键问题 |
|------|------|------|----------|
| Battlefield | ★★★★☆ | 干净 | 网格尺寸常量绑定特定战役 |
| Unit | ★★★☆☆ | 较干净 | effectiveMoveRange 已接入 Campaign |
| Campaign | ★★★☆☆ | 已重构 | 字段名通用化，fromJson 移除 |
| Game | ★★☆☆☆ | 大杂烩 | 规则和 JSON 加载混在同一文件 |

## 核心缺失

模型定义了棋子、棋盘、规则，但缺：
- 当前回合数、行动方、单位行动序列
- 驱动"选择→移动→攻击→结束回合→AI"的状态机

## 对应文件

- `lib/models/unit.dart` — Unit 类
- `lib/models/campaign.dart` — Campaign 类（被动状态容器）
- `lib/models/game.dart` — Game 类（规则工具箱 + CampaignConfig）
- `lib/models/battlefield.dart` — Battlefield 类（六边形几何 + 地形）
