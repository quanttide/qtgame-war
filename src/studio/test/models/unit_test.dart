import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/task.dart';
import 'package:studio/models/unit.dart';

void main() {
  group('Unit', () {
    test('moveTo updates position', () {
      final u = Unit(
        id: 1,
        side: Side.blue,
        type: UnitLibrary.lightInfantry,
        col: 0,
        row: 0,
      );
      u.moveTo(5, 3);
      expect(u.col, 5);
      expect(u.row, 3);
    });

    test('takeDamage reduces hp and kills when exhausted', () {
      final u = Unit(
        id: 1,
        side: Side.blue,
        type: UnitLibrary.lightInfantry,
        col: 0,
        row: 0,
        hp: 3,
      );
      u.takeDamage(1);
      expect(u.hp, 2);
      expect(u.alive, true);
      u.takeDamage(2);
      expect(u.hp, 0);
      expect(u.alive, false);
    });

    test('markActed and reveal toggle flags', () {
      final u = Unit(
        id: 1,
        side: Side.blue,
        type: UnitLibrary.lightInfantry,
        col: 0,
        row: 0,
      );
      expect(u.hasActed, false);
      u.markActed();
      expect(u.hasActed, true);
      expect(u.revealed, false);
      u.reveal();
      expect(u.revealed, true);
    });

    test('task 默认 null，可指派；fat 默认 0，可累加', () {
      final u = Unit(
        id: 1,
        side: Side.blue,
        type: UnitLibrary.lightInfantry,
        col: 0,
        row: 0,
      );
      expect(u.task, isNull);
      expect(u.fat, 0);
      u.task = TaskType.assault;
      u.fat += TaskType.assault.fat;
      expect(u.task, TaskType.assault);
      expect(u.fat, 2);
    });
  });
}
