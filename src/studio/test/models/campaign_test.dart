import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/campaign.dart';

void main() {
  group('Campaign', () {
    test('powerDesc returns correct descriptions at thresholds', () {
      expect(Campaign(huayePower: 85).powerDesc, '充沛');
      expect(Campaign(huayePower: 50).powerDesc, '尚可');
      expect(Campaign(huayePower: 30).powerDesc, '吃紧');
      expect(Campaign(huayePower: 10).powerDesc, '濒临极限');
    });

    test('hitMod and moveMod at different power levels', () {
      expect(Campaign(huayePower: 85).hitMod, 5);
      expect(Campaign(huayePower: 50).hitMod, 0);
      expect(Campaign(huayePower: 30).hitMod, -5);
      expect(Campaign(huayePower: 10).hitMod, -12);
      expect(Campaign(huayePower: 85).moveMod, 0);
      expect(Campaign(huayePower: 30).moveMod, 1);
      expect(Campaign(huayePower: 10).moveMod, 2);
    });
  });
}
