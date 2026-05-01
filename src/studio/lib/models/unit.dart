import 'battlefield.dart';

class Unit {
  final int id;
  final String name;
  final String side;
  int col;
  int row;
  final int maxHp;
  int hp;
  final int baseAttack;
  final int baseDefense;
  final int baseMoveRange;
  final int attackRange;
  final String? special;
  bool hasActed;
  bool revealed;
  bool alive;
  bool isReinforcement;

  Unit({
    required this.id,
    required this.name,
    required this.side,
    required this.col,
    required this.row,
    required this.maxHp,
    required this.baseAttack,
    required this.baseDefense,
    required this.baseMoveRange,
    required this.attackRange,
    this.special,
    this.hasActed = false,
    this.revealed = false,
    this.alive = true,
    this.isReinforcement = false,
  }) : hp = maxHp;

  int get effectiveMoveRange {
    return baseMoveRange;
  }

  int getTerrainDefense(List<List<TerrainType>> mapTerrain) {
    return terrainProps[mapTerrain[row][col]]!.defenseBonus;
  }

  bool isInFullCover(List<List<TerrainType>> mapTerrain) {
    return terrainProps[mapTerrain[row][col]]!.fullCover;
  }

  bool isInCore(List<List<TerrainType>> mapTerrain) {
    return terrainProps[mapTerrain[row][col]]!.isCore;
  }

  Unit copy() {
    final u = Unit(
      id: id,
      name: name,
      side: side,
      col: col,
      row: row,
      maxHp: maxHp,
      baseAttack: baseAttack,
      baseDefense: baseDefense,
      baseMoveRange: baseMoveRange,
      attackRange: attackRange,
      special: special,
    );
    u.hp = hp;
    u.hasActed = hasActed;
    u.revealed = revealed;
    u.alive = alive;
    u.isReinforcement = isReinforcement;
    return u;
  }
}
