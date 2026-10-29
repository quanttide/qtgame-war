import 'package:flutter_test/flutter_test.dart';
import 'package:studio/campaigns/diqiudian_victory.dart';
import 'package:studio/models/battlefield.dart';
import 'package:studio/models/campaign.dart';
import 'package:studio/models/game.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/models/victory_policy.dart';
import '../fixtures.dart';

void main() {
  group('diqiudianVictory', () {
    late CampaignConfig config;
    late TerrainBook terrain;
    late VictoryPolicy policy;

    Unit blueAt(int col, int row) => Unit(
      id: 1,
      side: Side.blue,
      type: UnitLibrary.lightInfantry,
      col: col,
      row: row,
      hp: 3,
      revealed: true,
    );
    Unit redAt(int col, int row) => Unit(
      id: 10,
      side: Side.red,
      type: UnitLibrary.lightInfantry,
      col: col,
      row: row,
      hp: 3,
      revealed: true,
    );

    setUp(() {
      config = CampaignConfig(
        name: '帝丘店',
        description: '测试用',
        date: '1948年7月',
        blueName: '华野',
        redName: '国军',
        gridCols: 10,
        gridRows: 7,
        hexSize: 27,
        mapGrid: testMapGrid(),
        terrainCatalog: testTerrainCatalog,
        templates: {'inf': UnitLibrary.lightInfantry},
        initialUnits: [],
        reinforcementWaves: [],
        maxTurns: 12,
        initialPlayerPower: 85,
        initialFortStrength: 3,
        victoryClearedText: '敌军已全部肃清！',
        victoryCoreText: '核心阵地已被攻占！',
      );
      terrain = TerrainBook(
        grid: testMapGrid(),
        catalog: testTerrainCatalog,
        cols: 10,
        rows: 7,
      );
      policy = diqiudianVictory(config);
    });

    test('红方全灭 → 胜，文案读注入配置', () {
      final red = redAt(4, 3)..alive = false;
      final result = policy([blueAt(3, 3), red], Campaign(), 5, terrain);
      expect(result, isNotNull);
      expect(result!.victory, isTrue);
      expect(result.detail, '敌军已全部肃清！');
    });

    test('蓝方占核心且工事归零 → 胜', () {
      final result = policy(
        [blueAt(5, 4), redAt(4, 3)],
        Campaign(fortStrength: 0),
        5,
        terrain,
      );
      expect(result, isNotNull);
      expect(result!.victory, isTrue);
      expect(result.detail, '核心阵地已被攻占！');
    });

    test('蓝方占核心但工事未归零 → 未结束', () {
      final result = policy(
        [blueAt(5, 4), redAt(4, 3)],
        Campaign(fortStrength: 1),
        5,
        terrain,
      );
      expect(result, isNull);
    });

    test('蓝方全灭 → 败，败因文案随迁自控制器', () {
      final blue = blueAt(3, 3)..alive = false;
      final result = policy([blue, redAt(4, 3)], Campaign(), 5, terrain);
      expect(result, isNotNull);
      expect(result!.victory, isFalse);
      expect(result.detail, '华野部队已无力再战，帝丘店未能攻克。');
      expect(result.dispatches, isEmpty);
    });

    test('超时（turn > 12） → 败 + 超时战报透传评估回合', () {
      final result = policy(
        [blueAt(3, 3), redAt(4, 3)],
        Campaign(),
        13,
        terrain,
      );
      expect(result, isNotNull);
      expect(result!.victory, isFalse);
      expect(result.detail, '时间耗尽，援军逼近，华野被迫撤出战斗。');
      expect(result.dispatches.single.msg, contains('时间耗尽'));
      expect(result.dispatches.single.type, 'urgent');
      expect(result.dispatches.single.turn, 13);
    });

    test('回合未尽且双方犹存 → 未结束', () {
      final result = policy(
        [blueAt(3, 3), redAt(4, 3)],
        Campaign(fortStrength: 3),
        12,
        terrain,
      );
      expect(result, isNull);
    });
  });
}
