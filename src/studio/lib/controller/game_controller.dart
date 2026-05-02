import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/unit.dart';
import '../models/campaign.dart';
import '../models/combat.dart';
import '../models/game.dart';
import '../models/battlefield.dart';

enum GamePhase { player, ai, gameOver }

class GameState {
  List<Unit> units;
  int? selectedUnitId;
  Set<String> moveCandidates;
  Set<String> attackCandidates;
  int currentTurn;
  GamePhase phase;
  Campaign campaign;
  List<Dispatch> logMessages;

  GameState({
    required this.units,
    this.selectedUnitId,
    this.moveCandidates = const {},
    this.attackCandidates = const {},
    this.currentTurn = 1,
    this.phase = GamePhase.player,
    required this.campaign,
    this.logMessages = const [],
  });

  List<Unit> get playerUnits =>
      units.where((u) => u.alive && u.side == Side.blue).toList();
  List<Unit> get enemyUnits =>
      units.where((u) => u.alive && u.side == Side.red).toList();
  List<Unit> get readyPlayerUnits =>
      units.where((u) => u.alive && u.side == Side.blue && !u.hasActed).toList();
  Unit? get selectedUnit => selectedUnitId != null
      ? units.cast<Unit?>().firstWhere(
            (u) => u!.id == selectedUnitId,
            orElse: () => null,
          )
      : null;
  bool get isGameOver => phase == GamePhase.gameOver;
}

class GameController extends ChangeNotifier {
  final Game engine;
  final GameState _state;
  GameState get state => _state;

  GameController(this.engine)
      : _state = GameState(
          units: engine.createInitialUnits(),
          campaign: Campaign(),
          logMessages: [
            const Dispatch('\u{1F4FB}野司：包围黄百韬于帝丘店！', 'info', 1),
            const Dispatch('\u23F0邱清泉预计第8回合到达，胡琏第7回合', 'info', 1),
            const Dispatch('\u{1F4A1}点击己方单位 \u2192 蓝色格移动 \u2192 红色格攻击', 'info', 1),
          ],
        );

  void selectUnit(int unitId) {
    if (_state.phase != GamePhase.player || _state.isGameOver) return;
    final unit = _state.units.cast<Unit?>().firstWhere(
          (u) => u!.id == unitId,
          orElse: () => null,
        );
    if (unit == null || !unit.alive || unit.side != Side.blue || unit.hasActed) {
      return;
    }

    if (_state.selectedUnitId == unitId) {
      _clearSelection();
      return;
    }

    _state.selectedUnitId = unitId;
    _state.moveCandidates =
        engine.getMoveRange(unit, _state.units).keys.toSet();
    _state.attackCandidates = engine.getAttackTargets(unit, _state.units);
    notifyListeners();
  }

  void clickHex(int col, int row) {
    if (_state.phase != GamePhase.player || _state.isGameOver) return;
    final clicked = engine.getUnitAt(col, row, _state.units);
    final key = '$col,$row';

    if (_state.selectedUnitId != null) {
      final su = _state.selectedUnit;
      if (su != null && su.alive && !su.hasActed) {
        if (_state.attackCandidates.contains(key) &&
            clicked != null &&
            clicked.side == Side.red &&
            clicked.revealed) {
          _executeAttack(su, clicked);
          return;
        }
        if (_state.moveCandidates.contains(key) && clicked == null) {
          _executeMove(su, col, row);
          return;
        }
        if (clicked != null &&
            clicked.side == Side.blue &&
            clicked.id != _state.selectedUnitId) {
          selectUnit(clicked.id);
          return;
        }
        if (clicked != null && clicked.id == _state.selectedUnitId) {
          _clearSelection();
          return;
        }
      }
    }

    if (clicked != null &&
        clicked.side == Side.blue &&
        clicked.alive &&
        !clicked.hasActed) {
      selectUnit(clicked.id);
      return;
    }

    if (clicked == null && _state.selectedUnitId != null) {
      _clearSelection();
    }
  }

  void _executeMove(Unit unit, int tc, int tr) {
    final key = '$tc,$tr';
    if (!_state.moveCandidates.contains(key)) return;

    unit.moveTo(tc, tr);
    _state.campaign.huayePower =
        (_state.campaign.huayePower - 1).clamp(5, 100);
    _state.logMessages = [
      ..._state.logMessages,
      Dispatch('${unit.type.name} 向 ($tc,$tr) 推进', 'info', _state.currentTurn),
    ];

    _state.moveCandidates = {};
    _state.attackCandidates =
        engine.getAttackTargets(unit, _state.units);
    notifyListeners();
  }

