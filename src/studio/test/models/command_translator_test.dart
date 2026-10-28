import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/battlefield.dart';
import 'package:studio/models/campaign.dart';
import 'package:studio/models/command.dart';
import 'package:studio/models/game.dart';
import 'package:studio/models/task.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/controllers/command_translator.dart';
import '../fixtures.dart';

void main() {
  // 内存构造最小战局：7x10 全平原，(5,3) 为核心要塞
  Game makeGame({(int, int)? fort}) {
    final grid = List.generate(7, (_) => List.filled(10, 'plain'));
    if (fort != null) grid[fort.$2][fort.$1] = 'core_fort';
    final config = CampaignConfig(
      name: 'test',
      description: '',
      date: '',
      blueName: '华野',
      redName: '国军',
      gridCols: 10,
      gridRows: 7,
      hexSize: 27,
      mapGrid: grid,
      terrainCatalog: testTerrainCatalog,
      templates: {},
      initialUnits: [],
      reinforcementWaves: [],
      maxTurns: 5,
      initialPlayerPower: 85,
      initialFortStrength: 3,
    );
    return Game(config);
  }

  Unit mk(
    int id,
    Side side, {
    required int col,
    required int row,
    int range = 1,
    int move = 3,
    bool isAssault = false,
    bool revealed = true,
  }) {
    return Unit(
      id: id,
      side: side,
      col: col,
      row: row,
      revealed: revealed,
      type: UnitType(
        name: 'u$id',
        maxHp: 3,
        baseAttack: 2,
        baseDefense: 0,
        baseMoveRange: move,
        attackRange: range,
        isAssault: isAssault,
      ),
    );
  }

  group('Command 模型', () {
    test('默认 pending，字段可读', () {
      final c = Command(
        unitId: 1,
        task: TaskType.assault,
        issuedTurn: 2,
        deadlineTurn: 2,
      );
      expect(c.status, CommandStatus.pending);
      expect(c.moveTo, isNull);
      expect(c.attack, isNull);
      expect(c.issuedTurn, 2);
      expect(c.deadlineTurn, 2);
    });
  });

  group('translateOrders 翻译规则', () {
    test('攻城档位朝要塞推进并攻击要塞守军', () {
      final engine = makeGame(fort: (5, 3));
      final garrison = mk(9, Side.red, col: 5, row: 3, revealed: true);
      final assault = mk(1, Side.blue, col: 5, row: 5, isAssault: true);
      final units = [assault, garrison];

      final cmds = translateOrders(
        assignments: {1: TaskType.assault},
        units: units,
        engine: engine,
        campaign: Campaign(),
        fortPos: (5, 3),
        reliefPos: (8, 1),
        currentTurn: 2,
      );

      expect(cmds, hasLength(1));
      final c = cmds.first;
      expect(c.unitId, 1);
      expect(c.task, TaskType.assault);
      expect(c.moveTo, isNotNull);
      // 落位应比起点更靠近要塞
      final start = Battlefield.hexDistance(5, 5, 5, 3);
      final end = Battlefield.hexDistance(c.moveTo!.$1, c.moveTo!.$2, 5, 3);
      expect(end, lessThan(start));
      // 要塞守军被作为攻击目标
      expect(c.attack, (5, 3));
      expect(c.issuedTurn, 2);
      expect(c.deadlineTurn, 2);
    });

    test('佯攻同属攻城线，朝要塞而非援军', () {
      final engine = makeGame(fort: (5, 3));
      final feinter = mk(1, Side.blue, col: 5, row: 5);
      final cmds = translateOrders(
        assignments: {1: TaskType.feint},
        units: [feinter],
        engine: engine,
        campaign: Campaign(),
        fortPos: (5, 3),
        reliefPos: (8, 1),
        currentTurn: 1,
      );
      final c = cmds.first;
      final toFort = Battlefield.hexDistance(c.moveTo!.$1, c.moveTo!.$2, 5, 3);
      final toRelief = Battlefield.hexDistance(
        c.moveTo!.$1,
        c.moveTo!.$2,
        8,
        1,
      );
      expect(toFort, lessThan(toRelief));
    });

    test('阻援档位朝援军推进，无近敌则不攻击', () {
      final engine = makeGame(fort: (5, 3));
      final blocker = mk(2, Side.blue, col: 2, row: 5);
      final cmds = translateOrders(
        assignments: {2: TaskType.block},
        units: [blocker],
        engine: engine,
        campaign: Campaign(),
        fortPos: (5, 3),
        reliefPos: (8, 1),
        currentTurn: 1,
      );
      final c = cmds.first;
      expect(c.task, TaskType.block);
      final start = Battlefield.hexDistance(2, 5, 8, 1);
      final end = Battlefield.hexDistance(c.moveTo!.$1, c.moveTo!.$2, 8, 1);
      expect(end, lessThan(start));
      expect(c.attack, isNull);
    });

    test('待命档位 hold：不移动不攻击', () {
      final engine = makeGame(fort: (5, 3));
      final reserve = mk(3, Side.blue, col: 1, row: 1);
      final cmds = translateOrders(
        assignments: {3: TaskType.standby},
        units: [reserve],
        engine: engine,
        campaign: Campaign(),
        fortPos: (5, 3),
        reliefPos: (8, 1),
        currentTurn: 1,
      );
      final c = cmds.first;
      expect(c.task, TaskType.standby);
      expect(c.moveTo, isNull);
      expect(c.attack, isNull);
    });

    test('已邻接目标则原地待攻，不移动', () {
      final engine = makeGame(fort: (5, 3));
      final garrison = mk(9, Side.red, col: 5, row: 3, revealed: true);
      final adjacent = mk(1, Side.blue, col: 5, row: 4, isAssault: true);
      final cmds = translateOrders(
        assignments: {1: TaskType.siege},
        units: [adjacent, garrison],
        engine: engine,
        campaign: Campaign(),
        fortPos: (5, 3),
        reliefPos: (8, 1),
        currentTurn: 1,
      );
      final c = cmds.first;
      expect(c.moveTo, isNull); // 已邻接，原地
      expect(c.attack, (5, 3)); // 但守军在射程内，仍攻击
    });

    test('未暴露敌军不作为攻击目标', () {
      final engine = makeGame(fort: (5, 3));
      final hidden = mk(9, Side.red, col: 5, row: 3, revealed: false);
      final assault = mk(1, Side.blue, col: 5, row: 4, isAssault: true);
      final cmds = translateOrders(
        assignments: {1: TaskType.assault},
        units: [assault, hidden],
        engine: engine,
        campaign: Campaign(),
        fortPos: (5, 3),
        reliefPos: (8, 1),
        currentTurn: 1,
      );
      expect(cmds.first.attack, isNull);
    });

    test('死亡纵队不产命令', () {
      final engine = makeGame(fort: (5, 3));
      final dead = mk(1, Side.blue, col: 5, row: 5)..takeDamage(3);
      final cmds = translateOrders(
        assignments: {1: TaskType.assault},
        units: [dead],
        engine: engine,
        campaign: Campaign(),
        fortPos: (5, 3),
        reliefPos: (8, 1),
        currentTurn: 1,
      );
      expect(cmds, isEmpty);
    });

    test('命令按 unitId 升序产出', () {
      final engine = makeGame(fort: (5, 3));
      final u3 = mk(3, Side.blue, col: 5, row: 5);
      final u1 = mk(1, Side.blue, col: 2, row: 2);
      final cmds = translateOrders(
        assignments: {3: TaskType.assault, 1: TaskType.block},
        units: [u3, u1],
        engine: engine,
        campaign: Campaign(),
        fortPos: (5, 3),
        reliefPos: (8, 1),
        currentTurn: 1,
      );
      expect(cmds.map((c) => c.unitId).toList(), [1, 3]);
    });
  });
}
