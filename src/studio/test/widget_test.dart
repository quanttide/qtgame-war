import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/models/campaign.dart';
import 'package:studio/models/combat.dart';
import 'package:studio/models/game.dart';
import 'package:studio/models/battlefield.dart';
import 'package:studio/controllers/game_controller.dart';

void main() {
  group('Unit', () {
    test('moveTo updates position', () {
      final u = Unit(id: 1, side: Side.blue, type: UnitLibrary.lightInfantry, col: 0, row: 0);
      u.moveTo(5, 3);
      expect(u.col, 5);
      expect(u.row, 3);
    });

    test('takeDamage reduces hp and kills when exhausted', () {
      final u = Unit(id: 1, side: Side.blue, type: UnitLibrary.lightInfantry, col: 0, row: 0, hp: 3);
      u.takeDamage(1);
      expect(u.hp, 2);
      expect(u.alive, true);
      u.takeDamage(2);
      expect(u.hp, 0);
      expect(u.alive, false);
    });

    test('markActed and reveal toggle flags', () {
      final u = Unit(id: 1, side: Side.blue, type: UnitLibrary.lightInfantry, col: 0, row: 0);
      expect(u.hasActed, false);
      u.markActed();
      expect(u.hasActed, true);
      expect(u.revealed, false);
      u.reveal();
      expect(u.revealed, true);
    });
  });

  group('Campaign', () {
    test('powerDesc returns correct descriptions at thresholds', () {
      expect(Campaign(huayePower: 85).powerDesc, '充沛');
      expect(Campaign(huayePower: 50).powerDesc, '尚可');
      expect(Campaign(huayePower: 30).powerDesc, '吃紧');
      expect(Campaign(huayePower: 10).powerDesc, '濒临极限');
    });

    test('hitMod and moveMod at different power levels', () {
      expect(Campaign(huayePower: 85).hitMod, 5);
      expect(Campaign(huayePower: 50).hitMod, 0);
      expect(Campaign(huayePower: 30).hitMod, -5);
      expect(Campaign(huayePower: 10).hitMod, -12);
      expect(Campaign(huayePower: 85).moveMod, 0);
      expect(Campaign(huayePower: 30).moveMod, 1);
      expect(Campaign(huayePower: 10).moveMod, 2);
    });
  });

  group('Combat', () {
    test('resolveCombat returns valid structure', () {
      final attacker = Unit(id: 1, side: Side.blue, type: UnitLibrary.lightInfantry, col: 0, row: 1);
      final defender = Unit(id: 2, side: Side.red, type: UnitLibrary.lightInfantry, col: 0, row: 2, hp: 3);
      final campaign = Campaign();
      final terrain = Battlefield.createMapTerrain();

      final result = resolveCombat(attacker, defender, campaign, terrain);
      expect(result.hit, isA<bool>());
      expect(result.damage, greaterThanOrEqualTo(0));
      expect(result.killed, isA<bool>());
      expect(result.text, isA<String>());
    });
  });

  group('Game', () {
    late Game game;
    late CampaignConfig config;
    late List<Unit> initialUnits;

    setUp(() {
      config = CampaignConfig(
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
          ReinforcementWave(label: 'qiu', turn: 8, message: '邱兵团到达', units: [
            UnitSpec(id: 0, template: UnitLibrary.cavalry, side: Side.red, col: 0, row: 2, revealed: true, isReinforcement: true),
          ]),
          ReinforcementWave(label: 'hu', turn: 7, message: '胡兵团到达', units: [
            UnitSpec(id: 0, template: UnitLibrary.lightInfantry, side: Side.red, col: 8, row: 5, revealed: true, isReinforcement: true),
          ]),
        ],
        maxTurns: 12,
        initialHuayePower: 85,
        initialFortStrength: 3,
        qiuReinforceTurn: 8,
        huReinforceTurn: 7,
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
      final campaign = Campaign(huayePower: 85, fortStrength: 3, qiuReinforceTurn: 8, huReinforceTurn: 7);
      final (newUnits, logs) = game.spawnReinforcements(initialUnits, campaign, 1);
      expect(newUnits, isEmpty);
      expect(logs, isEmpty);
    });

    test('spawnReinforcements spawns at wave turn', () {
      final campaign = Campaign(huayePower: 85, fortStrength: 3, qiuReinforceTurn: 8, huReinforceTurn: 7);
      final (newUnits, logs) = game.spawnReinforcements(initialUnits, campaign, 7);
      expect(newUnits, hasLength(1));
      expect(logs, hasLength(1));
      expect(logs.first.msg, '胡兵团到达');
    });

    test('spawnReinforcements does not re-spawn already arrived wave', () {
      final campaign = Campaign(huayePower: 85, fortStrength: 3, qiuReinforceTurn: 8, huReinforceTurn: 7);
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

  group('GameController', () {
    late GameController controller;
    late Game game;

    setUp(() {
      final terrain = Battlefield.createMapTerrain();
      final config = CampaignConfig(
        mapTerrain: terrain,
        templates: {'inf': UnitLibrary.lightInfantry, 'aslt': UnitLibrary.assaultInfantry, 'hvy': UnitLibrary.heavyInfantry},
        initialUnits: [
          UnitSpec(id: 1, template: UnitLibrary.assaultInfantry, side: Side.blue, col: 3, row: 3, revealed: true),
          UnitSpec(id: 10, template: UnitLibrary.heavyInfantry, side: Side.red, col: 4, row: 3, revealed: true),
        ],
        reinforcementWaves: [],
        maxTurns: 12,
        initialHuayePower: 85,
        initialFortStrength: 3,
        qiuReinforceTurn: 99,
        huReinforceTurn: 99,
      );
      game = Game(config);
      controller = GameController(game);
    });

    test('initial state is player phase', () {
      expect(controller.state.phase, GamePhase.player);
      expect(controller.state.selectedUnitId, isNull);
    });

    test('selectUnit sets selection and candidates', () {
      controller.selectUnit(1);
      expect(controller.state.selectedUnitId, 1);
      expect(controller.state.moveCandidates, isNotEmpty);
    });

    test('selectUnit ignores enemy unit', () {
      controller.selectUnit(10);
      expect(controller.state.selectedUnitId, isNull);
    });

    test('selectUnit toggles off on re-select', () {
      controller.selectUnit(1);
      expect(controller.state.selectedUnitId, 1);
      controller.selectUnit(1);
      expect(controller.state.selectedUnitId, isNull);
    });

    test('clickHex on empty move candidate moves unit', () {
      controller.selectUnit(1);
      final key = controller.state.moveCandidates.first;
      final parts = key.split(',');
      controller.clickHex(int.parse(parts[0]), int.parse(parts[1]));
      expect(controller.state.selectedUnit, isNotNull);
      expect('${controller.state.selectedUnit!.col},${controller.state.selectedUnit!.row}', key);
      expect(controller.state.moveCandidates, isEmpty);
    });

    test('clickHex on enemy in attack range executes attack', () {
      controller.selectUnit(1);
      controller.clickHex(4, 3);
      // After attack, selection is cleared
      expect(controller.state.selectedUnitId, isNull);
    });

    test('endTurn transitions to ai phase', () async {
      controller.endTurn();
      expect(controller.state.phase, GamePhase.ai);
    });

    test('reset restores initial state', () {
      controller.selectUnit(1);
      controller.reset();
      expect(controller.state.phase, GamePhase.player);
      expect(controller.state.selectedUnitId, isNull);
      expect(controller.state.currentTurn, 1);
    });
  });
}

void initAllRevealed(List<Unit> units) {
  for (final u in units) {
    u.revealed = true;
  }
}
