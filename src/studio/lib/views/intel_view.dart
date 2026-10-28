import 'package:flutter/material.dart';

class IntelView extends StatelessWidget {
  final Set<String> adoptedIntel;
  final ValueChanged<String> onToggleIntel;

  const IntelView({
    super.key,
    required this.adoptedIntel,
    required this.onToggleIntel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
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
          _card('intel1', '确凿', 'confirmed', '📡 区兵团电：\n"沿睢杞大道西进，预计明日抵杞县以东"', '26日20:10'),
          const SizedBox(height: 4),
          _card('intel2', '确凿', 'confirmed', '📡 蒋令破译：\n"邱、区东西对进，在睢杞夹击共军"', '26日22:30'),
          const SizedBox(height: 4),
          _card('intel3', '推测', 'speculated', '👁 骑侦：\n睢县西北10km发现敌行军纵队', '26日18:30'),
          const SizedBox(height: 4),
          _card('intel4', '推测', 'speculated', '👂 百姓口述：\n睢县有汽车电台，龙王店大量敌军', ''),
          const SizedBox(height: 4),
          _card('intel5', '存疑', 'doubtful', '❓ 黄百韬、胡琏动向：\n无任何情报', ''),
          const SizedBox(height: 6),
          _adoptedPanel(),
        ],
      ),
    );
  }

  Widget _title() {
    return const Text('情 报 看 板',
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'serif',
            color: Color(0xff2c2416)));
  }

  Widget _card(String id, String badge, String type, String text, String time) {
    final adopted = adoptedIntel.contains(id);
    Color borderColor;
    Color badgeBg;
    Color badgeFg;
    switch (type) {
      case 'confirmed':
        borderColor = const Color(0xff3d7a3d);
        badgeBg = const Color(0xffd4ead4);
        badgeFg = const Color(0xff2d5a2d);
        break;
      case 'speculated':
        borderColor = const Color(0xffb8922e);
        badgeBg = const Color(0xfff0e4c0);
        badgeFg = const Color(0xff6b4e18);
        break;
      default:
        borderColor = const Color(0xff7a7a7a);
        badgeBg = const Color(0xffe0e0e0);
        badgeFg = const Color(0xff555555);
    }
    return GestureDetector(
      onTap: () => onToggleIntel(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: adopted ? const Color(0xfffaf3e0) : const Color(0xfff4efe2),
          border: Border(
            left: BorderSide(color: adopted ? borderColor : borderColor.withValues(alpha: 0.4), width: 3),
            top: const BorderSide(color: Color(0xffd8c8a8)),
            right: const BorderSide(color: Color(0xffd8c8a8)),
            bottom: const BorderSide(color: Color(0xffd8c8a8)),
          ),
          boxShadow: adopted
              ? [BoxShadow(color: borderColor.withValues(alpha: 0.15), blurRadius: 6)]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(badge,
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: badgeFg)),
                      ),
                      if (time.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(time,
                            style: const TextStyle(
                                fontSize: 8, color: Color(0xff8a7a60))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(text,
                      style: const TextStyle(
                          fontSize: 9.5, color: Color(0xff2c2416), height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: adopted ? const Color(0xff5a3a1c) : Colors.transparent,
                border: Border.all(color: const Color(0xff8a7a50)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: adopted
                  ? const Icon(Icons.check, size: 10, color: Color(0xfff2e8d5))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _adoptedPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(20, 10, 4, 0.8),
        border: Border.all(color: const Color(0xff4a3020)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 我采信的情报',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffd4c090))),
          const SizedBox(height: 4),
          if (adoptedIntel.isEmpty)
            const Text('尚未采信',
                style: TextStyle(fontSize: 9, color: Color(0xff8a7050)))
          else
            ...adoptedIntel.map((id) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('- ${_label(id)}',
                  style: const TextStyle(
                      fontSize: 8.5, color: Color(0xffc8b080))),
            )),
        ],
      ),
    );
  }

  String _label(String id) {
    switch (id) {
      case 'intel1': return '区兵团沿睢杞大道西进';
      case 'intel2': return '蒋令邱区东西对进';
      case 'intel3': return '睢县西北发现敌行军';
      case 'intel4': return '睢县龙王店有敌军';
      case 'intel5': return '黄百韬胡琏不明';
      default: return id;
    }
  }
}
