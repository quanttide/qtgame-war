# Game 模块

## 职责

纯查询 + 工具方法，不持有状态，不管理回合。`GameController` 持有 `GameState` 并调用 `Game` 的方法。

## 方法

| 方法 | 输入 | 输出 |
|------|------|------|
| `getMoveRange` | unit, allUnits, campaign | `Map<String, int>` 可达位置 → 剩余移动力 |
| `getAttackTargets` | unit, allUnits | `Set<String>` 可攻击位置 |
| `spawnReinforcements` | units, campaign, turn | `(List<Unit>, List<Dispatch>)` |
| `checkVictory` | units, campaign, turn | `void`（变异 campaign） |
| `getUnitAt` | col, row, units | `Unit?` |
| `createInitialUnits` | — | `List<Unit>` |

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

- `getMoveRange` 签名增加 `Campaign campaign` 参数，传参给 `effectiveMoveRange(campaign)`
- `initialHuayePower` → `initialPlayerPower`：统一命名
