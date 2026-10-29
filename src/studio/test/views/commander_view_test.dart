import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/campaigns/diqiudian_victory.dart';
import 'package:studio/models/game.dart';
import '../fixtures.dart';
import 'package:studio/controllers/game_controller.dart';
import 'package:studio/views/commander_view.dart';

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
  return GameController(
    Game(config, victoryPolicy: diqiudianVictory(config)),
    rng: const _FixedRandom(),
    aiDelay: Duration.zero,
  );
}

Widget _buildApp(GameController controller) {
  return MaterialApp(
    home: Scaffold(body: CommanderView(controller: controller)),
  );
}

void main() {
  group('CommanderView', () {
    testWidgets('tap 强攻要塞 → 未行动纵队推进并攻击', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      final blue = controller.state.units.firstWhere((u) => u.id == 1);
      final from = (blue.col, blue.row);

      await tester.tap(find.text('⚔ 强攻要塞'));
      await tester.pump();

      expect((blue.col, blue.row) != from, isTrue); // 已向要塞推进
      expect(blue.hasActed, isTrue); // 已行动（移动+攻击或移动）
    });

    testWidgets('tap 原地休整 → 不移动不行动', (tester) async {
      final controller = _createController();
      await tester.pumpWidget(_buildApp(controller));

      final blue = controller.state.units.firstWhere((u) => u.id == 1);
      final from = (blue.col, blue.row);

      await tester.tap(find.textContaining('原地休整'));
      await tester.pump();

      expect((blue.col, blue.row), from);
      expect(blue.hasActed, isFalse);
    });

    testWidgets('敌军回合禁用决策卡', (tester) async {
      final controller = _createController();
      controller.state.phase = GamePhase.ai;
      await tester.pumpWidget(_buildApp(controller));

      final blue = controller.state.units.firstWhere((u) => u.id == 1);
      final from = (blue.col, blue.row);

      await tester.tap(find.text('⚔ 强攻要塞'), warnIfMissed: false);
      await tester.pump();

      expect((blue.col, blue.row), from);
      expect(find.text('敌军行动中…'), findsOneWidget);
    });
  });
}

/// 固定随机源：恒返回 0（攻击必 miss 也无妨，本组测试只断行动与位移）。
class _FixedRandom implements Random {
  const _FixedRandom();

  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
