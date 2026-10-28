import 'dart:math';
import 'unit.dart';
import 'battlefield.dart';

/// 战斗结算。纯函数，收注入命中修正标量 [hitMod]（由调用方从剧本状态取出）
/// 与注入的 [book] 地形容器，不收整个剧本状态对象——保持签名剧本无关。
CombatResult resolveCombat(
  Unit attacker,
  Unit defender,
  TerrainBook book, {
  int hitMod = 0,
}) {
  final defProps = book.propsAt(defender.col, defender.row);

  int hitChance = 55;
  hitChance += attacker.type.baseAttack * 6;
  hitChance += hitMod;
  hitChance -= defProps.defenseBonus * 8;
  final dist = Battlefield.hexDistance(
    attacker.col,
    attacker.row,
    defender.col,
    defender.row,
  );
  if (dist > 1) hitChance -= (dist - 1) * 4;
  hitChance = hitChance.clamp(5, 92);

  final roll = Random().nextInt(100) + 1;
  final bool hit = roll <= hitChance;
  int damage = 0;
  String text;

  if (hit) {
    if (attacker.type.isAssault && defProps.fullCover) {
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
