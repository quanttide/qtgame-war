import 'dart:math';
import 'unit.dart';
import 'campaign.dart';
import 'battlefield.dart';

class Game {
  final List<List<TerrainType>> mapTerrain;

  Game(this.mapTerrain);

  static int terrainDefense(Unit unit, List<List<TerrainType>> map) =>
      terrainProps[map[unit.row][unit.col]]!.defenseBonus;

  static bool inFullCover(Unit unit, List<List<TerrainType>> map) =>
      terrainProps[map[unit.row][unit.col]]!.fullCover;

  static bool inCore(Unit unit, List<List<TerrainType>> map) =>
      terrainProps[map[unit.row][unit.col]]!.isCore;

  Map<String, int> getMoveRange(Unit unit, List<Unit> allUnits) {
    final reachable = <String, int>{};
    final key = '${unit.col},${unit.row}';
    final queue = <(int, int, int)>[(unit.col, unit.row, unit.effectiveMoveRange)];
    reachable[key] = unit.effectiveMoveRange;

    while (queue.isNotEmpty) {
      final (c, r, remaining) = queue.removeAt(0);
      for (final (nc, nr) in Battlefield.getNeighbors(c, r)) {
        final nk = '$nc,$nr';
        final occ = getUnitAt(nc, nr, allUnits);
        if (occ != null && occ.id != unit.id) continue;
        final terrain = mapTerrain[nr][nc];
        if (terrain == TerrainType.coreFort && unit.special != 'assault') continue;
        final cost = terrainProps[terrain]!.moveCost;
        final nr2 = remaining - cost;
        if (nr2 < 0) continue;
        if (!reachable.containsKey(nk) || reachable[nk]! < nr2) {
          reachable[nk] = nr2;
          if (nr2 > 0) queue.add((nc, nr, nr2));
        }
      }
    }
    reachable.remove(key);
    return reachable;
  }

  Set<String> getAttackTargets(Unit unit, List<Unit> allUnits) {
    final targets = <String>{};
    for (final enemy in allUnits) {
      if (!enemy.alive || enemy.side != 'nationalist' || !enemy.revealed) continue;
      final dist = Battlefield.hexDistance(unit.col, unit.row, enemy.col, enemy.row);
      if (dist <= unit.attackRange) {
        if (inFullCover(enemy, mapTerrain) && dist > 1) continue;
        targets.add('${enemy.col},${enemy.row}');
      }
    }
    return targets;
  }

