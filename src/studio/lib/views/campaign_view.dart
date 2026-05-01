import 'package:flutter/material.dart';
import '../models/campaign.dart';

class CampaignView extends StatelessWidget {
  final Campaign campaign;

  const CampaignView({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
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
          _line('\u23F3邱清泉：',
              campaign.qiuArrived ? '已到达！' : '第${campaign.qiuReinforceTurn}回合', const Color(0xff9e7a40)),
          _line('\u23F3胡琏：',
              campaign.huArrived ? '已到达！' : '第${campaign.huReinforceTurn}回合', const Color(0xff9e7a40)),
          _line('\u26A1华野战力：', campaign.powerDesc, _powerColor(campaign.powerDesc)),
          _line('\u{1F3F0}帝丘店防御：', '坚固(${campaign.fortStrength})', const Color(0xffa04030)),
        ],
      ),
    );
  }

  Widget _line(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 9.5, color: Color(0xff6b6050), fontFamily: 'serif')),
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
}
