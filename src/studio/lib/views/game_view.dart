import 'package:flutter/material.dart';
import '../controller/game_controller.dart';

class GameView extends StatelessWidget {
  final GameState state;
  final GameController controller;

  const GameView({super.key, required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buttons(context, state),
        const SizedBox(height: 6),
        _log(state),
      ],
    );
  }

  Widget _buttons(BuildContext context, GameState state) {
    final canEnd = state.phase == GamePhase.player && !state.isGameOver;
    return Row(
      children: [
        Expanded(
            child: _styledButton(context,
          '\u23ED 结束回合',
          canEnd ? () => controller.endTurn() : null,
          primary: true,
        )),
        const SizedBox(width: 5),
        Expanded(
            child: _styledButton(context,
          '\u{1F504} 重置',
          () => controller.reset(),
          primary: false,
        )),
      ],
    );
  }

  Widget _styledButton(
      BuildContext context, String text, VoidCallback? onPressed,
      {required bool primary}) {
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
                  color: primary ? const Color(0xffa04030) : const Color(0xffc8bfae)),
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

  Widget _log(GameState state) {
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
}
