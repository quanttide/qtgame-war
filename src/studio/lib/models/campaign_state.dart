class CampaignState {
  int huayePower;
  int fortStrength;
  int qiuReinforceTurn;
  int huReinforceTurn;
  bool qiuArrived;
  bool huArrived;
  bool gameOver;
  bool? victory;
  String victoryDetail;

  CampaignState({
    this.huayePower = 85,
    this.fortStrength = 3,
    this.qiuReinforceTurn = 8,
    this.huReinforceTurn = 7,
    this.qiuArrived = false,
    this.huArrived = false,
    this.gameOver = false,
    this.victory,
    this.victoryDetail = '',
  });

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

  CampaignState copy() {
    return CampaignState(
      huayePower: huayePower,
      fortStrength: fortStrength,
      qiuReinforceTurn: qiuReinforceTurn,
      huReinforceTurn: huReinforceTurn,
      qiuArrived: qiuArrived,
      huArrived: huArrived,
      gameOver: gameOver,
      victory: victory,
      victoryDetail: victoryDetail,
    );
  }
}
