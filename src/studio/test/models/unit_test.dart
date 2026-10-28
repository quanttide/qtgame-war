import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/unit.dart';

void main() {
  group('Unit', () {
    test('moveTo updates position', () {
      final u = Unit(id: 1, side: Side.blue, type: UnitLibrary.lightInfantry, col: 0, row: 0);
      u.moveTo(5, 3);
      expect(u.col, 5);
      expect(u.row, 3);
    });

    test('takeDamage reduces hp and kills when exhausted', () {
      final u = Unit(id: 1, side: Side.blue, type: UnitLibrary.lightInfantry, col: 0, row: 0, hp: 3);
      u.takeDamage(1);
      expect(u.hp, 2);
      expect(u.alive, true);
      u.takeDamage(2);
      expect(u.hp, 0);
      expect(u.alive, false);
    });

    test('markActed and reveal toggle flags', () {
      final u = Unit(id: 1, side: Side.blue, type: UnitLibrary.lightInfantry, col: 0, row: 0);
      expect(u.hasActed, false);
      u.markActed();
      expect(u.hasActed, true);
      expect(u.revealed, false);
      u.reveal();
      expect(u.revealed, true);
    });
  });
}
