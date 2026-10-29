import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio/campaigns/diqiudian_victory.dart';
import 'package:studio/controllers/game_controller.dart';
import 'package:studio/models/game.dart';
import 'package:studio/screens/headquarters_screen.dart';

/// 整局可玩性检验：机器扮演玩家走真实交互路径——
/// 点决策卡 → 点结束回合 → 循环，直到结算弹窗出现。
///
/// 用真实帝丘店资产（rootBundle 加载 pubspec 壳内三份 JSON），
/// 注入零时长 AI 与固定种子保证确定性。只验「一局能打完」，
/// 不断胜负（胜负分布是种子批的事，未做）。
void main() {
  testWidgets('强攻 bot 能打完整局到结算弹窗', (tester) async {
    final config = await CampaignConfig.load('diqiudian');
    final controller = GameController(
      Game(config, victoryPolicy: diqiudianVictory(config)),
      rng: Random(1),
      aiDelay: Duration.zero,
    );
    await tester.pumpWidget(
      MaterialApp(home: HeadquartersScreen(controller: controller)),
    );
    expect(controller.state.phase, GamePhase.player);
    expect(find.text('⚔ 强攻要塞'), findsOneWidget);

    var turns = 0;
    while (!controller.state.isGameOver && turns < 40) {
      turns++;
      // 决策卡：全员行动后卡自动禁用，点不动是正常态，继续走回合
      await tester.tap(find.text('⚔ 强攻要塞'), warnIfMissed: false);
      await tester.pump();
      // 结束回合：触发 endTurn → aiDelay(zero) 定时器 → _aiStep
      await tester.tap(find.text('⏭ 结束回合'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      // 未结束时清掉决策回执，避免堆叠
      await tester.pump(const Duration(seconds: 2));
    }

    expect(
      controller.state.isGameOver,
      isTrue,
      reason: 'bot 应在时限内打完一局（超时判负也算打完）；实际跑 $turns 回合仍未结束',
    );
    expect(controller.state.currentTurn, lessThanOrEqualTo(14));

    await tester.pumpAndSettle();
    expect(find.textContaining('再来一局'), findsOneWidget);
    final titleShown =
        find.textContaining('大捷').evaluate().isNotEmpty ||
        find.textContaining('战役结束').evaluate().isNotEmpty;
    expect(titleShown, isTrue, reason: '结算弹窗应显示胜或负标题');

    // 重开：回到第 1 回合、玩家阶段
    await tester.tap(find.textContaining('再来一局'));
    await tester.pumpAndSettle();
    expect(controller.state.currentTurn, 1);
    expect(controller.state.phase, GamePhase.player);
    expect(controller.state.campaign.gameOver, isFalse);
  });
}
