# 单位模块

Unit 类是游戏的原子实体，承载了所有与单个单位相关的数据。它看似简单，但几个设计选择使其在更大架构中显得“不协调”。以下逐点分析。

—

模块职责一览

Unit 纯粹是数据容器，没有方法逻辑（除了 copy 和 getter）。字段涵盖：

· 标识：id, name
· 阵营：side (字符串)
· 位置：col, row
· 属性：maxHp / hp, baseAttack, baseDefense, baseMoveRange, attackRange
· 特殊能力：special 字符串（如 ’assault‘）
· 状态标记：hasActed, revealed, alive, isReinforcement

唯一计算属性 effectiveMoveRange 当前只是返回 baseMoveRange，预留了未来被战役修正影响的空间（但修正逻辑在其他类）。

—

优点

1. 集中定义：单位相关数据没有被拆散到各处，一组平行字段便于序列化和 UI 绑定。
2. 提供 copy()：返回深拷贝对象，方便不可变状态更新（虽然没有被充分利用，但为重构留了接口）。
3. 默认值合理：hasActed = false, alive = true, hp = maxHp 使得构造后立即可用。

—

问题与改进

1. 可变性泛滥导致副作用

几乎所有字段都有公共 setter（隐式），包括 hp、hasActed、alive 等。外部代码（如 Game.resolveCombat）直接修改 defender.hp，甚至将 alive 置 false。这种隐藏的副作用使得：

· 难以追踪状态变更来源；
· 多线程/异步环境不安全；
· 测试时需要构造可变对象，且无法简单重放。

建议：将 Unit 改为不可变数据类。操作（受伤、死亡、移动）返回一个新的 Unit 实例。这需要配合外部状态管理，但能根除随意修改。

2. 字符串字段丢失类型安全

· side 用字符串 ’pla‘ / ’nationalist‘，容易拼写错误。
· special 用可空字符串，含义模糊（null 与空字符串有何区别？）。

建议：

· 定义 enum Side { pla, nationalist }。
· 将特技改为枚举或一个小型对象（若未来有多个特技，可用列表）。简单的 String? 至少应该有常量定义。

3. 空有拷贝方法却未被运用

copy() 已经写好了，但 Game 中战斗、移动等操作仍然直接修改原对象。copy() 的存在说明作者想过不可变设计，但并未坚持。

4. 计算属性 effectiveMoveRange 显得突兀

当前它仅仅返回 baseMoveRange，而 Game.spawnReinforcements 中手动设置 effectiveMoveRange 又成了摆设（因为该类没有 effectiveMoveRange setter，Unit 字段列表中没有这个属性）。实际上 Game.getMoveRange 使用的是 unit.effectiveMoveRange，然而这个 getter 永远不会被战役修正所改变。这说明战役移动惩罚（Campaign.moveMod）的代码尚未加入。

建议：要么让 Unit 知道移动惩罚，要么在外部计算实际移动力时结合 Campaign.moveMod。当前实现会导致移动修正永远不生效，是一个逻辑断层。

5. 初始状态与业务逻辑耦合

初始单位数据是 Game.createInitialUnits() 硬编码写的。Unit 本身没问题，但创建方式意味着修改剧本需要改动 Game 类。应将单位模板数据外置（JSON/列表），然后在 Game 或剧本工厂中实例化。

6. 缺少身份概念

id 是整型，但援军的 ID (30-33) 是手工指定的。如果新增单位，容易冲突。应采用自增ID生成器，或由系统自动分配唯一标识。

—

重构建议：不可变 Units + 独立特技

```dart
enum Side { pla, nationalist }

class UnitAbility {
  final String id; // 如 ’assault‘
  // 未来可加效果描述、触发条件等
  const UnitAbility._(this.id);
  static const assault = UnitAbility._(’assault‘);
}

class Unit {
  final int id;
  final String name;
  final Side side;
  final int col, row;
  final int maxHp;
  final int hp;
  final int baseAttack;
  final int baseDefense;
  final int baseMoveRange;
  final int attackRange;
  final List<UnitAbility> abilities;
  final bool hasActed;
  final bool revealed;
  final bool alive;
  final bool isReinforcement;

  const Unit({
    required this.id,
    required this.name,
    required this.side,
    required this.col,
    required this.row,
    required this.maxHp,
    required this.hp,
    required this.baseAttack,
    required this.baseDefense,
    required this.baseMoveRange,
    required this.attackRange,
    this.abilities = const [],
    this.hasActed = false,
    this.revealed = false,
    this.alive = true,
    this.isReinforcement = false,
  });

  // 工厂：新建正常单位（hp=maxHp）
  factory Unit.create({
    required int id,
    required String name,
    required Side side,
    required int col,
    required int row,
    required int maxHp,
    required int baseAttack,
    required int baseDefense,
    required int baseMoveRange,
    required int attackRange,
    List<UnitAbility> abilities = const [],
    bool revealed = false,
    bool isReinforcement = false,
  }) => Unit(
    id: id,
    name: name,
    side: side,
    col: col,
    row: row,
    maxHp: maxHp,
    hp: maxHp,
    baseAttack: baseAttack,
    baseDefense: baseDefense,
    baseMoveRange: baseMoveRange,
    attackRange: attackRange,
    abilities: abilities,
    revealed: revealed,
    isReinforcement: isReinforcement,
  );

  // 状态转换方法（不可变）
  Unit moveTo(int newCol, int newRow) =>
      Unit.copy(this, col: newCol, row: newRow);

  Unit takeDamage(int amount) {
    final newHp = max(0, hp - amount);
    return Unit.copy(this, hp: newHp, alive: newHp > 0);
  }

  Unit markActed() => Unit.copy(this, hasActed: true);
  Unit reveal() => Unit.copy(this, revealed: true);

  // ... copyWith 私有构造
  static Unit copy(Unit source, {
    int? col, int? row, int? hp, bool? alive,
    bool? hasActed, bool? revealed, bool? isReinforcement,
  }) {
    return Unit(
      id: source.id,
      name: source.name,
      side: source.side,
      col: col ?? source.col,
      row: row ?? source.row,
      maxHp: source.maxHp,
      hp: hp ?? source.hp,
      baseAttack: source.baseAttack,
      baseDefense: source.baseDefense,
      baseMoveRange: source.baseMoveRange,
      attackRange: source.attackRange,
      abilities: source.abilities,
      hasActed: hasActed ?? source.hasActed,
      revealed: revealed ?? source.revealed,
      alive: alive ?? source.alive,
      isReinforcement: isReinforcement ?? source.isReinforcement,
    );
  }
}
```

收益：

· 任何状态改变都会产生新对象，可追踪、可回放。
· Game 类中的战斗方法不再修改单位，而是返回新对象及结果。
· 特技列表为未来扩展留出空间。

—

与主线的连接

Unit 作为最小数据单元，必须配合状态管理。当前设计让 Game 直接修改单位状态，导致了前几轮我们指出的“主线缺失”——因为没有动作记录、没有回合状态，修改单位只是散落在各处的赋值。将 Unit 不可变化后，Game 的流程自然需要演变为：

```dart
(currentUnits, combatResult) = game.resolveCombat(attacker, defender, ...);
```

这样状态的变迁成为显式流，Game 才能演进为我们期望的回合主控。

—

总结

Unit 类结构简单，却因为可变性与类型松散拖累了整体架构。它与 Battlefield 的严谨形成反差，是导致 Game 类“一堆零碎”的直接原因之一。走不可变性路线并强化类型定义，会让整个游戏的逻辑流转变得清晰、可测试，最终为主线的回合调度铺平道路。