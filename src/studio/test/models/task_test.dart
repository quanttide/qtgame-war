import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/task.dart';

void main() {
  group('TaskType 规格', () {
    test('七档命令的标签与数值与原型一致', () {
      const expected = {
        TaskType.assault: ('强攻', 0, 2),
        TaskType.siege: ('围困', 0, 0),
        TaskType.feint: ('佯攻', -2, 1),
        TaskType.block: ('正面', 0, 1),
        TaskType.flank: ('侧翼', 0, 1),
        TaskType.lure: ('诱敌', 0, 0),
        TaskType.standby: ('待命', 0, 0),
      };
      expect(TaskType.values.toSet(), expected.keys.toSet());
      for (final e in expected.entries) {
        expect(e.key.label, e.value.$1, reason: '${e.key} label');
        expect(e.key.atkMod, e.value.$2, reason: '${e.key} atkMod');
        expect(e.key.fat, e.value.$3, reason: '${e.key} fat');
      }
    });

    test('战线分组：攻城三档 / 阻援三档 / 恢复一档', () {
      expect(TaskType.assaultTargets, {
        TaskType.assault,
        TaskType.siege,
        TaskType.feint,
      });
      expect(TaskType.reliefTasks, {
        TaskType.block,
        TaskType.flank,
        TaskType.lure,
      });
      expect(TaskType.standbyTasks, {TaskType.standby});
      // 七档不重不漏
      final all = {
        ...TaskType.assaultTargets,
        ...TaskType.reliefTasks,
        ...TaskType.standbyTasks,
      };
      expect(all, TaskType.values.toSet());
    });
  });

  group('slotsFor 角色档位', () {
    test('攻城角色三档：强攻/围困/佯攻', () {
      expect(TaskType.slotsFor(TaskRole.assault), [
        TaskType.assault,
        TaskType.siege,
        TaskType.feint,
      ]);
    });

    test('预备队五档：正面/侧翼/诱敌/待命/强攻', () {
      expect(TaskType.slotsFor(TaskRole.reserve), [
        TaskType.block,
        TaskType.flank,
        TaskType.lure,
        TaskType.standby,
        TaskType.assault,
      ]);
    });

    test('攻城角色不可阻援，预备队可攻城', () {
      expect(
        TaskType.slotsFor(TaskRole.assault).contains(TaskType.block),
        false,
      );
      expect(
        TaskType.slotsFor(TaskRole.reserve).contains(TaskType.assault),
        true,
      );
    });
  });

  group('疲劳规则', () {
    test('阈值 4：3 不受罚，4 起受罚', () {
      expect(TaskType.fatigueThreshold, 4);
      expect(fatiguePenalty(3), 0);
      expect(fatiguePenalty(4), 1);
      expect(fatiguePenalty(6), 1);
    });

    test('待命恢复 2 点且不低于 0', () {
      expect(applyStandbyRecovery(5), 3);
      expect(applyStandbyRecovery(1), 0);
      expect(applyStandbyRecovery(0), 0);
    });
  });
}
