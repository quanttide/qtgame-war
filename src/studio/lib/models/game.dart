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
        if (terrain == TerrainType.coreFort && !unit.type.isAssault) continue;
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
      if (!enemy.alive || enemy.side != Side.red || !enemy.revealed) continue;
      final dist = Battlefield.hexDistance(unit.col, unit.row, enemy.col, enemy.row);
      if (dist <= unit.type.attackRange) {
        if (inFullCover(enemy, mapTerrain) && dist > 1) continue;
        targets.add('${enemy.col},${enemy.row}');
      }
    }
    return targets;
  }

  (List<Unit>, List<Dispatch>) spawnReinforcements(
      List<Unit> units, Campaign campaign, int currentTurn) {
    final newUnits = <Unit>[];
    final logs = <Dispatch>[];
    if (currentTurn >= campaign.qiuReinforceTurn && !campaign.qiuArrived) {
      campaign.qiuArrived = true;
      const qiuVan = UnitType(name: '邱清泉·第5军先头', maxHp: 2, baseAttack: 3, baseDefense: 1, baseMoveRange: 5, attackRange: 1);
      const qiuDiv = UnitType(name: '邱清泉·第70师', maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 4, attackRange: 2);
      newUnits.addAll([
        Unit(id: 30, side: Side.red, type: qiuVan, col: 0, row: 2, hp: 2, revealed: true, isReinforcement: true),
        Unit(id: 31, side: Side.red, type: qiuDiv, col: 0, row: 3, hp: 2, revealed: true, isReinforcement: true),
      ]);
      logs.add(Dispatch('\u{1F4A5}邱清泉兵团援军从西面抵达战场！', 'urgent', currentTurn));
    }
    if (currentTurn >= campaign.huReinforceTurn && !campaign.huArrived) {
      campaign.huArrived = true;
      const huVan = UnitType(name: '胡琏·整11师先头', maxHp: 2, baseAttack: 3, baseDefense: 1, baseMoveRange: 5, attackRange: 1);
      const huMain = UnitType(name: '胡琏·整11师主力', maxHp: 3, baseAttack: 2, baseDefense: 1, baseMoveRange: 4, attackRange: 1);
      newUnits.addAll([
        Unit(id: 32, side: Side.red, type: huVan, col: 7, row: 6, hp: 2, revealed: true, isReinforcement: true),
        Unit(id: 33, side: Side.red, type: huMain, col: 8, row: 5, hp: 3, revealed: true, isReinforcement: true),
      ]);
      logs.add(Dispatch('\u{1F4A5}胡琏兵团援军从南面抵达战场！', 'urgent', currentTurn));
    }
    return (newUnits, logs);
  }

  void checkVictory(List<Unit> units, Campaign campaign, int currentTurn) {
    final natUnits = units.where((u) => u.alive && u.side == Side.red);
    if (natUnits.isEmpty) {
      campaign.gameOver = true;
      campaign.victory = true;
      campaign.victoryDetail = '帝丘店地区国军全部肃清！';
      return;
    }
    final coreOccupied = units.any((u) => u.alive && inCore(u, mapTerrain) && u.side == Side.blue);
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
    const ziShiEr = UnitType(name: '四纵十二师', maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1, isAssault: true);
    const ziShi = UnitType(name: '四纵十师', maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1);
    const ziYi = UnitType(name: '四纵十一师', maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1);
    const yiYi = UnitType(name: '一纵一师', maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1);
    const yiEr = UnitType(name: '一纵二师', maxHp: 2, baseAttack: 2, baseDefense: 0, baseMoveRange: 4, attackRange: 1);
    const liuShiLiu = UnitType(name: '六纵十六师', maxHp: 3, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1);
    const liuShiQi = UnitType(name: '六纵十七师', maxHp: 2, baseAttack: 1, baseDefense: 1, baseMoveRange: 4, attackRange: 2);
    const teArt = UnitType(name: '特纵炮兵群', maxHp: 2, baseAttack: 3, baseDefense: 0, baseMoveRange: 3, attackRange: 3);

    const zheng40 = UnitType(name: '整25师40旅(核心)', maxHp: 3, baseAttack: 2, baseDefense: 2, baseMoveRange: 2, attackRange: 1);
    const zheng108 = UnitType(name: '整25师108旅', maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 3, attackRange: 1);
    const kuaiSu = UnitType(name: '快速纵队', maxHp: 2, baseAttack: 2, baseDefense: 1, baseMoveRange: 5, attackRange: 1);
    const tian = UnitType(name: '田花园守备团', maxHp: 1, baseAttack: 1, baseDefense: 1, baseMoveRange: 1, attackRange: 1);
    const maKou = UnitType(name: '马口守备队', maxHp: 1, baseAttack: 1, baseDefense: 1, baseMoveRange: 1, attackRange: 1);
    const liuLou = UnitType(name: '刘楼守备队', maxHp: 1, baseAttack: 1, baseDefense: 1, baseMoveRange: 1, attackRange: 1);

    return [
      Unit(id: 1, side: Side.blue, type: ziShiEr, col: 1, row: 2, revealed: true),
      Unit(id: 2, side: Side.blue, type: ziShi, col: 0, row: 1, revealed: true),
      Unit(id: 3, side: Side.blue, type: ziYi, col: 2, row: 3, revealed: true),
      Unit(id: 4, side: Side.blue, type: yiYi, col: 1, row: 4, revealed: true),
      Unit(id: 5, side: Side.blue, type: yiEr, col: 3, row: 5, revealed: true),
      Unit(id: 6, side: Side.blue, type: liuShiLiu, col: 5, row: 5, revealed: true),
      Unit(id: 7, side: Side.blue, type: liuShiQi, col: 6, row: 5, revealed: true),
      Unit(id: 8, side: Side.blue, type: teArt, col: 0, row: 3, revealed: true),
      Unit(id: 20, side: Side.red, type: zheng40, col: 5, row: 4),
      Unit(id: 21, side: Side.red, type: zheng108, col: 4, row: 4),
      Unit(id: 22, side: Side.red, type: kuaiSu, col: 6, row: 4),
      Unit(id: 23, side: Side.red, type: tian, col: 3, row: 2, revealed: true),
      Unit(id: 24, side: Side.red, type: maKou, col: 2, row: 5, revealed: true),
      Unit(id: 25, side: Side.red, type: liuLou, col: 7, row: 1, revealed: true),
    ];
  }
}

class Dispatch {
  final String msg;
  final String type;
  final int turn;
  const Dispatch(this.msg, this.type, this.turn);
}
