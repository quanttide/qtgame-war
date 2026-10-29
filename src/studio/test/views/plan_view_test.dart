import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/campaigns/diqiudian_victory.dart';
import 'package:studio/models/game.dart';
import '../fixtures.dart';
import 'package:studio/controllers/game_controller.dart';
import 'package:studio/views/plan_view.dart';

Widget _buildApp(GameController controller) {
  return MaterialApp(
    home: Scaffold(
      body: PlanView(state: controller.state, controller: controller),
    ),
  );
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
  group('PlanView', () {
    testWidgets('renders title', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      expect(find.text('战 况'), findsOneWidget);
    });

    testWidgets('renders campaign info', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      expect(find.textContaining('目标：'), findsOneWidget);
      expect(find.text('攻占帝丘店'), findsOneWidget);
    });

    testWidgets('renders unit list', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      expect(find.textContaining('突击步兵'), findsOneWidget);
    });

    testWidgets('renders reset control', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      expect(find.textContaining('重置'), findsOneWidget);
      expect(find.textContaining('结束回合'), findsNothing);
    });

    testWidgets('renders terrain legend', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      expect(find.text('平原'), findsOneWidget);
      expect(find.text('帝丘店核心'), findsOneWidget);
    });
  });
}
