import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/models/combat.dart';
import 'package:studio/models/battlefield.dart';
import 'package:studio/models/game.dart';
import '../fixtures.dart';

void main() {
  group('Combat', () {
    late TerrainBook book;

    Unit makeAttacker() => Unit(
      id: 1,
      side: Side.blue,
      type: UnitLibrary.lightInfantry,
      col: 0,
      row: 1,
    );
    Unit makeDefender() => Unit(
      id: 2,
      side: Side.red,
      type: UnitLibrary.lightInfantry,
      col: 0,
      row: 2,
      hp: 3,
    );

    setUp(() {
      book = TerrainBook(
        grid: testMapGrid(),
        catalog: testTerrainCatalog,
        cols: 10,
        rows: 7,
      );
    });

    test('resolveCombat returns valid structure', () {
      final result = resolveCombat(
        makeAttacker(),
        makeDefender(),
        book,
        rng: Random(),
        hitMod: 5,
      );
      expect(result.hit, isA<bool>());
      expect(result.damage, greaterThanOrEqualTo(0));
      expect(result.killed, isA<bool>());
      expect(result.text, isA<String>());
    });

    group('applyCombatOutcome 应用原语', () {
      test('落盘：伤害应用到守方、攻方标记已行动、产战报', () {
        final a = makeAttacker();
        final d = makeDefender();
        final result = resolveCombat(
          a,
          d,
          book,
          rng: _ScriptedRandom([39]), // roll=40 → 命中且非重创
          hitMod: 5,
        );
        final dispatch = applyCombatOutcome(
          a,
          d,
          result,
          turn: 7,
          type: 'hit',
        );
        expect(d.hp, 2); // 3 − 1
        expect(a.hasActed, isTrue);
        expect(dispatch.msg, contains('轻步兵'));
        expect(dispatch.msg, contains('命中！'));
        expect(dispatch.type, 'hit');
        expect(dispatch.turn, 7);
      });
    });

    group('战报-落盘核对（桩 rng 三档跑全）', () {
      /// 桩 rng 给定掷骰序列：结算后立即应用原语，返回结算结果供核对。
      CombatResult runWithRoll(List<int> rolls, Unit defender) {
        final a = makeAttacker();
        final result = resolveCombat(
          a,
          defender,
          book,
          rng: _ScriptedRandom(rolls),
          hitMod: 5,
        );
        applyCombatOutcome(a, defender, result, turn: 1, type: 'hit');
        return result;
      }

      test('未命中 ⇒ hp 不变', () {
        final d = makeDefender(); // hp 3
        final r = runWithRoll([99], d); // roll=100 > 72
        expect(r.text, contains('未命中'));
        expect(d.hp, 3);
        expect(d.alive, isTrue);
      });

      test('命中 ⇒ 降 1', () {
        final d = makeDefender(); // hp 3
        final r = runWithRoll([39], d); // roll=40 ∈ (18, 72]
        expect(r.text, contains('命中！'));
        expect(d.hp, 2);
      });

      test('重创 ⇒ 降 2，扣 0 封底', () {
        final d = makeDefender(); // hp 3
        final r = runWithRoll([9], d); // roll=10 ≤ 18
        expect(r.text, contains('重创'));
        expect(d.hp, 1);

        final d1 = Unit(
          id: 3,
          side: Side.blue,
          type: UnitLibrary.lightInfantry,
          col: 0,
          row: 2,
          hp: 1,
        );
        final r1 = runWithRoll([9], d1); // 同掷 10 → 伤害 2 但 hp 1
        expect(r1.text, contains('重创'));
        expect(d1.hp, 0); // 扣 0 封底
        expect(d1.alive, isFalse);
      });
    });

    group('确定性契约', () {
      /// 同一输入序列打 n 轮，记录每轮结算结果。
      List<String> runRounds(int seed) {
        final rng = Random(seed);
        return List.generate(20, (_) {
          final r = resolveCombat(
            makeAttacker(),
            makeDefender(),
            book,
            rng: rng,
            hitMod: 5,
          );
          return '${r.hit}|${r.damage}|${r.killed}|${r.text}';
        });
      }

      test('同种子双跑：结算序列逐项一致', () {
        expect(runRounds(42), equals(runRounds(42)));
      });

      test('不同种子：结算序列允许偏离', () {
        // Random(seed) 是确定性的，两个固定种子的比较结果本身稳定，
        // 20 轮含多次掷骰，全序列相同的概率可忽略。
        expect(runRounds(1), isNot(equals(runRounds(2))));
      });

      test('随机源不被结算层重置：种子 42 的第二轮不等于第一轮', () {
        final rng = Random(42);
        final first = resolveCombat(
          makeAttacker(),
          makeDefender(),
          book,
          rng: rng,
          hitMod: 5,
        );
        final second = resolveCombat(
          makeAttacker(),
          makeDefender(),
          book,
          rng: rng,
          hitMod: 5,
        );
        expect(
          '${first.hit}|${first.damage}|${first.killed}',
          isNot(equals('${second.hit}|${second.damage}|${second.killed}')),
        );
      });
    });
  });
}

/// 桩随机源：按给定序列返回掷骰值，三档核对用。
class _ScriptedRandom implements Random {
  final List<int> _rolls;
  int _i = 0;

  _ScriptedRandom(this._rolls);

  @override
  int nextInt(int max) {
    final v = _rolls[_i];
    _i++;
    return v;
  }

  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => false;
}
