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
        templates: {
          'inf': UnitLibrary.lightInfantry,
          'aslt': UnitLibrary.assaultInfantry,
          'hvy': UnitLibrary.heavyInfantry,
        },
        initialUnits: [
          UnitSpec(
            id: 1,
            template: UnitLibrary.assaultInfantry,
            side: Side.blue,
            col: 3,
            row: 3,
            revealed: true,
          ),
          UnitSpec(
            id: 10,
            template: UnitLibrary.heavyInfantry,
            side: Side.red,
            col: 4,
            row: 3,
            revealed: true,
          ),
        ],
        reinforcementWaves: [],
        maxTurns: 12,
        initialPlayerPower: 85,
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
      expect(
        '${controller.state.selectedUnit!.col},${controller.state.selectedUnit!.row}',
        key,
      );
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

    test('applyMove 移动单位且无需选中态', () {
      final u = controller.state.units.firstWhere((x) => x.id == 1);
      final range = controller.engine.getMoveRange(
        u,
        controller.state.units,
        controller.state.campaign,
      );
      final key = range.keys.first;
      final parts = key.split(',');
      final tc = int.parse(parts[0]);
      final tr = int.parse(parts[1]);

      final r = controller.applyMove(u, tc, tr);

      expect(r.ok, isTrue);
      expect('${u.col},${u.row}', key);
      expect(controller.state.selectedUnitId, isNull); // 未建立点击态
      expect(controller.state.logMessages, isNotEmpty);
    });

    test('applyMove 拒绝不可达目标', () {
      final u = controller.state.units.firstWhere((x) => x.id == 1);
      final before = (u.col, u.row);
      final r = controller.applyMove(u, 9, 6); // 远超移动力
      expect(r.ok, isFalse);
      expect((u.col, u.row), before);
    });

    test('applyAttack 无需选中态即可结算并返回战报', () {
      final a = controller.state.units.firstWhere((x) => x.id == 1);
      final d = controller.state.units.firstWhere((x) => x.id == 10);

      final r = controller.applyAttack(a, d);

      expect(r.ok, isTrue);
      expect(r.dispatches, isNotEmpty);
      expect(a.hasActed, isTrue);
      expect(controller.state.selectedUnitId, isNull);
    });

    test('applyAttack 拒绝射程外目标', () {
      final a = controller.state.units.firstWhere((x) => x.id == 1);
      final d = controller.state.units.firstWhere((x) => x.id == 10);
      d.col = 8;
      d.row = 6; // 拉到射程外
      final before = d.hp;
      final r = controller.applyAttack(a, d);
      expect(r.ok, isFalse);
      expect(d.hp, before);
    });
  });
}
