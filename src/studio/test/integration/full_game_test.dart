import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio/campaigns/diqiudian_victory.dart';
import 'package:studio/controllers/game_controller.dart';
import 'package:studio/models/game.dart';
import 'package:studio/screens/headquarters_screen.dart';

/// 整局可玩性检验（种子批版）：机器扮演玩家走真实交互路径——
/// 点强攻卡 → 结束回合 → 循环，直到结算。
///
/// 用真实帝丘店资产起局（rootBundle 加载 pubspec 壳内三份 JSON）。
/// 断言：**至少存在一个胜种子**（赢的路可达）——数值改动导致全败时变红。
/// 整局打完、结算弹窗与重开另有单局测试在下方。
const _seeds = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233];

/// 真实资产进程内只加载一次：rootBundle 在同一测试进程第二次 load 会永久挂起，
/// 且跨 testWidgets await 缓存 Future 同样挂——所以缓存解析后的值本身。
CampaignConfig? _config;

Future<GameController> _playBot(WidgetTester tester, int seed) async {
  final config = _config ??= await CampaignConfig.load('diqiudian');
  final controller = GameController(
    Game(config, victoryPolicy: diqiudianVictory(config)),
    rng: Random(seed),
    aiDelay: Duration.zero,
  );
  await tester.pumpWidget(
    MaterialApp(home: HeadquartersScreen(controller: controller)),
  );
  var turns = 0;
  while (!controller.state.isGameOver && turns < 40) {
    turns++;
    // 决策卡：全员行动后卡自动禁用，点不动是正常态，继续走回合
    await tester.tap(find.text('⚔ 强攻要塞'), warnIfMissed: false);
    await tester.pump();
    final endBtn = find.text('\u{23ED} 结束回合');
    if (endBtn.evaluate().isEmpty) {
      final texts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '<rich>')
          .toList();
      fail(
        'seed $seed T$turns 结束回合按钮不在：phase=${controller.state.phase} '
        'isGameOver=${controller.state.isGameOver} 屏上文字=$texts',
      );
    }
    await tester.tap(endBtn);
    await tester.pump();
    // 有待令部队时的确认弹窗：bot 信息完备，直接确认
    final confirm = find.text('结束回合');
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    // 清掉决策回执与结算弹窗，避免堆叠
    await tester.pump(const Duration(seconds: 2));
  }
  expect(
    controller.state.isGameOver,
    isTrue,
    reason:
        'seed $seed 应在时限内打完一局（超时判负也算打完）；'
        '实际 T${controller.state.currentTurn} phase=${controller.state.phase}',
  );
  return controller;
}

void main() {
  final results = <int, bool>{};

  for (final seed in _seeds) {
    testWidgets('种子批 seed $seed', (tester) async {
      final controller = await _playBot(tester, seed);
      final won = controller.state.campaign.victory == true;
      results[seed] = won;
      debugPrint(
        'seed $seed: ${won ? '胜' : '败'} T${controller.state.currentTurn}',
      );
      // 冲掉结算弹窗与回执计时器，避免污染下一个测试
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.textContaining('再来一局'), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('断言：至少一个胜种子（赢的路可达），全败即红', (tester) async {
    expect(results.length, _seeds.length, reason: '每种子都应打完一局');
    final wins = results.values.where((w) => w).length;
    final summary = results.entries.map(
      (e) => 's${e.key}:${e.value ? '胜' : '败'}',
    );
    expect(wins, greaterThan(0), reason: '应存在胜种子；实际全败：${summary.join(' ')}');
  });

  testWidgets('结算弹窗与重开：回到第 1 回合玩家阶段', (tester) async {
    final controller = await _playBot(tester, 1);
    await tester.pumpAndSettle();
    expect(find.textContaining('再来一局'), findsOneWidget);
    final titleShown =
        find.textContaining('大捷').evaluate().isNotEmpty ||
        find.textContaining('战役结束').evaluate().isNotEmpty;
    expect(titleShown, isTrue, reason: '结算弹窗应显示胜或负标题');

    await tester.tap(find.textContaining('再来一局'));
    await tester.pumpAndSettle();
    expect(controller.state.currentTurn, 1);
    expect(controller.state.phase, GamePhase.player);
    expect(controller.state.campaign.gameOver, isFalse);
  });
}
