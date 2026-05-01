import 'package:equatable/equatable.dart';
import 'unit.dart';
import 'campaign_state.dart';

enum GamePhase { player, ai, gameOver }

class GameState extends Equatable {
  final List<Unit> units;
  final int? selectedUnitId;
  final Set<String> moveCandidates;
  final Set<String> attackCandidates;
  final int currentTurn;
  final GamePhase phase;
  final CampaignState campaign;
  final List<LogMessage> logMessages;

  const GameState({
    required this.units,
    this.selectedUnitId,
    this.moveCandidates = const {},
    this.attackCandidates = const {},
    this.currentTurn = 1,
    this.phase = GamePhase.player,
    required this.campaign,
    this.logMessages = const [],
  });

  List<Unit> get playerUnits => units.where((u) => u.alive && u.side == 'pla').toList();
  List<Unit> get nationalistUnits => units.where((u) => u.alive && u.side == 'nationalist').toList();
  List<Unit> get readyPlayerUnits => units.where((u) => u.alive && u.side == 'pla' && !u.hasActed).toList();
  Unit? get selectedUnit => selectedUnitId != null ? units.cast<Unit?>().firstWhere((u) => u!.id == selectedUnitId, orElse: () => null) : null;
  bool get isGameOver => phase == GamePhase.gameOver;

  GameState copyWith({
    List<Unit>? units,
    int? selectedUnitId,
    Set<String>? moveCandidates,
    Set<String>? attackCandidates,
    int? currentTurn,
    GamePhase? phase,
    CampaignState? campaign,
    List<LogMessage>? logMessages,
    bool clearSelection = false,
  }) {
    return GameState(
      units: units ?? this.units.map((u) => u.copy()).toList(),
      selectedUnitId: clearSelection ? null : (selectedUnitId ?? this.selectedUnitId),
      moveCandidates: moveCandidates ?? this.moveCandidates,
      attackCandidates: attackCandidates ?? this.attackCandidates,
      currentTurn: currentTurn ?? this.currentTurn,
      phase: phase ?? this.phase,
      campaign: campaign ?? this.campaign,
      logMessages: logMessages ?? this.logMessages,
    );
  }

  @override
  List<Object?> get props => [
        units.map((u) => '${u.id}:${u.col},${u.row}:${u.hp}:${u.alive}:${u.hasActed}:${u.revealed}').join('|'),
        selectedUnitId,
        moveCandidates,
        attackCandidates,
        currentTurn,
        phase,
        campaign.huayePower,
        campaign.fortStrength,
        campaign.gameOver,
        campaign.victory,
        campaign.qiuArrived,
        campaign.huArrived,
        logMessages.length,
      ];
}

class LogMessage {
  final String msg;
  final String type;
  final int turn;
  const LogMessage(this.msg, this.type, this.turn);
}
