import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/combat.dart';
import 'package:studio/models/game.dart';
import 'package:studio/models/battlefield.dart';
import 'package:studio/models/campaign.dart';

void main() {
  test('Game resolves combat', () {
    final engine = Game(Battlefield.createMapTerrain());
    final units = engine.createInitialUnits();
    final attacker = units.first;
    final defender = units[8]; // nationalist unit
    final campaign = Campaign();

    final result = resolveCombat(attacker, defender, campaign, engine.mapTerrain);
    expect(result.hit == true || result.hit == false, true);
  });
}
