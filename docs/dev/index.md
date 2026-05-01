# 客户端实现

要将那个六边形战棋推演页面转为 Flutter + Bloc，核心是把“状态、逻辑、视图”彻底解耦，让 Bloc 承担起原 useReducer + Context 的职责，同时把六边形画布渲染交给 CustomPainter，交互交给 GestureDetector。

下面从架构分层、Bloc 设计、关键组件和代码示例四个方面展开。

—

1. 整体架构分层

```
┌──────────────────────────────────────┐
│              UI 层 (Widgets)         │
│  ├─ GameBoard (CustomPaint + Gesture)│
│  ├─ CommandPanel (卡片、按钮、日志)  │
│  └─ CampaignOverlay                  │
└──────────────┬───────────────────────┘
               │  BlocBuilder / BlocListener
┌──────────────▼───────────────────────┐
│           Presentation Bloc          │
│  GameBloc: 处理UI事件 → 调用领域逻辑│
└──────────────┬───────────────────────┘
               │
┌──────────────▼───────────────────────┐
│          领域/数据层 (纯Dart)         │
│  ├─ GameEngine: 所有游戏规则、AI、   │
│  │   移动/攻击范围计算、战斗结算      │
│  ├─ MapData: 地图地形、坐标工具       │
│  └─ Models: Unit, CampaignState等    │
└──────────────────────────────────────┘
```

关键点：Bloc 只负责事件调度和状态输出，它调用引擎函数得到新状态，然后发射。领域层不依赖 Flutter，可单独测试。

—

2. Bloc 设计：GameBloc

2.1 状态 (GameState)

```dart
class GameState extends Equatable {
  final List<Unit> units;
  final int? selectedUnitId;
  final Set<String> moveCandidates; // ’col,row‘
  final Set<String> attackCandidates;
  final int currentTurn;
  final GamePhase phase; // player, ai, gameOver
  final List<LogMessage> logMessages;
  final CampaignStatus campaign;

  // 派生属性
  List<Unit> get playerUnits => units.where((u) => u.alive && u.side == Side.pla).toList();
  bool get isGameOver => campaign.isGameOver;

  // 通过工厂方法创建副本并更新部分字段（使用copyWith）
}
```

Equatable 可以让 Bloc 避免重复发射相同状态。

2.2 事件 (GameEvent)

```dart
abstract class GameEvent extends Equatable {}

class SelectUnit extends GameEvent { final int unitId; }
class MoveUnit extends GameEvent { final int col; final int row; }
class AttackUnit extends GameEvent { final int targetCol; final int targetRow; }
class EndTurn extends GameEvent {}
class ResetGame extends GameEvent {}
class AIStep extends GameEvent {}
```

2.3 Bloc 实现 (GameBloc)

```dart
class GameBloc extends Bloc<GameEvent, GameState> {
  final GameEngine _engine;

  GameBloc() : super(initialState) {
    on<SelectUnit>(_onSelectUnit);
    on<MoveUnit>(_onMoveUnit);
    on<AttackUnit>(_onAttackUnit);
    on<EndTurn>(_onEndTurn);
    on<ResetGame>(_onReset);
    on<AIStep>(_onAIStep);
  }

  void _onSelectUnit(SelectUnit event, Emitter<GameState> emit) {
    // 使用引擎计算可移动/攻击范围，返回新状态
    final newState = _engine.handleSelectUnit(state, event.unitId);
    emit(newState);
  }

  void _onMoveUnit(MoveUnit event, Emitter<GameState> emit) {
    final newState = _engine.executeMove(state, event.col, event.row);
    emit(newState);
    if (newState.phase == GamePhase.gameOver) return;
    // 移动后自动切换到攻击高亮（复用逻辑）
  }

  void _onAttackUnit(AttackUnit event, Emitter<GameState> emit) {
    final newState = _engine.executeAttack(state, event.targetCol, event.targetRow);
    emit(newState);
    // 攻击后自动取消选中，检查胜负
  }

  void _onEndTurn(EndTurn event, Emitter<GameState> emit) {
    // 标记所有玩家单位已行动，切换phase为ai
    final playerTurnEnd = _engine.endPlayerTurn(state);
    emit(playerTurnEnd);
    // 延迟触发AI步骤
    add(AIStep());
  }

  void _onAIStep(AIStep event, Emitter<GameState> emit) async {
    if (state.phase != GamePhase.ai) return;
    // AI 可能多步，用循环 + emit 逐步更新（例如逐个单位行动）
    final aiState = _engine.runAiStep(state);
    emit(aiState);
    if (aiState.phase == GamePhase.ai) {
      // 模拟AI延迟，继续下一步
      await Future.delayed(Duration(milliseconds: 500));
      add(AIStep());
    } else {
      // AI结束，转换到player回合
      final newTurn = aiState.copyWith(phase: GamePhase.player, currentTurn: aiState.currentTurn + 1);
      emit(newTurn);
    }
  }
}
```

关键：Bloc 内部调用 GameEngine 的纯函数，引擎返回新的 GameState，Bloc 负责发射。这样逻辑完全在引擎层，可脱离 Flutter 进行单元测试。

—

3. 领域层：GameEngine

将原 JavaScript 中的移动范围计算、战斗结算、AI 逻辑全部抽到独立的 Dart 类中，接收 GameState 并返回新的 GameState。例如：

