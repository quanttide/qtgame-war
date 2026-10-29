import 'package:flutter/material.dart';
import '../controllers/command_executor.dart';
import '../controllers/command_translator.dart';
import '../controllers/game_controller.dart';
import '../models/game.dart';
import '../models/task.dart';

/// 指挥官决策卡。
///
/// 一键为全部未行动纵队下达同一姿态：经 [translateOrders] 在当前态势下
/// 具体化为带坐标的命令，再由 [CommandExecutor] 执行——玩家下决策，
/// 地图上的单位对应行动，不逐子微操。
class CommanderView extends StatelessWidget {
  final GameController controller;

  const CommanderView({super.key, required this.controller});

  static const List<(TaskType, String, String)> _cards = [
    (TaskType.assault, '⚔ 强攻要塞', '各纵队向要塞推进，攻击守军'),
    (TaskType.siege, '\u{1F6E1} 围困要塞', '推进至要塞外围，压制守军'),
    (TaskType.standby, '\u{1F634} 原地休整', '不行动，恢复疲劳'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final canOrder = state.phase == GamePhase.player && !state.isGameOver;
    final ready = state.playerUnits.where((u) => !u.hasActed).length;
    return Container(
      width: 216,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xfff4efe2),
        border: Border.symmetric(
          vertical: BorderSide(color: Color(0xffbfb6a5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '指 挥 官 决 策',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'serif',
              color: Color(0xff2c2416),
            ),
          ),
          const SizedBox(height: 8),
          for (final (task, title, subtitle) in _cards) ...[
            _DecisionCard(
              title: title,
              subtitle: subtitle,
              enabled: canOrder && ready > 0,
              onTap: canOrder && ready > 0
                  ? () => _issue(context, task, title)
                  : null,
            ),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          Text(
            canOrder ? '$ready 部待令' : '敌军行动中…',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xff8a7a60),
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  void _issue(BuildContext context, TaskType task, String title) {
    final state = controller.state;
    final assignments = <int, TaskType>{
      for (final u in state.playerUnits.where((u) => !u.hasActed)) u.id: task,
    };
    if (assignments.isEmpty) return;
    final commands = translateOrders(
      assignments: assignments,
      units: state.units,
      engine: controller.engine,
      campaign: state.campaign,
      fortPos: _fortPos(),
      reliefPos: null,
      currentTurn: state.currentTurn,
    );
    CommandExecutor(controller).executeAll(commands);
    final done = assignments.length;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title · $done 部已受令'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xff3a2f28),
        ),
      );
  }

  /// 要塞格：地形目录中 isCore 的唯一格（数据来自剧本注入的 catalog）。
  (int, int)? _fortPos() {
    final engine = controller.engine;
    for (var r = 0; r < engine.config.gridRows; r++) {
      for (var c = 0; c < engine.config.gridCols; c++) {
        if (engine.terrain.propsAt(c, r).isCore) return (c, r);
      }
    }
    return null;
  }
}

class _DecisionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _DecisionCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xfffaf6ec),
            border: Border.all(color: const Color(0xffc8b890)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                  color: Color(0xff7a2e20),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xff6b6050),
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
