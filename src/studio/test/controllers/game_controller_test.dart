import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/models/game.dart';
import 'package:studio/models/battlefield.dart';
import 'package:studio/controllers/game_controller.dart';

void main() {
  group('GameController', () {
    late GameController controller;
    late Game game;

    setUp(() {
      final terrain = Battlefield.createMapTerrain();
      final config = CampaignConfig(
        name: '测试战役',
        description: '测试用',
        date: '1948年7月',
        blueName: '华野',
        redName: '国军',
        gridCols: 10,
        gridRows: 7,
        hexSize: 27,
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
