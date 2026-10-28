import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/models/campaign.dart';
import 'package:studio/models/combat.dart';
import 'package:studio/models/battlefield.dart';

void main() {
  group('Combat', () {
    test('resolveCombat returns valid structure', () {
      final attacker = Unit(id: 1, side: Side.blue, type: UnitLibrary.lightInfantry, col: 0, row: 1);
      final defender = Unit(id: 2, side: Side.red, type: UnitLibrary.lightInfantry, col: 0, row: 2, hp: 3);
      final campaign = Campaign();
      final terrain = Battlefield.createMapTerrain();

      final result = resolveCombat(attacker, defender, campaign, terrain);
      expect(result.hit, isA<bool>());
      expect(result.damage, greaterThanOrEqualTo(0));
      expect(result.killed, isA<bool>());
      expect(result.text, isA<String>());
    });
  });
}