```dart
class GameEngine {
  final MapData mapData;

  GameState handleSelectUnit(GameState state, int unitId) {
    final unit = state.units.firstWhere((u) => u.id == unitId);
    if (!unit.canAct) return state; // 不可行动则忽略
    final moveRange = _calculateMoveRange(unit, state.units, mapData);
    final attackRange = _calculateAttackTargets(unit, state.units, mapData);
    return state.copyWith(
      selectedUnitId: unitId,
      moveCandidates: moveRange,
      attackCandidates: attackRange,
    );
  }

  GameState executeAttack(GameState state, int targetCol, int targetRow) {
    // 找到攻击者（selectedUnit）和目标，调用战斗结算
    // 返回包含日志、单位血量变化、战力消耗的新状态
  }

  GameState runAiStep(GameState state) {
    // 揭示、攻击、移动，返回单步执行后的状态（用于逐步动画）
  }
}
```

MapData 包含地形数组、六边形坐标转换等工具。

—

4. UI 组件化

UI 完全不接触引擎逻辑，只使用 BlocBuilder 渲染，通过 context.read<GameBloc>().add(event) 发送事件。

4.1 主页面

```dart
class CampaignScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameBloc(),
      child: Scaffold(
        body: Column(
          children: [
            TitleBar(),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: GameBoard()),
                  CommandPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

4.2 六边形地图画板 (GameBoard)

```dart
class GameBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return GestureDetector(
          onTapUp: (details) {
            final pos = _pixelToHex(details.localPosition, state, MapData);
            if (pos != null) {
              // 根据状态判断是移动、攻击还是选中
              final unit = getUnitAt(pos.col, pos.row, state.units);
              if (unit?.side == Side.pla && !unit!.hasActed) {
                context.read<GameBloc>().add(SelectUnit(unit.id));
              } else if (state.selectedUnitId != null && state.attackCandidates.contains(pos.key)) {
                context.read<GameBloc>().add(AttackUnit(pos.col, pos.row));
              } else if (state.selectedUnitId != null && state.moveCandidates.contains(pos.key)) {
                context.read<GameBloc>().add(MoveUnit(pos.col, pos.row));
              }
            }
          },
          onLongPress: () {
            context.read<GameBloc>().add(ClearSelection()); // 可选事件
          },
          child: CustomPaint(
            size: Size(canvasWidth, canvasHeight),
            painter: HexMapPainter(state: state, mapData: MapData),
          ),
        );
      },
    );
  }
}
```

4.3 绘图器 (HexMapPainter)

```dart
class HexMapPainter extends CustomPainter {
  final GameState state;
  final MapData mapData;

  @override
  void paint(Canvas canvas, Size size) {
    // 遍历所有格子，绘制地形、高亮、单位、血条等
    // 逻辑与原来 render() 相同，只是换成 Dart Canvas API
  }

  @override
  bool shouldRepaint(covariant HexMapPainter old) {
    return old.state != state; // 状态变化即重绘
  }
}
```

4.4 指挥面板 (CommandPanel)

```dart
class CommandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return SizedBox(
          width: 260,
          child: Column(
            children: [
              TurnInfo(state: state),
              GlobalStatus(campaign: state.campaign),
              UnitCards(state: state, onSelect: (id) {
                context.read<GameBloc>().add(SelectUnit(id));
              }),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: state.isGameOver ? null : () => context.read<GameBloc>().add(EndTurn()),
                    child: Text(’结束回合‘),
                  ),
                  ElevatedButton(
                    onPressed: () => context.read<GameBloc>().add(ResetGame()),
                    child: Text(’重置‘),
                  ),
                ],
              ),
              BattleLog(logs: state.logMessages),
              Legend(),
            ],
          ),
        );
      },
    );
  }
}
```

UnitCards、BattleLog 等其他小组件都是纯展示，只从 BlocBuilder 中读取状态。

—

5. 移动端适配与触摸处理

Flutter 的 GestureDetector 天然支持触摸。需要注意：

· 长按取消选中：用 onLongPress 发送 ClearSelection 事件。
· 单指点击：onTapUp 获取 localPosition，通过 pixelToHex 转换。为防止误触，可以加 HitTestBehavior.opaque 确保画布区域响应。
· 缩放与拖动：可选，用 InteractiveViewer 包裹 CustomPaint，让玩家可以缩放/平移战役地图。

—

6. 性能与优化

· shouldRepaint：精确比较状态引用（state != old.state），因为状态是不可变的，每次变化都会生成新实例，这样能保证重绘恰好发生。
· Bloc 状态区分粒度：若担心整个 GameState 刷新导致过度绘制，可以拆分为多个 Bloc（如 MapBloc 和 CampaignBloc），但当前规模一个 Bloc 足够。
· AI 异步：使用 AIStep 事件递归发射，配合 await Future.delayed 实现动画感，不阻塞 UI。

—

7. 总结

从 HTML 到 Flutter Bloc 的转型，核心在于：

· 引擎与 UI 彻底分离：GameEngine 处理所有游戏规则，Bloc 作为中间调度器，Widgets 只发事件和渲染状态。
· Canvas 渲染用 CustomPainter：把所有像素绘制逻辑从 Web API 迁移到 Dart Canvas 类，性能优异。
· 事件驱动：用户交互全部转为 Event，保证单向数据流，调试和测试变得极度简单。
· 组件化自然形成：GameBoard 负责地图，CommandPanel 负责信息与按钮，内部再拆细，每块只依赖需要的那部分 state。

这样构建出的 Flutter 应用，逻辑清晰、可维护性极高，同时保留了原 HTML 战棋的全部核心体验。
