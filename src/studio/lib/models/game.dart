import 'dart:convert';
import 'package:flutter/services.dart';
import 'unit.dart';
import 'campaign.dart';
import 'battlefield.dart';

class CampaignConfig {
  final String name;
  final String description;
  final String date;
  final String blueName;
  final String redName;
  final int gridCols;
  final int gridRows;
  final double hexSize;
  final List<List<TerrainType>> mapTerrain;
  final Map<String, UnitType> templates;
  final List<UnitSpec> initialUnits;
  final List<ReinforcementWave> reinforcementWaves;
  final int maxTurns;
  final int initialHuayePower;
  final int initialFortStrength;

  CampaignConfig({
    required this.name,
    required this.description,
    required this.date,
    required this.blueName,
    required this.redName,
    required this.gridCols,
    required this.gridRows,
    required this.hexSize,
    required this.mapTerrain,
    required this.templates,
    required this.initialUnits,
    required this.reinforcementWaves,
    required this.maxTurns,
    required this.initialHuayePower,
    required this.initialFortStrength,
  });

  static Future<CampaignConfig> load(String id) async {
    final c = jsonDecode(await rootBundle.loadString('assets/campaigns/$id/campaign.json'));
    final m = jsonDecode(await rootBundle.loadString('assets/campaigns/$id/map.json'));
    final u = jsonDecode(await rootBundle.loadString('assets/campaigns/$id/units.json'));

    final templates = <String, UnitType>{};
    for (final t in (u['templates'] as List)) {
      final ut = UnitType.fromJson(t);
      templates[t['id']] = ut;
    }

    final units = (u['units'] as List).map((x) => UnitSpec(
      id: x['id'],
      template: templates[x['template']]!,
      side: x['side'] == 'blue' ? Side.blue : Side.red,
      col: x['col'],
      row: x['row'],
      revealed: x['revealed'] ?? false,
      isReinforcement: x['is_reinforcement'] ?? false,
    )).toList();

    final waves = (c['reinforcements'] as List).map((x) => ReinforcementWave(
      label: x['label'],
      name: x['name'] ?? x['label'],
      turn: x['turn'],
      message: x['message'],
      arrivedFlag: x['arrived_flag'] as String? ?? '${x['label']}_arrived',
      units: (x['units'] as List).map((su) => UnitSpec(
        id: su['id'] ?? 0,
        template: templates[su['template']]!,
        side: su['side'] == 'blue' ? Side.blue : Side.red,
        col: su['col'],
        row: su['row'],
        revealed: true,
        isReinforcement: true,
      )).toList(),
    )).toList();

    return CampaignConfig(
      name: c['name'] ?? '',
      description: c['description'] ?? '',
      date: c['date'] ?? '',
      blueName: c['blue_name'] ?? '蓝方',
      redName: c['red_name'] ?? '红方',
      gridCols: c['grid_cols'] ?? 10,
      gridRows: c['grid_rows'] ?? 7,
      hexSize: (c['hex_size'] ?? 27).toDouble(),
      mapTerrain: Battlefield.createMapFromJson(m),
      templates: templates,
      initialUnits: units,
      reinforcementWaves: waves,
      maxTurns: c['max_turns'],
      initialHuayePower: c['initial_huaye_power'],
      initialFortStrength: c['initial_fort_strength'],
    );
  }
}

class UnitSpec {
  final int id;
  final UnitType template;
  final Side side;
  final int col;
  final int row;
  final bool revealed;
  final bool isReinforcement;

  const UnitSpec({
    required this.id,
    required this.template,
    required this.side,
    required this.col,
    required this.row,
    this.revealed = false,
    this.isReinforcement = false,
  });
}

class ReinforcementWave {
  final String label;
  final String name;
  final int turn;
  final String message;
  final List<UnitSpec> units;
  final String arrivedFlag;

  const ReinforcementWave({
    required this.label,
    required this.name,
    required this.turn,
    required this.message,
    required this.units,
    required this.arrivedFlag,
  });
}

class Game {
  final CampaignConfig config;
  late final List<List<TerrainType>> mapTerrain;

  Game(this.config) {
    mapTerrain = config.mapTerrain;
  }

  static int terrainDefense(Unit unit, List<List<TerrainType>> map) =>
      terrainProps[map[unit.row][unit.col]]!.defenseBonus;

  static bool inFullCover(Unit unit, List<List<TerrainType>> map) =>
      terrainProps[map[unit.row][unit.col]]!.fullCover;

