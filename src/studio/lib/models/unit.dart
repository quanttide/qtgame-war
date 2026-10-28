import 'campaign.dart';
import 'task.dart';

enum Side { blue, red }

class UnitType {
  final String name;
  final int maxHp;
  final int baseAttack;
  final int baseDefense;
  final int baseMoveRange;
  final int attackRange;
  final bool isAssault;

  const UnitType({
    required this.name,
    required this.maxHp,
    required this.baseAttack,
    required this.baseDefense,
    required this.baseMoveRange,
    required this.attackRange,
    this.isAssault = false,
  });

  factory UnitType.fromJson(Map<String, dynamic> json) => UnitType(
    name: json['name'],
    maxHp: json['max_hp'],
    baseAttack: json['attack'],
    baseDefense: json['defense'],
    baseMoveRange: json['move'],
    attackRange: json['range'],
    isAssault: json['assault'] ?? false,
  );
}

class UnitLibrary {
  static const lightInfantry = UnitType(
    name: '轻步兵',
    maxHp: 3,
    baseAttack: 2,
    baseDefense: 0,
    baseMoveRange: 4,
    attackRange: 1,
  );

  static const heavyInfantry = UnitType(
    name: '重步兵',
    maxHp: 4,
    baseAttack: 3,
    baseDefense: 1,
    baseMoveRange: 3,
    attackRange: 1,
  );

  static const artillery = UnitType(
    name: '炮兵',
    maxHp: 2,
    baseAttack: 4,
    baseDefense: 0,
    baseMoveRange: 3,
    attackRange: 3,
  );

  static const cavalry = UnitType(
    name: '骑兵',
    maxHp: 3,
    baseAttack: 2,
    baseDefense: 0,
    baseMoveRange: 6,
    attackRange: 1,
  );

  static const assaultInfantry = UnitType(
    name: '突击步兵',
    maxHp: 3,
    baseAttack: 2,
    baseDefense: 1,
    baseMoveRange: 5,
    attackRange: 1,
    isAssault: true,
  );

  static final List<UnitType> all = [
    lightInfantry,
    heavyInfantry,
    artillery,
    cavalry,
    assaultInfantry,
  ];
}

class Unit {
  final int id;
  final Side side;
  final UnitType type;
  int col;
  int row;
  int hp;
  bool hasActed;
  bool revealed;
  bool alive;
  bool isReinforcement;

  /// 本回合命令档位（指挥官层姿态），null 未指派
  TaskType? task;

  /// 累积疲劳，由档位增量/待命恢复驱动
  int fat;

  Unit({
    required this.id,
    required this.side,
    required this.type,
    required this.col,
    required this.row,
    int? hp,
    this.hasActed = false,
    this.revealed = false,
    this.alive = true,
    this.isReinforcement = false,
    this.task,
    this.fat = 0,
  }) : hp = hp ?? type.maxHp;

  /// 有效移动范围 = 基础移动范围 - 移动修正（moveMod 越大移动力越少）。
  /// 收注入修正标量而非 Campaign，保持模型签名剧本无关。
  int effectiveMoveRange(int moveMod) =>
      (type.baseMoveRange - moveMod).clamp(1, 99);
  int get maxHp => type.maxHp;

  void moveTo(int newCol, int newRow) {
    col = newCol;
    row = newRow;
  }

  void takeDamage(int damage) {
    hp = (hp - damage).clamp(0, type.maxHp);
    if (hp <= 0) alive = false;
  }

  void markActed() {
    hasActed = true;
  }

  void reveal() {
    revealed = true;
  }
}
