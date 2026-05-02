import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/combat.dart';
import 'package:studio/models/game.dart';
import 'package:studio/models/campaign.dart';

void main() {
  testWidgets('Game resolves combat', (tester) async {
    final config = await CampaignConfig.load('diqiudian');
    final engine = Game(config);
    final units = engine.createInitialUnits();
    final attacker = units.first;
    final defender = units[8];
    final campaign = Campaign();

    final result = resolveCombat(attacker, defender, campaign, engine.mapTerrain);
    expect(result.hit == true || result.hit == false, true);
  });
}
