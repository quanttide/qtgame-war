import 'dart:math';
import 'unit.dart';
import 'battlefield.dart';
import 'game.dart';

/// 战斗结算。纯函数，收注入命中修正标量 [hitMod]（由调用方从剧本状态取出）、
/// 注入的 [book] 地形容器与注入的随机源 [rng]，不收整个剧本状态对象、
/// 不内部构造 Random——保持签名剧本无关，同种子同输入序列结算可复算。
CombatResult resolveCombat(
  Unit attacker,
  Unit defender,
  TerrainBook book, {
  required Random rng,
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

  final roll = rng.nextInt(100) + 1;
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

/// 战斗应用原语（侧别中立）：把结算结果落到单位上并产战报。
///
/// 只做三样：守方 `takeDamage`、攻方 `markActed`、产一条 [Dispatch]。
/// 侧别专属资源结算（`playerPower` 消耗、`fortStrength` 削减、`reveal`）
/// 留在玩家路径调用方；玩家与敌军两路共用本原语，战果落盘不各写一份。
Dispatch applyCombatOutcome(
  Unit attacker,
  Unit defender,
  CombatResult result, {
  required int turn,
  required String type,
}) {
  defender.takeDamage(result.damage);
  attacker.markActed();
  return Dispatch(
    '${attacker.type.name} → ${defender.type.name}：${result.text}',
    type,
    turn,
  );
}
