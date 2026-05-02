import 'package:flutter/material.dart';
import '../controller/game_controller.dart';

class UnitView extends StatelessWidget {
  final GameState state;
  final GameController controller;

  const UnitView({super.key, required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
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
                color: selected ? const Color(0xffc9a96e) : const Color(0xffc8bfae),
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: selected
                  ? [
                      const BoxShadow(
                          color: Color.fromRGBO(201, 169, 110, 0.3),
                          blurRadius: 10)
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
                      border:
                          Border.all(color: const Color(0xffc44b3c), width: 2),
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
                            fontWeight: FontWeight.bold),
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
                                    : const Color(0xff2c2416))),
                        Text(
                            '攻${u.type.baseAttack} 防${u.type.baseDefense} 移${u.type.baseMoveRange} 射${u.type.attackRange}',
                            style: const TextStyle(
                                fontSize: 8,
                                color: Color(0xff6b6050),
                                fontFamily: 'serif')),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(u.type.maxHp, (i) => Container(
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
                                : const Color(0xffb0a898)),
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
}
