import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio/models/unit.dart';
import 'package:studio/models/combat.dart';
import 'package:studio/models/battlefield.dart';
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
