import 'battlefield.dart';
import 'campaign.dart';
import 'game.dart';
import 'unit.dart';

/// 胜负策略判定结果。
///
/// 条件判断与文案（含地名）由剧本策略产出；核心只负责落盘与转发战报。
class VictoryResult {
  /// true=胜，false=败。
  final bool victory;

  /// 胜负详情文案（剧本注入）。
  final String detail;

  /// 策略产出的战报（如超时横幅），由核心调用方入队。
  final List<Dispatch> dispatches;

  const VictoryResult(this.victory, this.detail, {this.dispatches = const []});
}

/// 剧本注入的胜负策略：评估当前态势，返回 null 表示未结束。
///
/// [terrain] 供查询地形属性（如核心据点标记），数据同样来自剧本注入的目录。
typedef VictoryPolicy =
    VictoryResult? Function(
      List<Unit> units,
      Campaign campaign,
      int turn,
      TerrainBook terrain,
    );
