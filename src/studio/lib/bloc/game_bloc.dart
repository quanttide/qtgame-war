import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/terrain.dart';
import '../models/unit.dart';
import '../models/campaign.dart';
import '../models/game.dart';
import 'game_state.dart';
import 'game_event.dart';
import '../models/battlefield.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GameEngine engine;

  GameBloc(this.engine)
      : super(GameState(
          units: engine.createInitialUnits(),
          campaign: Campaign(),
          logMessages: const [
            Dispatch('\u{1F4FB}野司：包围黄百韬于帝丘店！', 'info', 1),
            Dispatch('\u23F0邱清泉预计第8回合到达，胡琏第7回合', 'info', 1),
            Dispatch('\u{1F4A1}点击己方单位 \u2192 蓝色格移动 \u2192 红色格攻击', 'info', 1),
          ],
        )) {
    on<SelectUnit>(_onSelectUnit);
    on<ClickHex>(_onClickHex);
    on<EndTurn>(_onEndTurn);
    on<ResetGame>(_onReset);
    on<AiStep>(_onAiStep);
    on<ClearSelection>(_onClearSelection);
  }

  void _onSelectUnit(SelectUnit event, Emitter<GameState> emit) {
    if (state.phase != GamePhase.player || state.isGameOver) return;
    final unit = state.units.cast<Unit?>().firstWhere((u) => u!.id == event.unitId, orElse: () => null);
    if (unit == null || !unit.alive || unit.side != 'pla' || unit.hasActed) return;

    if (state.selectedUnitId == event.unitId) {
      emit(state.copyWith(clearSelection: true));
      return;
    }

    final moveRange = engine.getMoveRange(unit, state.units);
    final attackRange = engine.getAttackTargets(unit, state.units);
    emit(state.copyWith(
      selectedUnitId: event.unitId,
      moveCandidates: moveRange.keys.toSet(),
      attackCandidates: attackRange,
    ));
  }

  void _onClickHex(ClickHex event, Emitter<GameState> emit) {
    if (state.phase != GamePhase.player || state.isGameOver) return;
    final col = event.col;
    final row = event.row;
    final clicked = engine.getUnitAt(col, row, state.units);
    final key = '$col,$row';

    if (state.selectedUnitId != null) {
      final su = state.selectedUnit;
      if (su != null && su.alive && !su.hasActed) {
        if (state.attackCandidates.contains(key) && clicked != null && clicked.side == 'nationalist' && clicked.revealed) {
          _executeAttack(su, clicked, emit);
          return;
        }
        if (state.moveCandidates.contains(key) && clicked == null) {
          _executeMove(su, col, row, emit);
          return;
        }
        if (clicked != null && clicked.side == 'pla' && clicked.id != state.selectedUnitId) {
          add(SelectUnit(clicked.id));
          return;
        }
        if (clicked != null && clicked.id == state.selectedUnitId) {
          add(const ClearSelection());
          return;
        }
      }
    }

    if (clicked != null && clicked.side == 'pla' && clicked.alive && !clicked.hasActed) {
      add(SelectUnit(clicked.id));
      return;
    }

    if (clicked == null && state.selectedUnitId != null) {
      add(const ClearSelection());
    }
  }

  void _executeMove(Unit unit, int tc, int tr, Emitter<GameState> emit) {
    final key = '$tc,$tr';
    if (!state.moveCandidates.contains(key)) return;

    unit.col = tc;
    unit.row = tr;

    final newCampaign = state.campaign.copy();
    newCampaign.huayePower = (newCampaign.huayePower - 1).clamp(5, 100);

    final newLogs = [...state.logMessages, Dispatch('${unit.name} 向 ($tc,$tr) 推进', 'info', state.currentTurn)];

    final attackRange = engine.getAttackTargets(unit, state.units);

    emit(state.copyWith(
      moveCandidates: {},
      attackCandidates: attackRange,
      campaign: newCampaign,
      logMessages: newLogs,
    ));
  }

  void _executeAttack(Unit attacker, Unit defender, Emitter<GameState> emit) {
    final result = engine.resolveCombat(attacker, defender, state.campaign);
    final newCampaign = state.campaign.copy();
    newCampaign.huayePower = (newCampaign.huayePower - 3).clamp(5, 100);

    final newLogs = <Dispatch>[...state.logMessages];
    newLogs.add(Dispatch('${attacker.name} \u2192 ${defender.name}：${result.text}', 'hit', state.currentTurn));

    if (result.killed) {
      final defTerrain = engine.mapTerrain[defender.row][defender.col];
      if (terrainProps[defTerrain]!.isCore) {
        newCampaign.fortStrength = (newCampaign.fortStrength - 1).clamp(0, 5);
        newLogs.add(Dispatch('\u{1F3F0}帝丘店核心防御被削弱！（剩余强度${newCampaign.fortStrength}）', 'urgent', state.currentTurn));
      }
    }

    defender.revealed = true;
    attacker.hasActed = true;

    engine.checkVictory(state.units, newCampaign, state.currentTurn);

    emit(state.copyWith(
      selectedUnitId: null,
      moveCandidates: {},
      attackCandidates: {},
      campaign: newCampaign,
      logMessages: newLogs,
      phase: newCampaign.gameOver ? GamePhase.gameOver : state.phase,
    ));
  }

  Future<void> _onEndTurn(EndTurn event, Emitter<GameState> emit) async {
    if (state.phase != GamePhase.player || state.isGameOver) return;

    for (final u in state.units) {
      if (u.side == 'pla') u.hasActed = true;
    }

    final newLogs = [...state.logMessages, Dispatch('\u23F0华野回合结束，国军开始行动\u2026', 'info', state.currentTurn)];

    emit(state.copyWith(
      selectedUnitId: null,
      moveCandidates: {},
      attackCandidates: {},
      phase: GamePhase.ai,
      logMessages: newLogs,
    ));

    await Future.delayed(const Duration(milliseconds: 500));
    add(const AiStep());
  }

  Future<void> _onAiStep(AiStep event, Emitter<GameState> emit) async {
    if (state.phase != GamePhase.ai || state.isGameOver) return;

    var currentCampaign = state.campaign;
    var currentLogs = List<Dispatch>.from(state.logMessages);

    final (reinforcements, spawnLogs) = engine.spawnReinforcements(state.units, currentCampaign, state.currentTurn);
    if (reinforcements.isNotEmpty) {
      state.units.addAll(reinforcements);
      currentLogs.addAll(spawnLogs);
    }

    for (final nu in state.nationalistUnits.where((u) => u.revealed)) {
      final targets = state.playerUnits.where((pu) {
        final d = Battlefield.hexDistance(nu.col, nu.row, pu.col, pu.row);
        if (d > nu.attackRange) return false;
        if (pu.isInFullCover(engine.mapTerrain) && d > 1) return false;
        return true;
      }).toList();

      if (targets.isNotEmpty) {
        targets.sort((a, b) => (b.baseAttack + (b.special == 'assault' ? 5 : 0))
            .compareTo(a.baseAttack + (a.special == 'assault' ? 5 : 0)));
        final result = engine.resolveCombat(nu, targets.first, currentCampaign);
        currentLogs.add(Dispatch('${nu.name} \u2192 ${targets.first.name}：${result.text}', 'urgent', state.currentTurn));

        if (state.playerUnits.isEmpty) {
          currentCampaign.gameOver = true;
          currentCampaign.victory = false;
          currentCampaign.victoryDetail = '华野部队已无力再战，帝丘店未能攻克。';
          emit(state.copyWith(
            campaign: currentCampaign,
            phase: GamePhase.gameOver,
            logMessages: currentLogs,
          ));
          return;
        }
      }
    }

    var newTurn = state.currentTurn + 1;
    currentCampaign.huayePower = (currentCampaign.huayePower - 1).clamp(5, 100);

    engine.checkVictory(state.units, currentCampaign, newTurn);

    if (!currentCampaign.gameOver && newTurn > 12) {
      currentCampaign.gameOver = true;
      currentCampaign.victory = false;
      currentCampaign.victoryDetail = '时间耗尽，援军逼近，华野被迫撤出战斗。';
      currentLogs.add(Dispatch('\u{1F480}时间耗尽，未能攻克帝丘店。', 'urgent', newTurn));
    }

    if (currentCampaign.gameOver) {
      emit(state.copyWith(
        campaign: currentCampaign,
        phase: GamePhase.gameOver,
        currentTurn: newTurn,
        logMessages: currentLogs,
      ));
      return;
    }

    for (final u in state.units) {
      if (u.side == 'pla') u.hasActed = false;
    }

    emit(state.copyWith(
      selectedUnitId: null,
      moveCandidates: {},
      attackCandidates: {},
      currentTurn: newTurn,
      phase: GamePhase.player,
      campaign: currentCampaign,
      logMessages: currentLogs,
    ));
  }

  void _onReset(ResetGame event, Emitter<GameState> emit) {
    emit(GameState(
      units: engine.createInitialUnits(),
      campaign: Campaign(),
      logMessages: const [
        Dispatch('\u{1F4FB}野司：包围黄百韬于帝丘店！', 'info', 1),
        Dispatch('\u23F0邱清泉预计第8回合到达，胡琏第7回合', 'info', 1),
        Dispatch('\u{1F4A1}点击己方单位 \u2192 蓝色格移动 \u2192 红色格攻击', 'info', 1),
      ],
    ));
  }

  void _onClearSelection(ClearSelection event, Emitter<GameState> emit) {
    emit(state.copyWith(clearSelection: true));
  }
}
