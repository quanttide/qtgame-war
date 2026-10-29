import 'package:flutter/material.dart';
import '../campaigns/diqiudian_victory.dart';
import '../models/game.dart';
import '../models/unit.dart';
import '../controllers/game_controller.dart';
import '../views/battlefield_view.dart';
import '../views/commander_view.dart';

class HeadquartersScreen extends StatefulWidget {
  final GameController? controller;

  const HeadquartersScreen({super.key, this.controller});

  @override
  State<HeadquartersScreen> createState() => _HeadquartersScreenState();
}

class _HeadquartersScreenState extends State<HeadquartersScreen> {
  GameController? _controller;

  /// 每次运行只弹一次玩法说明（仅真实启动路径，测试注入控制器不弹）。
  static bool _howToPlayShown = false;

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
    final controller = GameController(
      Game(config, victoryPolicy: diqiudianVictory(config)),
    );
    controller.addListener(_onGameStateChanged);
    setState(() => _controller = controller);
    if (!_howToPlayShown) {
      _howToPlayShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showHowToPlay());
    }
  }

  void _showHowToPlay() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('三分钟会玩'),
        content: const SingleChildScrollView(
          child: Text(
            '1. 这里是指挥官视角：不用逐个摆弄单位，下决策即可。\n\n'
            '2. 点右侧决策卡（强攻 / 阻援 / 休整），全部未行动的纵队立刻执行——'
            '地图上可见各单位移动与交战。每单位每回合一次，动完变灰。\n\n'
            '3. 全部行动完，点底部「结束回合」（有待令部队会先确认），敌军自动行动；'
            '底部战报面板累计每次交战，点棋子可在左侧看部队详情。\n\n'
            '4. 胜利：消灭要塞守军使工事归零后占住要塞格，或歼灭全部敌军；'
            '己方全灭或拖过 12 回合则败。\n\n'
            '提示：也可直接点地图上的己方单位微操（蓝格移动，红框攻击）。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('开始作战'),
          ),
        ],
      ),
    );
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
            style: const TextStyle(
              color: Color(0xffc0b090),
              fontFamily: 'serif',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                c.reset();
              },
              child: const Text(
                '\u{1F504} 再来一局',
                style: TextStyle(color: Color(0xffc9a96e)),
              ),
            ),
          ],
        ),
      );
    }
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
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 572,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: BattlefieldView(
                                      controller: controller,
                                    ),
                                  ),
                                ),
                                _legendStrip(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 240,
                            child: CommanderView(controller: controller),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xff3a2010)),
                _bottomPanels(state),
                _endTurnBar(state),
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
          const Spacer(),
          Text(
            '第 ${state.currentTurn} / ${_controller!.engine.config.maxTurns} 回合',
            style: const TextStyle(fontSize: 12, color: Color(0xffc9a96e)),
          ),
          if (state.phase == GamePhase.player) ...[
            const SizedBox(width: 14),
            Text(
              '${state.playerUnits.where((u) => !u.hasActed).length} 部待令',
              style: const TextStyle(fontSize: 12, color: Color(0xff9a8a70)),
            ),
          ],
        ],
      ),
    );
  }

  /// 图例条：色彩语义按裁决 B——红=我军、蓝=敌军、黄=选中、绿=兵力。
  Widget _legendStrip() {
    Widget chip(Color c, String label) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xff9a8a70),
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
    return Container(
      height: 26,
      color: const Color(0xff1a1008),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          chip(const Color(0xffc44b3c), '我军'),
          chip(const Color(0xff4a80b4), '国军'),
          chip(const Color(0xfff0c040), '选中'),
          chip(const Color(0xff55aa55), '兵力'),
        ],
      ),
    );
  }

  /// 底部信息区：左=选中单位详情，右=战报累计——启用原先的空白区（清单 #7/#8/#12）。
  Widget _bottomPanels(GameState state) {
    return Container(
      height: 140,
      color: const Color(0xff16130e),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 12),
          SizedBox(width: 260, child: _unitDetail(state)),
          const VerticalDivider(width: 12, color: Color(0xff3a2010)),
          Expanded(child: _logPanel(state)),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  /// 单位详情：与地图选中态（黄框）联动，可核验「哪支部队、什么状态」。
  Widget _unitDetail(GameState state) {
    final u = state.selectedUnit;
    if (u == null) {
      return const Center(
        child: Text(
          '点击棋子查看部队详情',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xff8a7a60),
            fontFamily: 'serif',
          ),
        ),
      );
    }
    final sideLabel = u.side == Side.blue ? '我军 · 华野' : '国军';
    final rows = <(String, String)>[
      ('兵力', '${u.hp} / ${u.type.maxHp}'),
      ('疲劳', '${u.fat}'),
      ('姿态', u.task?.label ?? '未受令'),
      ('状态', u.hasActed ? '已行动' : '可行动'),
      ('位置', '(${u.col}, ${u.row})'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${u.type.name} · $sideLabel',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
              color: Color(0xffe8d8b0),
            ),
          ),
          const SizedBox(height: 6),
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      k,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xff8a7a60),
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                  Text(
                    v,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xffc9b896),
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 战报累计面板：最近 7 条滚动可见，交战条目高亮（清单 #8 的一次性文字问题）。
  Widget _logPanel(GameState state) {
    final log = state.logMessages;
    if (log.isEmpty) {
      return const Center(
        child: Text(
          '战报会在这里累计显示',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xff8a7a60),
            fontFamily: 'serif',
          ),
        ),
      );
    }
    final recent = log.length > 7 ? log.sublist(log.length - 7) : log;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      children: [
        for (final d in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              'T${d.turn}  ${d.msg}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'serif',
                color: d.type == 'info'
                    ? const Color(0xffa89a80)
                    : const Color(0xffe8c890),
              ),
            ),
          ),
      ],
    );
  }

  /// 有待令部队时先确认，防止漏下令就结束回合（清单 #9）。
  void _confirmEndTurn() {
    final c = _controller;
    if (c == null) return;
    final ready = c.state.playerUnits.where((u) => !u.hasActed).length;
    if (ready == 0) {
      c.endTurn();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('还有 $ready 部未下令'),
        content: const Text('未下令的部队本回合不会行动。确定结束回合？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('再想想'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              c.endTurn();
            },
            child: const Text('结束回合'),
          ),
        ],
      ),
    );
  }

  Widget _endTurnBar(GameState state) {
    final canEnd = state.phase == GamePhase.player && !state.isGameOver;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xff1a1008),
      child: Center(
        child: SizedBox(
          width: 240,
          child: ElevatedButton(
            onPressed: canEnd ? _confirmEndTurn : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffc9a96e),
              foregroundColor: const Color(0xff2a2010),
              disabledBackgroundColor: const Color(0xff3a2f28),
              disabledForegroundColor: const Color(0xff6a5f50),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              canEnd ? '\u23ED 结束回合' : '敌军行动中…',
              style: const TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
