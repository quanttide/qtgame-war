import 'package:flutter/material.dart';
import '../models/game.dart';
import '../controllers/game_controller.dart';
import '../views/battlefield_view.dart';
import '../views/intel_view.dart';
import '../views/plan_view.dart';

class HeadquartersScreen extends StatefulWidget {
  final GameController? controller;

  const HeadquartersScreen({super.key, this.controller});

  @override
  State<HeadquartersScreen> createState() => _HeadquartersScreenState();
}

class _HeadquartersScreenState extends State<HeadquartersScreen> {
  GameController? _controller;
  final Set<String> _adoptedIntel = {'intel1', 'intel2'};
  String _selectedPlanId = 'A';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.controller != null) {
      widget.controller!.addListener(_onGameStateChanged);
      setState(() => _controller = widget.controller);
      return;
    }
    final config = await CampaignConfig.load('diqiudian');
    final controller = GameController(Game(config));
    controller.addListener(_onGameStateChanged);
    setState(() => _controller = controller);
  }

  void _onGameStateChanged() {
    final c = _controller;
    if (c == null) return;
    if (c.state.isGameOver) {
      final campaign = c.state.campaign;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xff1a1814),
          title: Text(
            campaign.victory == true ? '\u{1F3C6} 大捷！' : '\u{1F480} 战役结束',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: campaign.victory == true
                  ? const Color(0xfff0c040)
                  : const Color(0xffc0b090),
              fontFamily: 'serif',
            ),
          ),
          content: Text(
            campaign.victoryDetail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xffc0b090), fontFamily: 'serif'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                c.reset();
              },
              child: const Text('\u{1F504} 再来一局',
                  style: TextStyle(color: Color(0xffc9a96e))),
            ),
          ],
        ),
      );
    }
  }

  void _toggleIntel(String id) {
    setState(() {
      if (_adoptedIntel.contains(id)) {
        _adoptedIntel.remove(id);
      } else {
        _adoptedIntel.add(id);
      }
    });
  }

  void _selectPlan(String id) {
    if (_controller!.state.isGameOver) return;
    setState(() => _selectedPlanId = id);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onGameStateChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(
        backgroundColor: Color(0xff1e1c17),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        return Scaffold(
          backgroundColor: const Color(0xff1e1c17),
          body: SafeArea(
            child: Column(
              children: [
                _titleBar(state),
                const Divider(height: 1, color: Color(0xff3a2010)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          IntelView(
                            adoptedIntel: _adoptedIntel,
                            onToggleIntel: _toggleIntel,
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 572,
                            child: BattlefieldView(controller: controller),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 260,
                            child: PlanView(
                              selectedPlanId: _selectedPlanId,
                              onSelectPlan: _selectPlan,
                              state: state,
                              controller: controller,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xff3a2010)),
                _bottomBar(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _titleBar(GameState state) {
    final config = _controller!.engine.config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xff1a1008),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\u2694\uFE0F ${config.name}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xffc9a96e),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
              Text(
                '${config.date} \u00B7 ${config.description}',
                style: const TextStyle(fontSize: 10, color: Color(0xff988878)),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: state.phase == GamePhase.player
                  ? const Color.fromRGBO(160, 64, 48, 0.2)
                  : const Color.fromRGBO(60, 80, 120, 0.2),
              border: Border.all(
                color: state.phase == GamePhase.player
                    ? const Color(0xff8b3030)
                    : const Color(0xff3a5a7a),
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              state.phase == GamePhase.player ? '决 策 中' : '执 行 中',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: state.phase == GamePhase.player
                    ? const Color(0xffe8b0b0)
                    : const Color(0xff80a0c0),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ...state.playerUnits.take(5).map((u) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _signalDot(u.type.name, u.hasActed ? 'gray' : 'green'),
          )),
          const Spacer(),
          Text(
            '回合 ${state.currentTurn} / ${_controller!.engine.config.maxTurns}',
            style: const TextStyle(fontSize: 11, color: Color(0xff8a7a50)),
          ),
        ],
      ),
    );
  }

  Widget _signalDot(String label, String status) {
    Color c;
    switch (status) {
      case 'green':
        c = const Color(0xff5a9a5a);
        break;
      case 'yellow':
        c = const Color(0xffc8a030);
        break;
      case 'red':
        c = const Color(0xffa04040);
        break;
      default:
        c = const Color(0xff555555);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c, boxShadow: [
            BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 4),
          ]),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: Color(0xffb8a080), fontFamily: 'serif')),
      ],
    );
  }

  Widget _bottomBar(GameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xff1a1008),
      child: Row(
        children: [
          const Text('通 信 科',
              style: TextStyle(fontSize: 9, color: Color(0xff8a7050), fontFamily: 'serif')),
          const SizedBox(width: 12),
          _commUnit('军委台', 'green'),
          const SizedBox(width: 8),
          _commUnit('1纵', 'green'),
          const SizedBox(width: 8),
          _commUnit('6纵', 'yellow'),
          const SizedBox(width: 8),
          _commUnit('中野11纵', 'red'),
        ],
      ),
    );
  }

  Widget _commUnit(String label, String status) {
    Color c;
    switch (status) {
      case 'yellow':
        c = const Color(0xffc8a030);
        break;
      case 'red':
        c = const Color(0xffa04040);
        break;
      default:
        c = const Color(0xff5a9a5a);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.4),
        border: Border.all(color: const Color(0xff3a2818)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c, boxShadow: [
              BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 3),
            ]),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: Color(0xffb8a080), fontFamily: 'serif')),
        ],
      ),
    );
  }
}