  static bool inCore(Unit unit, List<List<TerrainType>> map) =>
      terrainProps[map[unit.row][unit.col]]!.isCore;

  Map<String, int> getMoveRange(Unit unit, List<Unit> allUnits) {
    final reachable = <String, int>{};
    final key = '${unit.col},${unit.row}';
    final queue = <(int, int, int)>[(unit.col, unit.row, unit.effectiveMoveRange)];
    reachable[key] = unit.effectiveMoveRange;

    while (queue.isNotEmpty) {
      final (c, r, remaining) = queue.removeAt(0);
      for (final (nc, nr) in Battlefield.getNeighbors(c, r)) {
        final nk = '$nc,$nr';
        final occ = getUnitAt(nc, nr, allUnits);
        if (occ != null && occ.id != unit.id) continue;
        final terrain = mapTerrain[nr][nc];
        if (terrain == TerrainType.coreFort && !unit.type.isAssault) continue;
        final cost = terrainProps[terrain]!.moveCost;
        final nr2 = remaining - cost;
        if (nr2 < 0) continue;
        if (!reachable.containsKey(nk) || reachable[nk]! < nr2) {
          reachable[nk] = nr2;
          if (nr2 > 0) queue.add((nc, nr, nr2));
        }
      }
    }
    reachable.remove(key);
    return reachable;
  }

  Set<String> getAttackTargets(Unit unit, List<Unit> allUnits) {
    final targets = <String>{};
    for (final enemy in allUnits) {
      if (!enemy.alive || enemy.side != Side.red || !enemy.revealed) continue;
      final dist = Battlefield.hexDistance(unit.col, unit.row, enemy.col, enemy.row);
      if (dist <= unit.type.attackRange) {
        if (inFullCover(enemy, mapTerrain) && dist > 1) continue;
        targets.add('${enemy.col},${enemy.row}');
      }
    }
    return targets;
  }

  (List<Unit>, List<Dispatch>) spawnReinforcements(
      List<Unit> units, Campaign campaign, int currentTurn) {
    final newUnits = <Unit>[];
    final logs = <Dispatch>[];

    for (final wave in config.reinforcementWaves) {
      if (currentTurn >= wave.turn && !(campaign.arrived[wave.arrivedFlag] ?? false)) {
        campaign.arrived[wave.arrivedFlag] = true;
        for (final spec in wave.units) {
          final nextId = units.fold(0, (max, u) => u.id > max ? u.id : max) + 1;
          newUnits.add(Unit(
            id: nextId,
            side: spec.side,
            type: spec.template,
            col: spec.col,
            row: spec.row,
            hp: spec.template.maxHp,
            revealed: true,
            isReinforcement: true,
          ));
        }
        logs.add(Dispatch(wave.message, 'urgent', currentTurn));
      }
    }
    return (newUnits, logs);
  }

  void checkVictory(List<Unit> units, Campaign campaign, int currentTurn) {
    final natUnits = units.where((u) => u.alive && u.side == Side.red);
    if (natUnits.isEmpty) {
      campaign.gameOver = true;
      campaign.victory = true;
      campaign.victoryDetail = '帝丘店地区国军全部肃清！';
      return;
    }
    final coreOccupied = units.any((u) => u.alive && inCore(u, mapTerrain) && u.side == Side.blue);
    if (coreOccupied && campaign.fortStrength <= 0) {
      campaign.gameOver = true;
      campaign.victory = true;
      campaign.victoryDetail = '帝丘店核心阵地已被攻占！';
      return;
    }
  }

  Unit? getUnitAt(int col, int row, List<Unit> units) {
    return units.cast<Unit?>().firstWhere(
      (u) => u!.alive && u.col == col && u.row == row,
      orElse: () => null,
    );
  }

  List<Unit> createInitialUnits() {
    int id = 0;
    final specs = config.initialUnits;
    final units = <Unit>[];
    for (final spec in specs) {
      units.add(Unit(
        id: spec.id,
        side: spec.side,
        type: spec.template,
        col: spec.col,
        row: spec.row,
        revealed: spec.revealed,
        isReinforcement: spec.isReinforcement,
      ));
      if (spec.id > id) id = spec.id;
    }
    return units;
  }
}

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

class Dispatch {
  final String msg;
  final String type;
  final int turn;
  const Dispatch(this.msg, this.type, this.turn);
}
