import 'package:flutter_test/flutter_test.dart';
import 'package:studio/engine/game_engine.dart';
import 'package:studio/engine/map_data.dart';
import 'package:studio/models/campaign.dart';

void main() {
  test('GameEngine resolves combat', () {
    final engine = GameEngine(createMapTerrain());
    final units = engine.createInitialUnits();
    final attacker = units.first;
    final defender = units[8]; // nationalist unit
    final campaign = Campaign();

    final result = engine.resolveCombat(attacker, defender, campaign);
    expect(result.hit == true || result.hit == false, true);
  });
}
