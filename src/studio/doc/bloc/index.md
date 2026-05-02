# 状态管理层现状

BLoC 已移除，替换为 `GameController`（ChangeNotifier）。

## GameController

`lib/controller/game_controller.dart` — 单文件，包含：

| 组成部分 | 说明 |
|---------|------|
| `GamePhase` enum | player / ai / gameOver |
| `GameState` class | 全 mutable 状态容器，无 copyWith，无 Equatable |
| `GameController` class | ChangeNotifier，提供方法替代 BLoC 事件 |

## 方法替代事件

| 旧事件 | 新方法 |
|--------|--------|
| SelectUnit | `selectUnit(int id)` |
| ClickHex | `clickHex(int col, int row)` |
| EndTurn | `endTurn()` |
| ResetGame | `reset()` |
| AiStep | `_aiStep()`（私有） |
| ClearSelection | `_clearSelection()`（私有） |

## UI 绑定

- `ListenableBuilder` 替代 `BlocBuilder`
- `controller.addListener(callback)` 替代 `BlocListener`
- 直接调用 `controller.xxx()` 替代 `context.read<GameBloc>().add(Event)`
- 视图通过构造参数接收 `controller`，无 InheritedWidget / Provider 开销

## GameState 字段

| 字段 | 类型 | 可变性 |
|------|------|--------|
| units | `List<Unit>` | mutable list, mutable items |
| selectedUnitId | `int?` | mutable |
| moveCandidates | `Set<String>` | mutable |
| attackCandidates | `Set<String>` | mutable |
| currentTurn | `int` | mutable |
| phase | `GamePhase` | mutable |
| campaign | `Campaign` | mutable |
| logMessages | `List<Dispatch>` | reassignable |
