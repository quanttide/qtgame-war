# 状态管理层

## 架构

单文件 `lib/controllers/game_controller.dart`，包含三个定义：

| 定义 | 角色 |
|------|------|
| `GamePhase` enum | 三态：player / ai / gameOver |
| `GameState` class | 可变的单一状态容器 |
| `GameController` | ChangeNotifier，暴露操作方法 |

选择单文件而非拆分三文件，因为三者高度耦合——每次加功能都需要同时改 phase 转换、state 字段、controller 方法，分文件只会增加跳转成本。

## GameController API

所有状态变更通过 `GameController` 的方法调用触发：

| 方法 | 触发时机 |
|------|----------|
| `selectUnit(id)` | 点击己方单位 |
| `clickHex(col, row)` | 点击地图格子 |
| `endTurn()` | 点击结束回合 |
| `reset()` | 重置游戏 |

私有方法（`_aiStep`、`_clearSelection`）不暴露给外部。

```dart
// 视图层标准用法
final controller = GameController();
ListenableBuilder(
  listenable: controller,
  builder: (_, _) => /* 读 controller.state.xxx */,
);
```

## GameState

所有字段公开可写，无 copyWith、无 Equatable、无封装层：

| 字段 | 类型 | 说明 |
|------|------|------|
| `units` | `List<Unit>` | 全部单位，含敌我 |
| `selectedUnitId` | `int?` | 当前选中单位 |
| `moveCandidates` | `Set<String>` | 可移动位置，"col,row" |
| `attackCandidates` | `Set<String>` | 可攻击位置 |
| `currentTurn` | `int` | 回合计数 |
| `phase` | `GamePhase` | 当前阶段 |
| `campaign` | `Campaign` | 战役状态 |
| `logMessages` | `List<Dispatch>` | 行动日志 |

## 设计约束

- **不拆分 Controller**：目前只有一个 controller。如果出现多个独立状态树（如战役层 + 战场层并行），才考虑拆分
- **不引入 Provider**：视图树仅 2 层，controller 通过构造参数传递即可
- **不变性靠约定**：mutable 字段意味着代码任何位置都可能改状态。维护者需遵守"只通过 controller 方法改状态"的约定，不直接修改 `state.xxx`
- **不保留事件历史**：失去了 BLoC 的事件追溯能力。如果将来需要回放/调试，改为记录 `List<GameEvent>` 而非重建事件驱动架构