  void _executeAttack(Unit attacker, Unit defender) {
    final result =
        resolveCombat(attacker, defender, _state.campaign, engine.mapTerrain);

    _state.campaign.huayePower =
        (_state.campaign.huayePower - 3).clamp(5, 100);

    _state.logMessages = [
      ..._state.logMessages,
      Dispatch('${attacker.type.name} \u2192 ${defender.type.name}：${result.text}',
          'hit', _state.currentTurn),
    ];

    if (result.killed) {
      final defTerrain = engine.mapTerrain[defender.row][defender.col];
      if (terrainProps[defTerrain]!.isCore) {
        _state.campaign.fortStrength =
            (_state.campaign.fortStrength - 1).clamp(0, 5);
        _state.logMessages = [
          ..._state.logMessages,
          Dispatch(
              '\u{1F3F0}帝丘店核心防御被削弱！（剩余强度${_state.campaign.fortStrength}）',
              'urgent',
              _state.currentTurn),
        ];
      }
    }

    defender.reveal();
    defender.takeDamage(result.damage);
    attacker.markActed();

    engine.checkVictory(_state.units, _state.campaign, _state.currentTurn);

    _state.selectedUnitId = null;
    _state.moveCandidates = {};
    _state.attackCandidates = {};
    _state.phase = _state.campaign.gameOver ? GamePhase.gameOver : _state.phase;
    notifyListeners();
  }

  void endTurn() async {
    if (_state.phase != GamePhase.player || _state.isGameOver) return;

    for (final u in _state.units) {
      if (u.side == Side.blue) u.markActed();
    }

    _state.selectedUnitId = null;
    _state.moveCandidates = {};
    _state.attackCandidates = {};
    _state.phase = GamePhase.ai;
    _state.logMessages = [
      ..._state.logMessages,
      const Dispatch('\u23F0华野回合结束，国军开始行动\u2026', 'info', 0),
    ];
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    _aiStep();
  }

  void _aiStep() {
    if (_state.phase != GamePhase.ai || _state.isGameOver) return;

    final (reinforcements, spawnLogs) = engine.spawnReinforcements(
        _state.units, _state.campaign, _state.currentTurn);
    if (reinforcements.isNotEmpty) {
      _state.units.addAll(reinforcements);
      _state.logMessages = [..._state.logMessages, ...spawnLogs];
    }

    for (final nu in _state.enemyUnits.where((u) => u.revealed)) {
      final targets = _state.playerUnits.where((pu) {
        final d =
            Battlefield.hexDistance(nu.col, nu.row, pu.col, pu.row);
        if (d > nu.type.attackRange) return false;
        if (Game.inFullCover(pu, engine.mapTerrain) && d > 1) return false;
        return true;
      }).toList();

      if (targets.isNotEmpty) {
        targets.sort((a, b) =>
            (b.type.baseAttack + (b.type.isAssault ? 5 : 0))
                .compareTo(a.type.baseAttack + (a.type.isAssault ? 5 : 0)));
        final result = resolveCombat(
            nu, targets.first, _state.campaign, engine.mapTerrain);
        _state.logMessages = [
          ..._state.logMessages,
          Dispatch('${nu.type.name} \u2192 ${targets.first.type.name}：${result.text}',
              'urgent', _state.currentTurn),
        ];

        if (_state.playerUnits.isEmpty) {
          _state.campaign.gameOver = true;
          _state.campaign.victory = false;
          _state.campaign.victoryDetail = '华野部队已无力再战，帝丘店未能攻克。';
          _state.phase = GamePhase.gameOver;
          notifyListeners();
          return;
        }
      }
    }

    var newTurn = _state.currentTurn + 1;
    _state.campaign.huayePower =
        (_state.campaign.huayePower - 1).clamp(5, 100);

    engine.checkVictory(_state.units, _state.campaign, newTurn);

    if (!_state.campaign.gameOver && newTurn > 12) {
      _state.campaign.gameOver = true;
      _state.campaign.victory = false;
      _state.campaign.victoryDetail = '时间耗尽，援军逼近，华野被迫撤出战斗。';
      _state.logMessages = [
        ..._state.logMessages,
        const Dispatch('\u{1F480}时间耗尽，未能攻克帝丘店。', 'urgent', 0),
      ];
    }

    if (_state.campaign.gameOver) {
      _state.currentTurn = newTurn;
      _state.phase = GamePhase.gameOver;
      notifyListeners();
      return;
    }

    for (final u in _state.units) {
      if (u.side == Side.blue) u.hasActed = false;
    }

    _state.selectedUnitId = null;
    _state.moveCandidates = {};
    _state.attackCandidates = {};
    _state.currentTurn = newTurn;
    _state.phase = GamePhase.player;
    notifyListeners();
  }

  void reset() {
    _state.units = engine.createInitialUnits();
    _state.campaign = Campaign();
    _state.selectedUnitId = null;
    _state.moveCandidates = {};
    _state.attackCandidates = {};
    _state.currentTurn = 1;
    _state.phase = GamePhase.player;
    _state.logMessages = [
      const Dispatch('\u{1F4FB}野司：包围黄百韬于帝丘店！', 'info', 1),
      const Dispatch('\u23F0邱清泉预计第8回合到达，胡琏第7回合', 'info', 1),
      const Dispatch('\u{1F4A1}点击己方单位 \u2192 蓝色格移动 \u2192 红色格攻击', 'info', 1),
    ];
    notifyListeners();
  }

  void _clearSelection() {
    _state.selectedUnitId = null;
    _state.moveCandidates = {};
    _state.attackCandidates = {};
    notifyListeners();
  }
}
