import '../models/battlefield.dart';
import '../models/campaign.dart';
import '../models/command.dart';
import '../models/game.dart';
import '../models/task.dart';
import '../models/unit.dart';

/// Task → Command 翻译层。
///
/// 纯函数：不掷骰、不改状态。把一组「纵队 → Task 姿态」在当前战场态势下
/// 具体化为带坐标的 Command 列表，交给引擎执行。见 `doc/models/command.md`。
///
/// 规则：
///  1. 定目标：攻城档位 → 要塞格，阻援档位 → 援军格，待命 → hold。
///  2. 选移动：可达格中取距目标 hexDistance 最小者；已邻接则原地；无路 → 留原地。
///  3. 选攻击：从落位取射程内一个已暴露、非满掩体隔格的敌军。
List<Command> translateOrders({
  required Map<int, TaskType> assignments,
  required List<Unit> units,
  required Game engine,
  required Campaign campaign,
  required (int, int)? fortPos,
  required (int, int)? reliefPos,
  required int currentTurn,
}) {
  final commands = <Command>[];
  final ids = assignments.keys.toList()..sort();

  for (final id in ids) {
    final task = assignments[id]!;
    final unit = units.cast<Unit?>().firstWhere(
      (u) => u!.id == id,
      orElse: () => null,
    );
    if (unit == null || !unit.alive) continue;

    // 待命：hold，不移动不攻击
    if (task == TaskType.standby) {
      commands.add(_hold(id, task, currentTurn));
      continue;
    }

    // 1. 定目标
    (int, int)? target;
    if (TaskType.assaultTargets.contains(task)) {
      target = fortPos;
    } else if (TaskType.reliefTasks.contains(task)) {
      target = reliefPos;
    }
    if (target == null) {
      commands.add(_hold(id, task, currentTurn));
      continue;
    }

    // 2. 选移动：可达格中距目标最近者；已邻接则原地（moveTo 保持 null）
    final moveRange = engine.getMoveRange(unit, units, campaign);
    final startDist = Battlefield.hexDistance(
      unit.col,
      unit.row,
      target.$1,
      target.$2,
    );
    (int, int)? best;
    var bestDist = startDist;
    for (final key in moveRange.keys) {
      final (c, r) = _parseKey(key);
      final d = Battlefield.hexDistance(c, r, target.$1, target.$2);
      if (d < bestDist) {
        bestDist = d;
        best = (c, r);
      }
    }
    final dest = best ?? (unit.col, unit.row);

    // 3. 选攻击：从落位取射程内一个已暴露、非满掩体隔格的敌军
    final enemy = _pickAttackTarget(dest, unit, units, engine.terrain);

    commands.add(
      Command(
        unitId: id,
        task: task,
        moveTo: best,
        attack: enemy == null ? null : (enemy.col, enemy.row),
        issuedTurn: currentTurn,
        deadlineTurn: currentTurn,
      ),
    );
  }
  return commands;
}

Command _hold(int id, TaskType task, int turn) =>
    Command(unitId: id, task: task, issuedTurn: turn, deadlineTurn: turn);

(int, int) _parseKey(String key) {
  final i = key.indexOf(',');
  return (int.parse(key.substring(0, i)), int.parse(key.substring(i + 1)));
}

Unit? _pickAttackTarget(
  (int, int) from,
  Unit unit,
  List<Unit> units,
  TerrainBook book,
) {
  Unit? best;
  var bestDist = 1 << 30;
  for (final e in units) {
    if (!e.alive || e.side != Side.red || !e.revealed) continue;
    final d = Battlefield.hexDistance(from.$1, from.$2, e.col, e.row);
    if (d > unit.type.attackRange) continue;
    if (book.propsAt(e.col, e.row).fullCover && d > 1) continue;
    if (d < bestDist) {
      bestDist = d;
      best = e;
    }
  }
  return best;
}
