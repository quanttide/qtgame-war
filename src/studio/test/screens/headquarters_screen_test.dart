import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/campaigns/diqiudian_victory.dart';
import 'package:studio/models/game.dart';
import '../fixtures.dart';
import 'package:studio/controllers/game_controller.dart';
import 'package:studio/screens/headquarters_screen.dart';
import 'package:studio/views/battlefield_view.dart';
import 'package:studio/views/commander_view.dart';

Widget _buildApp(GameController controller) {
  return MaterialApp(home: HeadquartersScreen(controller: controller));
}

GameController _createController() {
  final config = CampaignConfig(
    name: '测试战役',
    description: '测试用',
    date: '1948年7月',
    blueName: '华野',
    redName: '国军',
    gridCols: 10,
    gridRows: 7,
    hexSize: 27,
    mapGrid: testMapGrid(),
    terrainCatalog: testTerrainCatalog,
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
  return GameController(Game(config, victoryPolicy: diqiudianVictory(config)));
}

void main() {
  group('HeadquartersScreen', () {
    testWidgets('renders main layout: battlefield and commander view', (
      tester,
    ) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      expect(find.byType(BattlefieldView), findsOneWidget);
      expect(find.byType(CommanderView), findsOneWidget);
      expect(find.text('⚔ 强攻要塞'), findsOneWidget);
      expect(find.text('战 况'), findsNothing);
      expect(find.text('情 报 看 板'), findsNothing);
      expect(find.text('通 信 科'), findsNothing);
    });

    testWidgets('renders top bar with phase indicator and turn info', (
      tester,
    ) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      expect(find.text('决 策 中'), findsOneWidget);
      expect(find.text('回合 1 / 12'), findsOneWidget);
    });

    testWidgets('renders end-turn button as the primary bottom action', (
      tester,
    ) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      expect(find.textContaining('结束回合'), findsOneWidget);
    });
  });
}
