import 'dart:convert';
import 'package:flutter/services.dart';
import 'unit.dart';
import 'campaign.dart';
import 'battlefield.dart';
import 'victory_policy.dart';

class CampaignConfig {
  final String name;
  final String description;
  final String date;
  final String blueName;
  final String redName;
  final int gridCols;
  final int gridRows;
  final double hexSize;

  /// 地形网格：grid[row][col] = 地形 id（字符串）。
  final List<List<String>> mapGrid;

  /// 地形目录：id → 属性（剧本注入，含地名/消耗/颜色/掩体等）。
  final Map<String, TerrainProps> terrainCatalog;

  final Map<String, UnitType> templates;
  final List<UnitSpec> initialUnits;
  final List<ReinforcementWave> reinforcementWaves;
  final int maxTurns;
  final int initialPlayerPower;
  final int initialFortStrength;

  /// 胜负文案（剧本注入，核心不写死地名）。
  final String victoryClearedText;
  final String victoryCoreText;

  CampaignConfig({
    required this.name,
    required this.description,
    required this.date,
    required this.blueName,
    required this.redName,
    required this.gridCols,
    required this.gridRows,
    required this.hexSize,
    required this.mapGrid,
    required this.terrainCatalog,
    required this.templates,
    required this.initialUnits,
    required this.reinforcementWaves,
    required this.maxTurns,
    required this.initialPlayerPower,
    required this.initialFortStrength,
    this.victoryClearedText = '敌军已全部肃清！',
    this.victoryCoreText = '核心阵地已被攻占！',
  });

  static Future<CampaignConfig> load(String id) async {
    final c = jsonDecode(
      await rootBundle.loadString('assets/campaigns/$id/campaign.json'),
    );
    final m = jsonDecode(
      await rootBundle.loadString('assets/campaigns/$id/map.json'),
    );
    final u = jsonDecode(
      await rootBundle.loadString('assets/campaigns/$id/units.json'),
    );

    final gridCols = c['grid_cols'] ?? 10;
    final gridRows = c['grid_rows'] ?? 7;

    final templates = <String, UnitType>{};
    for (final t in (u['templates'] as List)) {
      final ut = UnitType.fromJson(t);
      templates[t['id']] = ut;
    }

    final units = (u['units'] as List)
        .map(
          (x) => UnitSpec(
            id: x['id'],
            template: templates[x['template']]!,
            side: x['side'] == 'blue' ? Side.blue : Side.red,
            col: x['col'],
            row: x['row'],
            revealed: x['revealed'] ?? false,
            isReinforcement: x['is_reinforcement'] ?? false,
          ),
        )
        .toList();

    final waves = (c['reinforcements'] as List)
        .map(
          (x) => ReinforcementWave(
            label: x['label'],
            name: x['name'] ?? x['label'],
            turn: x['turn'],
            message: x['message'],
            arrivedFlag:
                x['arrived_flag'] as String? ?? '${x['label']}_arrived',
            units: (x['units'] as List)
                .map(
                  (su) => UnitSpec(
                    id: su['id'] ?? 0,
                    template: templates[su['template']]!,
                    side: su['side'] == 'blue' ? Side.blue : Side.red,
                    col: su['col'],
                    row: su['row'],
                    revealed: true,
                    isReinforcement: true,
                  ),
                )
                .toList(),
          ),
        )
        .toList();

    return CampaignConfig(
      name: c['name'] ?? '',
      description: c['description'] ?? '',
      date: c['date'] ?? '',
      blueName: c['blue_name'] ?? '蓝方',
      redName: c['red_name'] ?? '红方',
      gridCols: gridCols,
      gridRows: gridRows,
      hexSize: (c['hex_size'] ?? 27).toDouble(),
      mapGrid: Battlefield.createMapGrid(m, gridCols, gridRows),
      terrainCatalog: _parseCatalog(m),
      templates: templates,
      initialUnits: units,
      reinforcementWaves: waves,
      maxTurns: c['max_turns'],
      initialPlayerPower: c['initial_huaye_power'],
      initialFortStrength: c['initial_fort_strength'],
      victoryClearedText: c['victory_cleared_text'] ?? '敌军已全部肃清！',
      victoryCoreText: c['victory_core_text'] ?? '核心阵地已被攻占！',
    );
  }

