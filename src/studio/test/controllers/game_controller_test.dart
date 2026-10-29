import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio/campaigns/diqiudian_victory.dart';
import 'package:studio/models/victory_policy.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/models/game.dart';
import '../fixtures.dart';
import 'package:studio/controllers/game_controller.dart';

void main() {
  group('GameController', () {
    late GameController controller;
    late Game game;
    late CampaignConfig config;

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
      game = Game(config, victoryPolicy: diqiudianVictory(config));
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

    test('种子冒烟：敌军回合跑完蓝方单位 hp 下降', () async {
      final c = GameController(
        game,
        rng: Random(1),
        aiDelay: Duration.zero, // 修订一：假时钟，不真实等待
      );
      final blue = c.state.units.firstWhere((x) => x.id == 1);
      final before = blue.hp;

      c.endTurn();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero); // 让出拍子，确保 _aiStep 链路完成

      expect(blue.hp, lessThan(before)); // 只断状态落盘，不断文本不断数值
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

    test('注入策略判败 → 回合结束转 gameOver', () async {
      final c = GameController(
        Game(
          config,
          victoryPolicy: (u, ca, t, terr) => VictoryResult(false, '测试败因'),
        ),
        rng: Random(1),
        aiDelay: Duration.zero,
      );
      c.endTurn();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      expect(c.state.phase, GamePhase.gameOver);
      expect(c.state.campaign.victory, isFalse);
      expect(c.state.campaign.victoryDetail, '测试败因');
    });

    test('帝丘店策略：第 13 回合超时，详情与战报皆落盘', () async {
      final c = GameController(
        Game(config, victoryPolicy: diqiudianVictory(config)),
        rng: Random(1),
        aiDelay: Duration.zero,
      );
      c.state.currentTurn = 12;
      c.endTurn();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      expect(c.state.campaign.gameOver, isTrue);
      expect(c.state.campaign.victory, isFalse);
      expect(c.state.campaign.victoryDetail, '时间耗尽，援军逼近，华野被迫撤出战斗。');
      expect(
        c.state.logMessages.map((d) => d.msg),
        contains('\u{1F480}时间耗尽，未能攻克帝丘店。'),
      );
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
