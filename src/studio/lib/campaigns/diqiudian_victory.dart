import '../models/game.dart';
import '../models/unit.dart';
import '../models/victory_policy.dart';

/// 帝丘店剧本的胜负策略。
///
/// 四条件（顺序即优先级）：红方全灭胜 → 蓝方占核心且工事归零胜 →
/// 蓝方全灭败 → 超时败。胜文案读注入的 [CampaignConfig]（campaign.json
/// 单一来源），败文案就地声明。超时阈值 `turn > 12` 为随迁魔数，
/// 改读 `config.maxTurns` 归任务 4。
VictoryPolicy diqiudianVictory(CampaignConfig config) {
  return (units, campaign, turn, terrain) {
    if (!units.any((u) => u.alive && u.side == Side.red)) {
      return VictoryResult(true, config.victoryClearedText);
    }
    final coreOccupied = units.any(
      (u) =>
          u.alive &&
          u.side == Side.blue &&
          terrain.propsAt(u.col, u.row).isCore,
    );
    if (coreOccupied && campaign.fortStrength <= 0) {
      return VictoryResult(true, config.victoryCoreText);
    }
    if (!units.any((u) => u.alive && u.side == Side.blue)) {
      return const VictoryResult(false, '华野部队已无力再战，帝丘店未能攻克。');
    }
    if (turn > 12) {
      return VictoryResult(
        false,
        '时间耗尽，援军逼近，华野被迫撤出战斗。',
        dispatches: [Dispatch('\u{1F480}时间耗尽，未能攻克帝丘店。', 'urgent', turn)],
      );
    }
    return null;
  };
}
