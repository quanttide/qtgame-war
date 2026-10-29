# Game 模块

## 职责

纯查询 + 工具方法，不持有状态，不管理回合。`GameController` 持有 `GameState` 并调用 `Game` 的方法。

## 方法

| 方法 | 输入 | 输出 |
|------|------|------|
| `getMoveRange` | unit, allUnits, campaign | `Map<String, int>` 可达位置 → 剩余移动力 |
| `getAttackTargets` | unit, allUnits | `Set<String>` 可攻击位置 |
| `spawnReinforcements` | units, campaign, turn | `(List<Unit>, List<Dispatch>)` |
| `checkVictory` | units, campaign, turn | `List<Dispatch>`（调注入策略并落盘） |
| `getUnitAt` | col, row, units | `Unit?` |
| `createInitialUnits` | — | `List<Unit>` |

## 胜负策略注入

胜负条件与文案是剧本资产，核心不预设。`Game` 构造时收 `required VictoryPolicy victoryPolicy`（形状定义在 `victory_policy.dart`，帝丘店实现在 `lib/campaigns/diqiudian_victory.dart`）：

- `VictoryPolicy = VictoryResult? Function(List<Unit>, Campaign, int turn, TerrainBook)` —— `null` = 未结束；`terrain` 供查询地形属性（如核心据点标记），数据同样来自剧本注入的目录
- `VictoryResult{victory, detail, dispatches}` —— 条件判断与文案（含地名）归剧本策略；状态落盘（`gameOver/victory/victoryDetail`）与战报返回归 `checkVictory`
- `campaign.gameOver` 已置位时 `checkVictory` 不再评估，直接返回空

## CampaignConfig

所有剧本数据通过 `CampaignConfig` 注入：

| 字段 | 类型 | 来源 |
|------|------|------|
| `mapTerrain` | `List<List<TerrainType>>` | `map.json` |
| `templates` | `Map<String, UnitType>` | `units.json` |
| `initialUnits` | `List<UnitSpec>` | `units.json` |
| `reinforcementWaves` | `List<ReinforcementWave>` | `campaign.json` |
| `maxTurns` | `int` | `campaign.json` |
| `initialPlayerPower` | `int` | `campaign.json` |
| `initialFortStrength` | `int` | `campaign.json` |

## 变更记录

- `getMoveRange` 签名带 `Campaign campaign` 参数，内部取 `campaign.moveMod` 传给 `effectiveMoveRange(moveMod)`（几何通用，编排层仍帝丘店感知）
- `initialHuayePower` → `initialPlayerPower`：统一命名