  /// 从 map.json 的 `catalog` 段解析地形目录。
  static Map<String, TerrainProps> _parseCatalog(Map<String, dynamic> json) {
    final catalogJson = json['catalog'] as Map<String, dynamic>?;
    if (catalogJson == null) return {};
    final catalog = <String, TerrainProps>{};
    for (final e in catalogJson.entries) {
      final v = e.value as Map<String, dynamic>;
      catalog[e.key] = TerrainProps(
        name: v['name'] as String,
        moveCost: v['move_cost'] as int,
        defenseBonus: v['defense'] as int,
        color: _hex(v['color'] as String),
        fillColor: _hex(v['fill_color'] as String),
        icon: v['icon'] as String? ?? '',
        fullCover: v['full_cover'] as bool? ?? false,
        isCore: v['is_core'] as bool? ?? false,
        assaultOnly: v['assault_only'] as bool? ?? false,
      );
    }
    return catalog;
  }

  static int _hex(String s) =>
      int.parse(s.replaceFirst('0x', '').replaceFirst('#', ''), radix: 16);
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

  /// 剧本注入的胜负策略。条件与文案归策略，核心只调用与落盘。
  final VictoryPolicy victoryPolicy;

  /// 注入的地形容器（网格 + 目录 + 尺寸），核心地形逻辑全走这里。
  late final TerrainBook terrain;

  Game(this.config, {required this.victoryPolicy})
    : terrain = TerrainBook(
        grid: config.mapGrid,
        catalog: config.terrainCatalog,
        cols: config.gridCols,
        rows: config.gridRows,
      );

  Map<String, int> getMoveRange(
    Unit unit,
    List<Unit> allUnits,
    Campaign campaign,
  ) {
    final moveMod = campaign.moveMod;
    final reachable = <String, int>{};
    final key = '${unit.col},${unit.row}';
    final queue = <(int, int, int)>[
      (unit.col, unit.row, unit.effectiveMoveRange(moveMod)),
    ];
    reachable[key] = unit.effectiveMoveRange(moveMod);

    while (queue.isNotEmpty) {
      final (c, r, remaining) = queue.removeAt(0);
      for (final (nc, nr) in Battlefield.getNeighbors(
        c,
        r,
        config.gridCols,
        config.gridRows,
      )) {
        final nk = '$nc,$nr';
        final occ = getUnitAt(nc, nr, allUnits);
        if (occ != null && occ.id != unit.id) continue;
        final props = terrain.propsAt(nc, nr);
        if (props.assaultOnly && !unit.type.isAssault) continue;
        final cost = props.moveCost;
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
      final dist = Battlefield.hexDistance(
        unit.col,
        unit.row,
        enemy.col,
        enemy.row,
      );
      if (dist <= unit.type.attackRange) {
        if (terrain.propsAt(enemy.col, enemy.row).fullCover && dist > 1) {
          continue;
        }
        targets.add('${enemy.col},${enemy.row}');
      }
    }
    return targets;
  }

  (List<Unit>, List<Dispatch>) spawnReinforcements(
    List<Unit> units,
    Campaign campaign,
    int currentTurn,
  ) {
    final newUnits = <Unit>[];
    final logs = <Dispatch>[];

    for (final wave in config.reinforcementWaves) {
      if (currentTurn >= wave.turn &&
          !(campaign.arrived[wave.arrivedFlag] ?? false)) {
        campaign.arrived[wave.arrivedFlag] = true;
        for (final spec in wave.units) {
          final nextId = units.fold(0, (max, u) => u.id > max ? u.id : max) + 1;
          newUnits.add(
            Unit(
              id: nextId,
              side: spec.side,
              type: spec.template,
              col: spec.col,
              row: spec.row,
              hp: spec.template.maxHp,
              revealed: true,
              isReinforcement: true,
            ),
          );
        }
        logs.add(Dispatch(wave.message, 'urgent', currentTurn));
      }
    }
    return (newUnits, logs);
  }

  /// 交给注入的胜负策略评估（已结束则不再评估）。
  ///
  /// 结果非 null 时落盘战役状态，返回策略产出的战报；条件与文案归策略。
  List<Dispatch> checkVictory(
    List<Unit> units,
    Campaign campaign,
    int currentTurn,
  ) {
    if (campaign.gameOver) return const [];
    final result = victoryPolicy(units, campaign, currentTurn, terrain);
    if (result == null) return const [];
    campaign.gameOver = true;
    campaign.victory = result.victory;
    campaign.victoryDetail = result.detail;
    return result.dispatches;
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
      units.add(
        Unit(
          id: spec.id,
          side: spec.side,
          type: spec.template,
          col: spec.col,
          row: spec.row,
          revealed: spec.revealed,
          isReinforcement: spec.isReinforcement,
        ),
      );
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
  List<Unit> get readyPlayerUnits => units
      .where((u) => u.alive && u.side == Side.blue && !u.hasActed)
      .toList();
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
