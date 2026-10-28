import 'dart:math';
import 'unit.dart';
import 'campaign.dart';
import 'battlefield.dart';

CombatResult resolveCombat(Unit attacker, Unit defender, Campaign campaign, List<List<TerrainType>> mapTerrain) {
  int hitChance = 55;
  hitChance += attacker.type.baseAttack * 6;
  hitChance += campaign.hitMod;
  hitChance -= _terrainDefense(defender, mapTerrain) * 8;
  final dist = Battlefield.hexDistance(attacker.col, attacker.row, defender.col, defender.row);
  if (dist > 1) hitChance -= (dist - 1) * 4;
  hitChance = hitChance.clamp(5, 92);

  final roll = Random().nextInt(100) + 1;
  final bool hit = roll <= hitChance;
  int damage = 0;
  String text;

  if (hit) {
    if (attacker.type.isAssault && _inFullCover(defender, mapTerrain)) {
      damage = min(2, defender.hp);
      text = '\u{1F4A5}突击成功！重创核心守军！';
    } else {
      damage = 1;
      if (roll <= hitChance * 0.25) {
        damage = min(2, defender.hp);
        text = '\u{1F3AF}重创敌军！';
      } else {
        text = '\u2705命中！';
      }
    }
  } else {
    text = '\u274C未命中';
  }

  bool killed = defender.hp - damage <= 0;

  if (killed) {
    text += ' 敌军被歼灭！';
  }

  return CombatResult(hit: hit, damage: damage, text: text, killed: killed);
}

class CombatResult {
  final bool hit;
  final int damage;
  final String text;
  final bool killed;

  const CombatResult({
    required this.hit,
    required this.damage,
    required this.text,
    required this.killed,
  });
}

int _terrainDefense(Unit unit, List<List<TerrainType>> map) =>
    terrainProps[map[unit.row][unit.col]]!.defenseBonus;

bool _inFullCover(Unit unit, List<List<TerrainType>> map) =>
    terrainProps[map[unit.row][unit.col]]!.fullCover;
