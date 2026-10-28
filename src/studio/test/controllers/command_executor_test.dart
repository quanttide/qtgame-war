import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/battlefield.dart';
import 'package:studio/models/command.dart';
import 'package:studio/models/game.dart';
import 'package:studio/models/task.dart';
import 'package:studio/models/unit.dart';
import '../fixtures.dart';
import 'package:studio/controllers/command_executor.dart';
import 'package:studio/controllers/game_controller.dart';

void main() {
  group('CommandExecutor', () {
    late GameController controller;
    late Game game;
    late CommandExecutor executor;

    setUp(() {
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
      game = Game(config);
      controller = GameController(game);
      executor = CommandExecutor(controller);
    });

    Unit unit(int id) => controller.state.units.firstWhere((u) => u.id == id);

    Command makeCmd(
      int unitId, {
      TaskType task = TaskType.assault,
      (int, int)? move,
      (int, int)? attack,
      int issued = 1,
      int deadline = 1,
    }) => Command(
      unitId: unitId,
      task: task,
      moveTo: move,
      attack: attack,
      issuedTurn: issued,
      deadlineTurn: deadline,
    );

    group('守卫', () {
      test('空令执行为待命：登记姿态、不算行动', () {
        final c = makeCmd(1, task: TaskType.standby);
        final report = executor.executeOne(c);

        expect(c.status, CommandStatus.executed);
        expect(report, isEmpty);
        expect(unit(1).task, TaskType.standby);
        expect(unit(1).hasActed, isFalse);
      });

      test('受令纵队不在场：拒绝', () {
        final c = makeCmd(999);
        final report = executor.executeOne(c);

        expect(c.status, CommandStatus.blocked);
        expect(report, isEmpty);
      });

      test('受令纵队已亡：拒绝', () {
        unit(1).takeDamage(999);
        final c = makeCmd(1, attack: (4, 3));
        final report = executor.executeOne(c);

        expect(c.status, CommandStatus.blocked);
        expect(report, isEmpty);
      });

      test('受令纵队不归我方：拒绝', () {
        final c = makeCmd(10, attack: (3, 3)); // 10 是红方
        final report = executor.executeOne(c);

        expect(c.status, CommandStatus.blocked);
        expect(report, isEmpty);
      });

      test('本回合已行动：拒绝', () {
        unit(1).markActed();
        final c = makeCmd(1, attack: (4, 3));
        final report = executor.executeOne(c);

        expect(c.status, CommandStatus.blocked);
        expect(report, isEmpty);
      });

      test('命令过期：拒绝为 expired', () {
        final c = makeCmd(1, attack: (4, 3), issued: 0, deadline: 0);
        final report = executor.executeOne(c);

        expect(c.status, CommandStatus.expired);
        expect(report, isEmpty);
        expect(unit(1).hasActed, isFalse);
      });
    });

    group('执行', () {
      test('移动+攻击整条执行：战报含移动与战斗', () {
        final u = unit(1);
        final range = controller.engine.getMoveRange(
          u,
          controller.state.units,
          controller.state.campaign,
        );
        // 选一个可达、且落位后仍与敌 (4,3) 相邻的格子
        final dest = Battlefield.getNeighbors(
          4,
          3,
          10,
          7,
        ).firstWhere((n) => range.containsKey('${n.$1},${n.$2}'));
        final c = makeCmd(1, move: dest, attack: (4, 3));
        final report = executor.executeOne(c);

        expect(c.status, CommandStatus.executed);
        expect(report.length, greaterThanOrEqualTo(2)); // 移动 + 战斗
        expect((u.col, u.row), dest);
        expect(u.task, TaskType.assault);
        expect(u.hasActed, isTrue);
        expect(c.resultText, isNotNull);
      });

      test('移动不可达：整条拒绝，不再尝试攻击', () {
        final u = unit(1);
        final before = (u.col, u.row);
        final c = makeCmd(1, move: (9, 6), attack: (4, 3));
        final report = executor.executeOne(c);

        expect(c.status, CommandStatus.blocked);
        expect(report, isEmpty);
        expect((u.col, u.row), before);
        expect(u.hasActed, isFalse);
      });

      test('攻击落空不撤销移动：executed 并记落空', () {
        final u = unit(1);
        final range = controller.engine.getMoveRange(
          u,
          controller.state.units,
          controller.state.campaign,
        );
        final destKey = range.keys.first;
        final dest = (
          int.parse(destKey.split(',')[0]),
          int.parse(destKey.split(',')[1]),
        );
        final c = makeCmd(1, move: dest, attack: (0, 0)); // (0,0) 无敌
        final report = executor.executeOne(c);

        expect(c.status, CommandStatus.executed);
        expect(c.resultText, contains('攻击落空'));
        expect(report, isNotEmpty); // 移动战报仍在
        expect((u.col, u.row), dest);
        expect(u.hasActed, isTrue);
      });

      test('只攻击成功', () {
        final c = makeCmd(1, attack: (4, 3));
        final report = executor.executeOne(c);

        expect(c.status, CommandStatus.executed);
        expect(report, isNotEmpty);
        expect(unit(1).hasActed, isTrue);
      });
    });

    group('executeAll 批量', () {
      test('逐条独立：一条失败不影响其余，战报汇总进战报流', () {
        final good = makeCmd(1, attack: (4, 3));
        final bad = makeCmd(999);
        final before = controller.state.logMessages.length;

        final report = executor.executeAll([good, bad]);

        expect(good.status, CommandStatus.executed);
        expect(bad.status, CommandStatus.blocked);
        expect(report, isNotEmpty);
        expect(controller.state.logMessages.length, greaterThan(before));
      });
    });
  });
}
