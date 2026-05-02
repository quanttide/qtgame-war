import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/models/game.dart';
import 'package:studio/models/battlefield.dart';
import 'package:studio/controllers/game_controller.dart';
import 'package:studio/screens/headquarters_screen.dart';
import 'package:studio/views/battlefield_view.dart';

Widget _buildApp(GameController controller) {
  return MaterialApp(
    home: HeadquartersScreen(controller: controller),
  );
}

GameController _createController() {
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
      UnitSpec(id: 1, template: UnitLibrary.assaultInfantry, side: Side.blue, col: 3, row: 3, revealed: true),
      UnitSpec(id: 10, template: UnitLibrary.heavyInfantry, side: Side.red, col: 4, row: 3, revealed: true),
    ],
    reinforcementWaves: [],
    maxTurns: 12,
    initialHuayePower: 85,
    initialFortStrength: 3,
  );
  return GameController(Game(config));
}

void main() {
  group('HeadquartersScreen', () {
    testWidgets('renders three-column layout', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      expect(find.text('情 报 看 板'), findsOneWidget);
      expect(find.byType(BattlefieldView), findsOneWidget);
      expect(find.text('作 战 计 划'), findsOneWidget);
    });

    testWidgets('renders top bar with phase indicator and turn info', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      expect(find.text('决 策 中'), findsOneWidget);
      expect(find.text('回合 1 / 12'), findsOneWidget);
    });

    testWidgets('renders bottom bar with comm units', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      expect(find.text('通 信 科'), findsOneWidget);
      expect(find.text('军委台'), findsOneWidget);
    });
  });
}
