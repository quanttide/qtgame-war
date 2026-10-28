import 'task.dart';

/// 执行状态。
///
/// pending ──执行──> executed（移动且/或攻击完成）
///    ├─无法执行──> blocked（无路可达 或 目标不在射程）
///    └─超时────> expired（deadlineTurn 已过；Phase C3 长命令预留，本版不触发）
enum CommandStatus { pending, executed, blocked, expired }

/// 执行层载体：一个纵队的 Task 姿态在当前战场态势下的具体化。
///
/// 一条 Command = 「先 moveTo，若 attack 非空则再攻击」，对应引擎点击路径
/// 「移动后可攻击」的语义，故不拆成两条。见 `doc/models/command.md`。
class Command {
  /// 受令纵队
  final int unitId;

  /// 溯源：这条命令来自哪个姿态
  final TaskType task;

  /// 移动目标格；null 不移动
  final (int, int)? moveTo;

  /// 攻击目标格；null 不攻击
  final (int, int)? attack;

  /// 下令回合
  final int issuedTurn;

  /// 时限：最迟生效回合。v0.1.0 恒等于 issuedTurn（单回合令）。
  final int deadlineTurn;

  /// 执行状态
  CommandStatus status;

  /// 执行后的战报片段
  String? resultText;

  Command({
    required this.unitId,
    required this.task,
    this.moveTo,
    this.attack,
    required this.issuedTurn,
    required this.deadlineTurn,
    this.status = CommandStatus.pending,
    this.resultText,
  });

  /// 是否含实际动作（移动或攻击），hold 为 false
  bool get hasAction => moveTo != null || attack != null;

  @override
  String toString() =>
      'Command(u$unitId ${task.name} move=$moveTo attack=$attack $status)';
}
