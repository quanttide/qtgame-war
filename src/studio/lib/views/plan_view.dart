import 'package:flutter/material.dart';
import '../models/game.dart';
import '../controllers/game_controller.dart';

class PlanView extends StatelessWidget {
  final GameState state;
  final GameController controller;

  const PlanView({super.key, required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xfff4efe2),
        border: Border.symmetric(
          vertical: BorderSide(color: Color(0xffbfb6a5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(),
          const SizedBox(height: 6),
          _campaignView(),
          const SizedBox(height: 8),
          Expanded(child: _unitList()),
          const SizedBox(height: 4),
          _gameControls(context),
          const SizedBox(height: 4),
          _legend(),
        ],
      ),
    );
  }

  Widget _title() {
    return const Text(
      '战 况',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        fontFamily: 'serif',
        color: Color(0xff2c2416),
      ),
    );
  }

  Widget _campaignView() {
    final campaign = state.campaign;
    final waves = controller.engine.config.reinforcementWaves;
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
          _line('\u{1F3AF}目标：', '攻占帝丘店', const Color(0xffa04030)),
          ...waves.map(
            (w) => _line(
              '\u23F3${w.name}：',
              campaign.arrived[w.arrivedFlag] == true ? '已到达！' : '第${w.turn}回合',
              const Color(0xff9e7a40),
            ),
          ),
          _line(
            '\u26A1华野战力：',
            campaign.powerDesc,
            _powerColor(campaign.powerDesc),
          ),
          _line(
            '\u{1F3F0}帝丘店防御：',
            '坚固(${campaign.fortStrength})',
            const Color(0xffa04030),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xff6b6050),
              fontFamily: 'serif',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: valueColor,
              fontFamily: 'serif',
            ),
          ),
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

  Widget _unitList() {
    return ListView(
      children: state.playerUnits.map((u) {
        final selected = u.id == state.selectedUnitId;
        return GestureDetector(
          onTap: u.hasActed ? null : () => controller.selectUnit(u.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            decoration: BoxDecoration(
              color: selected
                  ? const Color.fromRGBO(201, 169, 110, 0.07)
                  : const Color.fromRGBO(0, 0, 0, 0.015),
              border: Border.all(
                color: selected
                    ? const Color(0xffc9a96e)
                    : const Color(0xffc8bfae),
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: selected
                  ? [
                      const BoxShadow(
                        color: Color.fromRGBO(201, 169, 110, 0.3),
                        blurRadius: 10,
                      ),
                    ]
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
                      border: Border.all(
                        color: const Color(0xffc44b3c),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        u.type.isAssault
                            ? '\u26A1'
                            : u.type.attackRange >= 2
                            ? '\u25C8'
                            : '\u25C6',
                        style: const TextStyle(
                          color: Color(0xfff0c0a0),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${u.type.name}${u.hasActed ? ' (\u2713)' : ''}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'serif',
                            color: u.hasActed
                                ? const Color(0xff6b6050)
                                : const Color(0xff2c2416),
                          ),
                        ),
                        Text(
                          '攻${u.type.baseAttack} 防${u.type.baseDefense} 移${u.type.baseMoveRange} 射${u.type.attackRange}',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Color(0xff6b6050),
                            fontFamily: 'serif',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      u.type.maxHp,
                      (i) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < u.hp
                              ? const Color(0xffc44b3c)
                              : const Color(0xffd5cfc5),
                          border: Border.all(
                            color: i < u.hp
                                ? const Color(0xff802020)
                                : const Color(0xffb0a898),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _gameControls(BuildContext context) {
    return Column(
      children: [_buttons(context), const SizedBox(height: 6), _log()],
    );
  }

  Widget _buttons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _styledButton(
            '\u{1F504} 重置',
            () => controller.reset(),
            primary: false,
          ),
        ),
      ],
    );
  }

  Widget _styledButton(
    String text,
    VoidCallback? onPressed, {
    required bool primary,
  }) {
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
                color: primary
                    ? const Color(0xffa04030)
                    : const Color(0xffc8bfae),
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'serif',
                color: primary
                    ? const Color(0xff5a2020)
                    : const Color(0xff2c2416),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _log() {
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
            child: Text(
              '[T${l.turn}] ${l.msg}',
              style: TextStyle(
                fontSize: 8,
                color: c,
                fontFamily: 'serif',
                height: 1.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _legend() {
    final catalog = controller.engine.terrain.catalog;
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: catalog.values
          .map((p) => _legendItem(Color(p.color), p.name))
          .toList(),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 7.5,
            color: Color(0xff999999),
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }
}
