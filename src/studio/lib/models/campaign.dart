class Campaign {
  int huayePower;
  int fortStrength;
  Map<String, bool> arrived;
  bool gameOver;
  bool? victory;
  String victoryDetail;

  Campaign({
    this.huayePower = 85,
    this.fortStrength = 3,
    this.gameOver = false,
    this.victory,
    this.victoryDetail = '',
  }) : arrived = {};

  factory Campaign.fromJson(Map<String, dynamic> json) {
    final camp = Campaign(
      huayePower: json['initial_huaye_power'],
      fortStrength: json['initial_fort_strength'],
    );
    if (json['reinforcements'] != null) {
      for (final r in (json['reinforcements'] as List)) {
        final flag = r['arrived_flag'] as String? ?? '${r['label']}_arrived';
        camp.arrived[flag] = false;
      }
    }
    return camp;
  }

  String get powerDesc {
    if (huayePower >= 70) return '充沛';
    if (huayePower >= 45) return '尚可';
    if (huayePower >= 25) return '吃紧';
    return '濒临极限';
  }

  int get hitMod {
    if (huayePower >= 70) return 5;
    if (huayePower >= 45) return 0;
    if (huayePower >= 25) return -5;
    return -12;
  }

  int get moveMod {
    if (huayePower >= 70) return 0;
    if (huayePower >= 45) return 0;
    if (huayePower >= 25) return 1;
    return 2;
  }
}
