import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/models/campaign.dart';
import 'package:studio/models/game.dart';
import 'package:studio/models/battlefield.dart';

void main() {
  group('Game', () {
    late Game game;
    late CampaignConfig config;
    late List<Unit> initialUnits;

    setUp(() {
      config = CampaignConfig(
        name: '测试战役',
        description: '测试用',
        date: '1948年7月',
        blueName: '华野',
        redName: '国军',
        gridCols: 10,
        gridRows: 7,
        hexSize: 27,
        mapTerrain: Battlefield.createMapTerrain(),
        templates: {
          'inf': UnitLibrary.lightInfantry,
          'hvy': UnitLibrary.heavyInfantry,
          'art': UnitLibrary.artillery,
          'cav': UnitLibrary.cavalry,
          'aslt': UnitLibrary.assaultInfantry,
        },
        initialUnits: [
          UnitSpec(id: 1, template: UnitLibrary.artillery, side: Side.blue, col: 3, row: 3, revealed: true),
          UnitSpec(id: 2, template: UnitLibrary.lightInfantry, side: Side.blue, col: 0, row: 1, revealed: true),
          UnitSpec(id: 3, template: UnitLibrary.assaultInfantry, side: Side.blue, col: 1, row: 2, revealed: true),
          UnitSpec(id: 10, template: UnitLibrary.heavyInfantry, side: Side.red, col: 4, row: 3, revealed: true),
          UnitSpec(id: 11, template: UnitLibrary.lightInfantry, side: Side.red, col: 4, row: 5),
          UnitSpec(id: 12, template: UnitLibrary.heavyInfantry, side: Side.red, col: 6, row: 4),
        ],
        reinforcementWaves: [
          ReinforcementWave(label: 'qiu', name: '邱清泉', turn: 8, message: '邱兵团到达', arrivedFlag: 'qiu_arrived', units: [
            UnitSpec(id: 0, template: UnitLibrary.cavalry, side: Side.red, col: 0, row: 2, revealed: true, isReinforcement: true),
          ]),
          ReinforcementWave(label: 'hu', name: '胡琏', turn: 7, message: '胡兵团到达', arrivedFlag: 'hu_arrived', units: [
            UnitSpec(id: 0, template: UnitLibrary.lightInfantry, side: Side.red, col: 8, row: 5, revealed: true, isReinforcement: true),
          ]),
        ],
        maxTurns: 12,
        initialHuayePower: 85,
        initialFortStrength: 3,
      );
      game = Game(config);
      initialUnits = game.createInitialUnits();
    });

    test('createInitialUnits matches configured specs', () {
      expect(initialUnits.length, 6);
      expect(initialUnits.where((u) => u.side == Side.blue).length, 3);
      expect(initialUnits.where((u) => u.side == Side.red).length, 3);
    });

    test('getMoveRange excludes own position', () {
      final unit = initialUnits.first;
      final range = game.getMoveRange(unit, initialUnits);
      expect(range.containsKey('${unit.col},${unit.row}'), false);
    });

    test('getMoveRange returns reachable hexes within move range', () {
      final unit = initialUnits.first;
      final range = game.getMoveRange(unit, initialUnits);
      for (final key in range.keys) {
        final parts = key.split(',');
        final c = int.parse(parts[0]);
        final r = int.parse(parts[1]);
        final dist = Battlefield.hexDistance(unit.col, unit.row, c, r);
        expect(dist, lessThanOrEqualTo(unit.effectiveMoveRange));
      }
    });

    test('getAttackTargets returns only revealed enemy units', () {
      final player = initialUnits.firstWhere((u) => u.side == Side.blue);
      initAllRevealed(initialUnits);
      final targets = game.getAttackTargets(player, initialUnits);
      expect(targets, isNotEmpty);
      for (final key in targets) {
        final parts = key.split(',');
        final u = game.getUnitAt(int.parse(parts[0]), int.parse(parts[1]), initialUnits);
        expect(u, isNotNull);
        expect(u!.side, Side.red);
      }
    });

    test('getAttackTargets ignores unrevealed enemies', () {
      for (final u in initialUnits) { if (u.side == Side.red) u.revealed = false; }
      final player = initialUnits.firstWhere((u) => u.side == Side.blue);
      final targets = game.getAttackTargets(player, initialUnits);
      expect(targets, isEmpty);
    });

    test('getUnitAt finds unit at position', () {
      final u = initialUnits.first;
      final found = game.getUnitAt(u.col, u.row, initialUnits);
      expect(found, isNotNull);
      expect(found!.id, u.id);
    });

    test('getUnitAt returns null for empty hex', () {
      final found = game.getUnitAt(9, 0, initialUnits);
      expect(found, isNull);
    });

    test('spawnReinforcements does not spawn before wave turn', () {
      final campaign = Campaign(huayePower: 85, fortStrength: 3);
      final (newUnits, logs) = game.spawnReinforcements(initialUnits, campaign, 1);
      expect(newUnits, isEmpty);
      expect(logs, isEmpty);
    });

    test('spawnReinforcements spawns at wave turn', () {
      final campaign = Campaign(huayePower: 85, fortStrength: 3);
      final (newUnits, logs) = game.spawnReinforcements(initialUnits, campaign, 7);
      expect(newUnits, hasLength(1));
      expect(logs, hasLength(1));
      expect(logs.first.msg, '胡兵团到达');
    });

    test('spawnReinforcements does not re-spawn already arrived wave', () {
      final campaign = Campaign(huayePower: 85, fortStrength: 3);
      game.spawnReinforcements(initialUnits, campaign, 7); // hu arrives
      game.spawnReinforcements(initialUnits, campaign, 8); // qiu arrives
      final (newUnits, logs) = game.spawnReinforcements(initialUnits, campaign, 10);
      expect(newUnits, isEmpty);
    });

    test('checkVictory detects no enemies left', () {
      final campaign = Campaign();
      for (final u in initialUnits) { if (u.side == Side.red) u.alive = false; }
      game.checkVictory(initialUnits, campaign, 5);
      expect(campaign.gameOver, true);
      expect(campaign.victory, true);
      expect(campaign.victoryDetail, contains('肃清'));
    });

    test('checkVictory does not trigger with enemies alive and core not taken', () {
      final campaign = Campaign(fortStrength: 3);
      game.checkVictory(initialUnits, campaign, 5);
      expect(campaign.gameOver, false);
    });
  });
}

void initAllRevealed(List<Unit> units) {
  for (final u in units) {
    u.revealed = true;
  }
}
