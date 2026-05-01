import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_state.dart';
import '../bloc/game_event.dart';
import '../models/battlefield.dart';
import '../models/game_engine.dart';
import '../bloc/game_bloc.dart';
import 'game_board.dart';
import 'command_panel.dart';

class CampaignScreen extends StatelessWidget {
  const CampaignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameBloc(GameEngine(Battlefield.createMapTerrain())),
      child: BlocListener<GameBloc, GameState>(
        listener: (context, state) {
          if (state.isGameOver) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xff1a1814),
                title: Text(
                  state.campaign.victory == true ? '\u{1F3C6} 大捷！' : '\u{1F480} 战役结束',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: state.campaign.victory == true ? const Color(0xfff0c040) : const Color(0xffc0b090),
                    fontFamily: 'serif',
                  ),
                ),
                content: Text(
                  state.campaign.victoryDetail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xffc0b090), fontFamily: 'serif'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.read<GameBloc>().add(const ResetGame());
                    },
                    child: const Text('\u{1F504} 再来一局',
                        style: TextStyle(color: Color(0xffc9a96e))),
                  ),
                ],
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xff1e1c17),
          body: SafeArea(
            child: Column(
              children: [
                _titleBar(),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GameBoard(),
                        const SizedBox(width: 12),
                        const SizedBox(width: 225, child: CommandPanel()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _titleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Text(
            '\u2694\uFE0F 帝丘店 \u00B7 豫东战役第三阶段',
            style: TextStyle(
              fontSize: 18,
              color: const Color(0xffc9a96e),
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
              shadows: [Shadow(color: const Color(0xffc9a96e).withValues(alpha: 0.45), blurRadius: 18)],
            ),
          ),
          const Text(
            '1948年7月2-6日 \u00B7 华野围攻黄百韬兵团 \u00B7 邱清泉胡琏紧急驰援',
            style: TextStyle(fontSize: 11, color: Color(0xff988878)),
          ),
        ],
      ),
    );
  }
}
