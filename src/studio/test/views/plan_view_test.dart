import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/models/game.dart';
import 'package:studio/models/battlefield.dart';
import 'package:studio/controllers/game_controller.dart';
import 'package:studio/views/plan_view.dart';

Widget _buildApp(String selectedPlanId, ValueChanged<String> onSelect, GameController controller) {
  return MaterialApp(
    home: Scaffold(
      body: PlanView(
        selectedPlanId: selectedPlanId,
        onSelectPlan: onSelect,
        state: controller.state,
        controller: controller,
      ),
    ),
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
  group('PlanView', () {
    testWidgets('renders title', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp('A', (_) {}, controller));

      expect(find.text('作 战 计 划'), findsOneWidget);
    });

    testWidgets('renders plan cards with risk badges', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp('A', (_) {}, controller));

      expect(find.text('甲案：集中打区寿年'), findsOneWidget);
      expect(find.text('乙案：先打邱清泉'), findsOneWidget);
      expect(find.text('风险中'), findsOneWidget);
      expect(find.text('风险高'), findsOneWidget);
    });

    testWidgets('tapping plan card triggers callback', (tester) async {
      final controller = _createController();
      final selected = <String>[];
      await tester.pumpWidget(_buildApp('A', (id) => selected.add(id), controller));

      await tester.tap(find.text('乙案：先打邱清泉'));
      expect(selected, ['B']);
    });

    testWidgets('renders campaign info', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp('A', (_) {}, controller));

      expect(find.textContaining('目标：'), findsOneWidget);
      expect(find.text('攻占帝丘店'), findsOneWidget);
    });

    testWidgets('renders unit list', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp('A', (_) {}, controller));

      expect(find.textContaining('突击步兵'), findsOneWidget);
    });

    testWidgets('renders game controls', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp('A', (_) {}, controller));

      expect(find.textContaining('结束回合'), findsOneWidget);
      expect(find.textContaining('重置'), findsOneWidget);
    });

    testWidgets('renders terrain legend', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp('A', (_) {}, controller));

      expect(find.text('平原'), findsOneWidget);
      expect(find.text('核心'), findsOneWidget);
    });
  });
}
