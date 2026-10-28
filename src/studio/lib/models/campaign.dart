/// 战役运行时状态。
///
/// 记录当前战役的全局动态数值（战力、防御工事、已到达援军、胜负状态）。
/// 字段名保持战役无关（不包含"huaye""diqiudian"等专名），由 [CampaignConfig] 提供初始值。
class Campaign {
  /// 己方综合战力（0-100），影响命中修正和行动消耗
  int playerPower;

  /// 目标防御工事强度，降为 0 且核心格被占则胜利
  int fortStrength;

  /// 援军到达标记，key 为 arrived_flag，value 表示是否已到达
  Map<String, bool> arrived;

  /// 战役是否结束
  bool gameOver;

  /// 胜利标记（null=未结束，true=胜，false=败）
  bool? victory;

  /// 胜负详情文本
  String victoryDetail;

  Campaign({
    this.playerPower = 85,
    this.fortStrength = 3,
    this.gameOver = false,
    this.victory,
    this.victoryDetail = '',
  }) : arrived = {};

  /// 战力描述文本
  String get powerDesc {
    if (playerPower >= 70) return '充沛';
    if (playerPower >= 45) return '尚可';
    if (playerPower >= 25) return '吃紧';
    return '濒临极限';
  }

  /// 基于当前战力的命中修正值
  int get hitMod {
    if (playerPower >= 70) return 5;
    if (playerPower >= 45) return 0;
    if (playerPower >= 25) return -5;
    return -12;
  }

  /// 基于当前战力的移动消耗修正（增加移动力消耗的回合数）
  int get moveMod {
    if (playerPower >= 70) return 0;
    if (playerPower >= 45) return 0;
    if (playerPower >= 25) return 1;
    return 2;
  }
}
