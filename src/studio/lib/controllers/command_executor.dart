import '../models/command.dart';
import '../models/game.dart';
import '../models/unit.dart';
import 'game_controller.dart';

/// CommandExecutor：命令序列 → 引擎原语 → 战报。
///
/// 守卫（不在场/已亡/不归我方/已行动/过期/空令）集中在本类，
/// 调用方不再各自内联复制。执行复用 `GameController.applyMove` /
/// `applyAttack`（领域口子，不依赖点击态）。见 `doc/models/command.md`。
class CommandExecutor {
  final GameController controller;

  const CommandExecutor(this.controller);

  /// 执行一批命令，返回汇总战报。逐条独立：一条失败不影响其余。
  List<Dispatch> executeAll(List<Command> commands) {
    final report = <Dispatch>[];
    for (final cmd in commands) {
      report.addAll(executeOne(cmd));
    }
    if (report.isNotEmpty) {
      controller.state.logMessages = [
        ...controller.state.logMessages,
        ...report,
      ];
      controller.notifyChanged();
    }
    return report;
  }

  /// 执行单条命令，返回它的战报片段（守卫拒绝或空令时为空列表）。
  List<Dispatch> executeOne(Command cmd) {
    final state = controller.state;

    // 守卫：过期（跨回合长命令预留，v0.1.0 单回合令不触发）
    if (cmd.deadlineTurn < state.currentTurn) {
      cmd.status = CommandStatus.expired;
      cmd.resultText = '命令已过期';
      return const [];
    }

    // 守卫：不在场 / 已亡 / 不归我方 / 本回合已行动
    final unit = state.units.cast<Unit?>().firstWhere(
      (u) => u!.id == cmd.unitId,
      orElse: () => null,
    );
    if (unit == null || !unit.alive) {
      cmd.status = CommandStatus.blocked;
      cmd.resultText = '受令纵队不在场或已失去战斗力';
      return const [];
    }
    if (unit.side != Side.blue) {
      cmd.status = CommandStatus.blocked;
      cmd.resultText = '该部不归我方指挥';
      return const [];
    }
    if (unit.hasActed) {
      cmd.status = CommandStatus.blocked;
      cmd.resultText = '该部本回合已行动';
      return const [];
    }

    // 空令：只登记姿态，不算行动
    if (!cmd.hasAction) {
      unit.task = cmd.task;
      cmd.status = CommandStatus.executed;
      cmd.resultText = '原地待命';
      return const [];
    }

    // 移动：无路可达则整条拒绝，不再尝试攻击
    final report = <Dispatch>[];
    if (cmd.moveTo != null) {
      final moved = controller.applyMove(unit, cmd.moveTo!.$1, cmd.moveTo!.$2);
      if (!moved.ok) {
        cmd.status = CommandStatus.blocked;
        cmd.resultText = '无路可达';
        return const [];
      }
      report.addAll(moved.dispatches);
    }

    // 攻击：目标格无敌或不在射程均记「落空」；
    // 已移动则移动算数（executed），未移动则整条拒绝
    var ok = cmd.moveTo != null;
    if (cmd.attack != null) {
      final defender = state.units.cast<Unit?>().firstWhere(
        (u) =>
            u!.alive &&
            u.side == Side.red &&
            u.col == cmd.attack!.$1 &&
            u.row == cmd.attack!.$2,
        orElse: () => null,
      );
      final hit = defender == null
          ? const ExecutionResult(false)
          : controller.applyAttack(unit, defender);
      if (hit.ok) {
        ok = true;
        report.addAll(hit.dispatches);
      } else if (cmd.moveTo != null) {
        report.add(
          Dispatch(
            '${unit.type.name} 攻击落空：目标不在射程或已撤离',
            'info',
            state.currentTurn,
          ),
        );
      }
    }

    if (!ok) {
      cmd.status = CommandStatus.blocked;
      cmd.resultText = '目标不在射程';
      return const [];
    }

    unit.task = cmd.task;
    if (!unit.hasActed) unit.markActed(); // 只移动的命令也要收尾
    cmd.status = CommandStatus.executed;
    cmd.resultText = report.map((d) => d.msg).join('；');
    return report;
  }
}
