import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/game_state.dart';
import '../models/game_event.dart';
import '../bloc/game_bloc.dart';

class CommandPanel extends StatelessWidget {
  const CommandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        final campaign = state.campaign;
        return Container(
          width: 225,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xfff4efe2),
            border: Border.all(color: const Color(0xffbfb6a5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\u{1F4CB} 华野司令部',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff2c2416))),
              const Divider(height: 12),
              _infoRow('当前回合', '第${state.currentTurn}回合 / 12'),
              _infoRow('阶段', state.isGameOver
                  ? (campaign.victory == true ? '\u{1F3C6} 战役结束' : '\u{1F480} 战役结束')
                  : state.phase == GamePhase.player
                      ? '\u{1F3F4} 华野行动'
                      : '\u{1F7E6} 国军行动中\u2026'),
              _infoRow('可行动', state.readyPlayerUnits.length.toString(),
                  color: state.readyPlayerUnits.isNotEmpty ? const Color(0xff5a7a4a) : null),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(160, 64, 48, 0.04),
                  border: Border.all(color: const Color.fromRGBO(160, 64, 48, 0.15)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _campaignRow('\u{1F3AF} 目标', '\u26A0攻占帝丘店', const Color(0xffa04030)),
                    _campaignRow('\u23F3 邱清泉',
                        campaign.qiuArrived ? '已到达！' : '第${campaign.qiuReinforceTurn}回合', const Color(0xff9e7a40)),
                    _campaignRow('\u23F3 胡琏',
                        campaign.huArrived ? '已到达！' : '第${campaign.huReinforceTurn}回合', const Color(0xff9e7a40)),
                    _campaignRow('\u26A1 华野战力', campaign.powerDesc, _powerColor(campaign.powerDesc)),
                    _campaignRow('\u{1F3F0} 帝丘店防御', '坚固(${campaign.fortStrength})', const Color(0xffa04030)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(child: _unitCards(context, state)),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (state.phase != GamePhase.player || state.isGameOver)
                          ? null
                          : () => context.read<GameBloc>().add(const EndTurn()),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: const Color.fromRGBO(160, 64, 48, 0.1),
                      ),
                      child: const Text('\u23ED 结束回合', style: TextStyle(fontSize: 11, color: Color(0xff5a2020))),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.read<GameBloc>().add(const ResetGame()),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                      child: const Text('\u{1F504} 重置', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _logArea(state),
              const SizedBox(height: 4),
              _legend(),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xff6b6050))),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color ?? const Color(0xff2c2416),
                  fontFamily: 'serif')),
        ],
      ),
    );
  }

  Widget _campaignRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xff6b6050))),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color, fontFamily: 'serif')),
        ],
      ),
    );
  }

  Color _powerColor(String desc) {
    switch (desc) {
      case '充沛':
        return const Color(0xff5a7a4a);
      case '吃紧':
      case '濒临极限':
        return const Color(0xffa04030);
      default:
        return const Color(0xff9e7a40);
    }
  }

  Widget _unitCards(BuildContext context, GameState state) {
    return ListView(
      children: state.playerUnits.map((u) {
        final selected = u.id == state.selectedUnitId;
        return GestureDetector(
          onTap: u.hasActed
              ? null
              : () => context.read<GameBloc>().add(SelectUnit(u.id)),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? const Color(0xffc9a96e) : const Color(0xffc8bfae)),
              color: selected ? const Color.fromRGBO(201, 169, 110, 0.07) : null,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff4a3020),
                    border: Border.all(color: const Color(0xffc44b3c)),
                  ),
                  child: Center(
                    child: Text(
                      u.special == 'assault' ? '\u26A1' : u.attackRange >= 2 ? '\u25C8' : '\u25C6',
                      style: const TextStyle(color: Color(0xfff0c0a0), fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${u.name}${u.hasActed ? ' (\u2713)' : ''}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              color: u.hasActed ? const Color(0xff6b6050) : const Color(0xff2c2416))),
                      Text('攻${u.baseAttack} 防${u.baseDefense} 移${u.baseMoveRange} 射${u.attackRange}',
                          style: const TextStyle(fontSize: 8, color: Color(0xff6b6050))),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(u.maxHp, (i) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < u.hp ? const Color(0xffc44b3c) : const Color(0xffd5cfc5),
                      border: Border.all(color: i < u.hp ? const Color(0xff802020) : const Color(0xffb0a898)),
                    ),
                  )),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _logArea(GameState state) {
    final recent = state.logMessages.length > 8
        ? state.logMessages.sublist(state.logMessages.length - 8)
        : state.logMessages;
    return Container(
      constraints: const BoxConstraints(maxHeight: 100),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.025),
        border: Border.all(color: const Color(0xffc8bfae)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: ListView(
        children: recent.map((l) {
          Color c;
          switch (l.type) {
            case 'hit':
              c = const Color(0xffa04030);
              break;
            case 'urgent':
              c = const Color(0xff6b3020);
              break;
            case 'info':
              c = const Color(0xff5a7a4a);
              break;
            default:
              c = const Color(0xff6b6050);
          }
          return Text('[T${l.turn}] ${l.msg}',
              style: TextStyle(fontSize: 8, color: c, fontFamily: 'serif'));
        }).toList(),
      ),
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
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
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, border: Border.all(color: Colors.grey))),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 8, color: Color(0xff999999))),
      ],
    );
  }
}
