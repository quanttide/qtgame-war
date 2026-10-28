/// 命令档位与疲劳规则。
///
/// 规格来自 `examples/prototype/龙王店战斗.html` 的 `TASK` 表、`slots()`、
/// `resolve()`，逐项等价。见 `doc/models/task.md`。
library;

/// 纵队角色，决定该纵队可用的命令档位。
enum TaskRole { assault, reserve }

/// 七档命令。攻城线打工事，阻援线制整25师推进，standby 恢复疲劳。
enum TaskType {
  assault('强攻', 0, 2),
  siege('围困', 0, 0),
  feint('佯攻', -2, 1),
  block('正面', 0, 1),
  flank('侧翼', 0, 1),
  lure('诱敌', 0, 0),
  standby('待命', 0, 0);

  const TaskType(this.label, this.atkMod, this.fat);

  /// 界面标签
  final String label;

  /// 攻击加值（佯攻打折）
  final int atkMod;

  /// 每回合疲劳增量
  final int fat;

  /// 攻城线：结算时打工事
  static const Set<TaskType> assaultTargets = {assault, siege, feint};

  /// 阻援线：结算时制整25师推进
  static const Set<TaskType> reliefTasks = {block, flank, lure};

  /// 恢复：结算时疲劳 -2
  static const Set<TaskType> standbyTasks = {standby};

  /// 疲劳阈值：fat 达到此值起攻击受罚 1
  static const int fatigueThreshold = 4;

  /// standby 每回合恢复点数
  static const int standbyRecovery = 2;

  /// 角色可用档位，顺序与原型 `slots()` 一致
  static List<TaskType> slotsFor(TaskRole role) => switch (role) {
    TaskRole.assault => [assault, siege, feint],
    TaskRole.reserve => [block, flank, lure, standby, assault],
  };
}

/// 疲劳惩罚：fat ≥ [TaskType.fatigueThreshold] 时为 1，否则 0。
/// 消费方从攻击/佯攻的 diff 中减去该值（原型 `resolve()` 的 `pen`）。
int fatiguePenalty(int fat) => fat >= TaskType.fatigueThreshold ? 1 : 0;

/// standby 恢复：fat - [TaskType.standbyRecovery]，不低于 0。
int applyStandbyRecovery(int fat) {
  final next = fat - TaskType.standbyRecovery;
  return next < 0 ? 0 : next;
}
