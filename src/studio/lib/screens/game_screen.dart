import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_state.dart';
import '../bloc/game_event.dart';
import '../models/battlefield.dart';
import '../models/game.dart';
import '../bloc/game_bloc.dart';
import '../views/battlefield_view.dart';
import '../views/campaign_view.dart';
import '../views/unit_view.dart';
import '../views/game_view.dart';

class CampaignScreen extends StatelessWidget {
  const CampaignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameBloc(Game(Battlefield.createMapTerrain())),
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
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const BattlefieldView(),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 225,
                            child: BlocBuilder<GameBloc, GameState>(
                              builder: (context, state) => _sidePanel(state),
                            ),
                          ),
                        ],
                      ),
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

  Widget _sidePanel(GameState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: const Color(0xfff4efe2),
        border: Border.all(color: const Color(0xffbfb6a5)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.25), blurRadius: 14, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panelTitle(),
          const SizedBox(height: 6),
          _infoRow('当前回合', '第${state.currentTurn}回合 / 12'),
          _infoRow('阶段', state.isGameOver
              ? (state.campaign.victory == true ? '\u{1F3C6}大捷' : '\u{1F480}战败')
              : state.phase == GamePhase.player
                  ? '\u{1F3F4}华野行动'
                  : '\u{1F7E6}国军行动'),
          _infoRow('可行动', '${state.readyPlayerUnits.length}',
              valueColor: state.readyPlayerUnits.isNotEmpty ? const Color(0xff5a7a4a) : null),
          const SizedBox(height: 5),
          CampaignView(campaign: state.campaign),
          const SizedBox(height: 4),
          Expanded(child: UnitView(state: state)),
          const SizedBox(height: 5),
          GameView(state: state),
          const SizedBox(height: 4),
          _legend(),
        ],
      ),
    );
  }

  Widget _panelTitle() {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffc8bfae))),
      ),
      child: const Text('\u{1F4CB} 华野司令部',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff2c2416), fontFamily: 'serif', letterSpacing: 1.0)),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.06), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xff6b6050))),
          Text(value,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'serif',
                  color: valueColor ?? const Color(0xff2c2416))),
        ],
      ),
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 6, runSpacing: 2,
      children: [
        _legendItem(const Color(0xffb8a068), '平原'),
        _legendItem(const Color(0xff7a8a6a), '村庄'),
        _legendItem(const Color(0xff5a4a3a), '城镇'),
        _legendItem(const Color(0xff3a5a7a), '河流'),
        _legendItem(const Color(0xff3a1a1a), '核心'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, border: Border.all(color: const Color(0xff777777)), borderRadius: BorderRadius.circular(1))),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 7.5, color: Color(0xff999999), fontFamily: 'serif')),
      ],
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
