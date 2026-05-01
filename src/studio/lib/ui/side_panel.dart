import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/campaign.dart';
import '../bloc/game_state.dart';
import '../bloc/game_event.dart';
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
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
          decoration: BoxDecoration(
            color: const Color(0xfff4efe2),
            border: Border.all(color: const Color(0xffbfb6a5)),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.25), blurRadius: 14, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTitle(),
              const SizedBox(height: 6),
              _buildInfoRow('当前回合', '第${state.currentTurn}回合 / 12'),
              _buildInfoRow('阶段', state.isGameOver
                  ? (campaign.victory == true ? '\u{1F3C6}大捷' : '\u{1F480}战败')
                  : state.phase == GamePhase.player
                      ? '\u{1F3F4}华野行动'
                      : '\u{1F7E6}国军行动'),
              _buildInfoRow('可行动', '${state.readyPlayerUnits.length}',
                  valueColor: state.readyPlayerUnits.isNotEmpty ? const Color(0xff5a7a4a) : null),
              const SizedBox(height: 5),
              _buildGlobalStatus(campaign),
              const SizedBox(height: 4),
              Expanded(child: _buildUnitCards(context, state)),
              const SizedBox(height: 5),
              _buildButtons(context, state),
              const SizedBox(height: 6),
              _buildLogArea(state),
              const SizedBox(height: 4),
              _buildLegend(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffc8bfae))),
      ),
      child: const Text('\u{1F4CB} 华野司令部',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xff2c2416),
              fontFamily: 'serif',
              letterSpacing: 1.0)),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.06), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xff6b6050))),
          Text(value,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'serif',
                  color: valueColor ?? const Color(0xff2c2416))),
        ],
      ),
    );
  }

  Widget _buildGlobalStatus(Campaign campaign) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(160, 64, 48, 0.04),
        border: Border.all(color: const Color.fromRGBO(160, 64, 48, 0.15)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusLine('\u{1F3AF}目标：', '攻占帝丘店', const Color(0xffa04030)),
          _statusLine('\u23F3邱清泉：',
              campaign.qiuArrived ? '已到达！' : '第${campaign.qiuReinforceTurn}回合', const Color(0xff9e7a40)),
          _statusLine('\u23F3胡琏：',
              campaign.huArrived ? '已到达！' : '第${campaign.huReinforceTurn}回合', const Color(0xff9e7a40)),
          _statusLine('\u26A1华野战力：', campaign.powerDesc, _powerColor(campaign.powerDesc)),
          _statusLine('\u{1F3F0}帝丘店防御：', '坚固(${campaign.fortStrength})', const Color(0xffa04030)),
        ],
      ),
    );
  }

  Widget _statusLine(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xff6b6050), fontFamily: 'serif')),
          Text(value,
              style: TextStyle(
                  fontSize: 9.5, fontWeight: FontWeight.w600, color: valueColor, fontFamily: 'serif')),
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

  Widget _buildUnitCards(BuildContext context, GameState state) {
    return ListView(
      children: state.playerUnits.map((u) {
        final selected = u.id == state.selectedUnitId;
        return GestureDetector(
          onTap: u.hasActed ? null : () => context.read<GameBloc>().add(SelectUnit(u.id)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            decoration: BoxDecoration(
              color: selected
                  ? const Color.fromRGBO(201, 169, 110, 0.07)
                  : const Color.fromRGBO(0, 0, 0, 0.015),
              border: Border.all(
                color: selected ? const Color(0xffc9a96e) : const Color(0xffc8bfae),
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: selected
                  ? [const BoxShadow(color: Color.fromRGBO(201, 169, 110, 0.3), blurRadius: 10)]
                  : null,
            ),
            child: Opacity(
              opacity: u.hasActed ? 0.45 : 1.0,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff4a3020),
                      border: Border.all(color: const Color(0xffc44b3c), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        u.special == 'assault' ? '\u26A1' : u.attackRange >= 2 ? '\u25C8' : '\u25C6',
                        style: const TextStyle(color: Color(0xfff0c0a0), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${u.name}${u.hasActed ? ' (\u2713)' : ''}',
                            style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'serif',
                                color: u.hasActed ? const Color(0xff6b6050) : const Color(0xff2c2416))),
                        Text('攻${u.baseAttack} 防${u.baseDefense} 移${u.baseMoveRange} 射${u.attackRange}',
                            style: const TextStyle(fontSize: 8, color: Color(0xff6b6050), fontFamily: 'serif')),
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButtons(BuildContext context, GameState state) {
    final canEnd = state.phase == GamePhase.player && !state.isGameOver;
    return Row(
      children: [
        Expanded(
          child: _styledButton(
            '\u23ED 结束回合',
            canEnd ? () => context.read<GameBloc>().add(const EndTurn()) : null,
            primary: true,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _styledButton(
            '\u{1F504} 重置',
            () => context.read<GameBloc>().add(const ResetGame()),
            primary: false,
          ),
        ),
      ],
    );
  }

  Widget _styledButton(String text, VoidCallback? onPressed, {required bool primary}) {
    return SizedBox(
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(3),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary
                  ? const Color.fromRGBO(160, 64, 48, 0.1)
                  : const Color.fromRGBO(255, 255, 255, 0.5),
              border: Border.all(
                color: primary ? const Color(0xffa04030) : const Color(0xffc8bfae),
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(text,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    color: primary ? const Color(0xff5a2020) : const Color(0xff2c2416))),
          ),
        ),
      ),
    );
  }

  Widget _buildLogArea(GameState state) {
    final recent = state.logMessages.length > 8
        ? state.logMessages.sublist(state.logMessages.length - 8)
        : state.logMessages;
    return Container(
      constraints: const BoxConstraints(maxHeight: 110),
      padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text('[T${l.turn}] ${l.msg}',
                style: TextStyle(fontSize: 8, color: c, fontFamily: 'serif', height: 1.5)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 6,
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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: const Color(0xff777777)),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 7.5, color: Color(0xff999999), fontFamily: 'serif')),
      ],
    );
  }
}
