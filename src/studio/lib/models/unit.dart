enum Side { pla, nationalist }

enum UnitAbility { assault }

class Unit {
  final int id;
  final String name;
  final Side side;
  final int col;
  final int row;
  final int maxHp;
  final int hp;
  final int baseAttack;
  final int baseDefense;
  final int baseMoveRange;
  final int attackRange;
  final UnitAbility? special;
  final bool hasActed;
  final bool revealed;
  final bool alive;
  final bool isReinforcement;

  Unit({
    required this.id,
    required this.name,
    required this.side,
    required this.col,
    required this.row,
    required this.maxHp,
    int? hp,
    required this.baseAttack,
    required this.baseDefense,
    required this.baseMoveRange,
    required this.attackRange,
    this.special,
    this.hasActed = false,
    this.revealed = false,
    this.alive = true,
    this.isReinforcement = false,
  }) : hp = hp ?? maxHp;

  int get effectiveMoveRange => baseMoveRange;

  Unit copyWith({
    int? id,
    String? name,
    Side? side,
    int? col,
    int? row,
    int? maxHp,
    int? hp,
    int? baseAttack,
    int? baseDefense,
    int? baseMoveRange,
    int? attackRange,
    UnitAbility? special,
    bool? hasActed,
    bool? revealed,
    bool? alive,
    bool? isReinforcement,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      side: side ?? this.side,
      col: col ?? this.col,
      row: row ?? this.row,
      maxHp: maxHp ?? this.maxHp,
      hp: hp ?? this.hp,
      baseAttack: baseAttack ?? this.baseAttack,
      baseDefense: baseDefense ?? this.baseDefense,
      baseMoveRange: baseMoveRange ?? this.baseMoveRange,
      attackRange: attackRange ?? this.attackRange,
      special: special ?? this.special,
      hasActed: hasActed ?? this.hasActed,
      revealed: revealed ?? this.revealed,
      alive: alive ?? this.alive,
      isReinforcement: isReinforcement ?? this.isReinforcement,
    );
  }

  Unit moveTo(int newCol, int newRow) => copyWith(col: newCol, row: newRow);

  Unit takeDamage(int damage) {
    final newHp = (hp - damage).clamp(0, maxHp);
    return copyWith(hp: newHp, alive: newHp > 0);
  }

  Unit markActed() => copyWith(hasActed: true);

  Unit reveal() => copyWith(revealed: true);

  Unit markReinforcement() => copyWith(isReinforcement: true);
}
