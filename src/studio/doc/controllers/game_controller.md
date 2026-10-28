# GameController

## 定义位置

| 类型 | 文件 |
|------|------|
| `GamePhase` enum | `models/game.dart` |
| `GameState` class | `models/game.dart` |
| `GameController` class | `controllers/game_controller.dart` |

## API

### 交互入口（依赖点击态）

| 方法 | 触发时机 |
|------|----------|
| `selectUnit(id)` | 点击己方单位 |
| `clickHex(col, row)` | 点击地图格子 |
| `endTurn()` | 点击结束回合 |
| `reset()` | 重置游戏 |

### 领域执行口子（不依赖点击态）

| 方法 | 说明 |
|------|------|
| `applyMove(unit, col, row)` → `ExecutionResult` | 移动一个单位。用引擎真实移动范围校验，不读 `moveCandidates`。供 CommandExecutor 驱动 |
| `applyAttack(attacker, defender)` → `ExecutionResult` | 攻击一个单位。用引擎真实攻击范围校验，不读 `attackCandidates`/`selectedUnitId` |

两者各自拥有不变量（自行校验存活/阵营/可达/射程），返回 `ExecutionResult`（成功与否 + 战报），不触碰 `selectedUnitId`/`moveCandidates`/`attackCandidates`，不 `notify`。`_executeMove`/`_executeAttack` 退化为薄适配器：调用领域口子 + 补 UI 态（清候选/重算/通知）。这是「引擎被命令驱动」的入口。

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