  CombatResult resolveCombat(Unit attacker, Unit defender, Campaign campaign) {
    int hitChance = 55;
    hitChance += attacker.baseAttack * 6;
    hitChance += campaign.hitMod;
    hitChance -= terrainDefense(defender, mapTerrain) * 8;
    final dist = Battlefield.hexDistance(attacker.col, attacker.row, defender.col, defender.row);
    if (dist > 1) hitChance -= (dist - 1) * 4;
    hitChance = hitChance.clamp(5, 92);

    final roll = Random().nextInt(100) + 1;
    final bool hit = roll <= hitChance;
    int damage = 0;
    String text;

    if (hit) {
      if (attacker.special == 'assault' && inFullCover(defender, mapTerrain)) {
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

    defender.hp -= damage;
    bool killed = false;
    if (defender.hp <= 0) {
      defender.alive = false;
      defender.hp = 0;
      text += ' 敌军被歼灭！';
      killed = true;
    }

    return CombatResult(hit: hit, damage: damage, text: text, killed: killed);
  }

  (List<Unit>, List<Dispatch>) spawnReinforcements(
      List<Unit> units, Campaign campaign, int currentTurn) {
    final newUnits = <Unit>[];
    final logs = <Dispatch>[];
    if (currentTurn >= campaign.qiuReinforceTurn && !campaign.qiuArrived) {
      campaign.qiuArrived = true;
      newUnits.addAll([
        Unit(id: 30, name: '邱清泉·第5军先头', side: 'nationalist', col: 0, row: 2, maxHp: 2, baseAttack: 3, baseDefense: 1, baseMoveRange: 5, attackRange: 1),
        Unit(id: 31, name: '邱清泉·第70师', side: 'nationalist', col: 0, row: 3, maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 4, attackRange: 2),
      ]);
      for (final u in newUnits.sublist(newUnits.length - 2)) {
        u.revealed = true;
        u.isReinforcement = true;
      }
      logs.add(Dispatch('\u{1F4A5}邱清泉兵团援军从西面抵达战场！', 'urgent', currentTurn));
    }
    if (currentTurn >= campaign.huReinforceTurn && !campaign.huArrived) {
      campaign.huArrived = true;
      newUnits.addAll([
        Unit(id: 32, name: '胡琏·整11师先头', side: 'nationalist', col: 7, row: 6, maxHp: 2, baseAttack: 3, baseDefense: 1, baseMoveRange: 5, attackRange: 1),
        Unit(id: 33, name: '胡琏·整11师主力', side: 'nationalist', col: 8, row: 5, maxHp: 3, baseAttack: 2, baseDefense: 1, baseMoveRange: 4, attackRange: 1),
      ]);
      for (final u in newUnits.sublist(newUnits.length - 2)) {
        u.revealed = true;
        u.isReinforcement = true;
      }
      logs.add(Dispatch('\u{1F4A5}胡琏兵团援军从南面抵达战场！', 'urgent', currentTurn));
    }
    return (newUnits, logs);
  }

  void checkVictory(List<Unit> units, Campaign campaign, int currentTurn) {
    final natUnits = units.where((u) => u.alive && u.side == 'nationalist');
    if (natUnits.isEmpty) {
      campaign.gameOver = true;
      campaign.victory = true;
      campaign.victoryDetail = '帝丘店地区国军全部肃清！';
      return;
    }
    final coreOccupied = units.any((u) => u.alive && inCore(u, mapTerrain) && u.side == 'pla');
    if (coreOccupied && campaign.fortStrength <= 0) {
      campaign.gameOver = true;
      campaign.victory = true;
      campaign.victoryDetail = '帝丘店核心阵地已被攻占！';
      return;
    }
  }

  Unit? getUnitAt(int col, int row, List<Unit> units) {
    return units.cast<Unit?>().firstWhere(
      (u) => u!.alive && u.col == col && u.row == row,
      orElse: () => null,
    );
  }

  List<Unit> createInitialUnits() {
    return [
      Unit(id: 1, name: '四纵十二师', side: 'pla', col: 1, row: 2, maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1, special: 'assault', revealed: true),
      Unit(id: 2, name: '四纵十师', side: 'pla', col: 0, row: 1, maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1, revealed: true),
      Unit(id: 3, name: '四纵十一师', side: 'pla', col: 2, row: 3, maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1, revealed: true),
      Unit(id: 4, name: '一纵一师', side: 'pla', col: 1, row: 4, maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1, revealed: true),
      Unit(id: 5, name: '一纵二师', side: 'pla', col: 3, row: 5, maxHp: 2, baseAttack: 2, baseDefense: 0, baseMoveRange: 4, attackRange: 1, revealed: true),
      Unit(id: 6, name: '六纵十六师', side: 'pla', col: 5, row: 5, maxHp: 3, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1, revealed: true),
      Unit(id: 7, name: '六纵十七师', side: 'pla', col: 6, row: 5, maxHp: 2, baseAttack: 1, baseDefense: 1, baseMoveRange: 4, attackRange: 2, revealed: true),
      Unit(id: 8, name: '特纵炮兵群', side: 'pla', col: 0, row: 3, maxHp: 2, baseAttack: 3, baseDefense: 0, baseMoveRange: 3, attackRange: 3, revealed: true),
      Unit(id: 20, name: '整25师40旅(核心)', side: 'nationalist', col: 5, row: 4, maxHp: 3, baseAttack: 2, baseDefense: 2, baseMoveRange: 2, attackRange: 1),
      Unit(id: 21, name: '整25师108旅', side: 'nationalist', col: 4, row: 4, maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 3, attackRange: 1),
      Unit(id: 22, name: '快速纵队', side: 'nationalist', col: 6, row: 4, maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1),
      Unit(id: 23, name: '田花园守备团', side: 'nationalist', col: 3, row: 2, maxHp: 1, baseAttack: 1, baseDefense: 1, baseMoveRange: 1, attackRange: 1, revealed: true),
      Unit(id: 24, name: '马口守备队', side: 'nationalist', col: 2, row: 5, maxHp: 1, baseAttack: 1, baseDefense: 1, baseMoveRange: 1, attackRange: 1, revealed: true),
      Unit(id: 25, name: '刘楼守备队', side: 'nationalist', col: 7, row: 1, maxHp: 1, baseAttack: 1, baseDefense: 1, baseMoveRange: 1, attackRange: 1, revealed: true),
    ];
  }
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

class Dispatch {
  final String msg;
  final String type;
  final int turn;
  const Dispatch(this.msg, this.type, this.turn);
}
