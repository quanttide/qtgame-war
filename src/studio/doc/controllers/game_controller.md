# GameController

## 定义位置

| 类型 | 文件 |
|------|------|
| `GamePhase` enum | `models/game.dart` |
| `GameState` class | `models/game.dart` |
| `GameController` class | `controllers/game_controller.dart` |

## API

| 方法 | 触发时机 |
|------|----------|
| `selectUnit(id)` | 点击己方单位 |
| `clickHex(col, row)` | 点击地图格子 |
| `endTurn()` | 点击结束回合 |
| `reset()` | 重置游戏 |

## GameState 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `units` | `List<Unit>` | 全部单位 |
| `selectedUnitId` | `int?` | 当前选中单位 |
| `moveCandidates` | `Set<String>` | 可移动位置 |
| `attackCandidates` | `Set<String>` | 可攻击位置 |
| `currentTurn` | `int` | 回合计数 |
| `phase` | `GamePhase` | 当前阶段 |
| `campaign` | `Campaign` | 战役状态 |
| `logMessages` | `List<Dispatch>` | 行动日志 |

## 设计约束

- 不引入 Provider：视图层仅 2 层，controller 通过构造参数传递
- 不变性靠约定：只通过 controller 方法改状态，不直接修改 `state.xxx`
