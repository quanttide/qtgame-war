# Game 模块

本文件还包含 `GamePhase`（三态枚举）和 `GameState`（可变状态容器），与 `Game` 放在一起因为三者都是 game 概念的数据/逻辑，而非 controller 的实现细节。

## 职责

纯查询 + 工具方法，不持有状态，不管理回合。`GameController` 持有 `GameState` 并调用 `Game` 的方法。

| 方法 | 输入 | 输出 |
|------|------|------|
| `getMoveRange` | unit, allUnits | `Map<String, int>` 可达位置 → 剩余移动力 |
| `getAttackTargets` | unit, allUnits | `Set<String>` 可攻击位置 |
| `spawnReinforcements` | units, campaign, turn | `(List<Unit>, List<Dispatch>)` |
| `checkVictory` | units, campaign, turn | `void`（变异 campaign） |
| `getUnitAt` | col, row, units | `Unit?` |
| `createInitialUnits` | — | `List<Unit>` |

## CampaignConfig

所有剧本数据通过 `CampaignConfig` 注入，从 JSON 加载或直接构造：

| 字段 | 类型 | 来源 |
|------|------|------|
| `mapTerrain` | `List<List<TerrainType>>` | `map.json` |
| `templates` | `Map<String, UnitType>` | `units.json` |
| `initialUnits` | `List<UnitSpec>` | `units.json` |
| `reinforcementWaves` | `List<ReinforcementWave>` | `campaign.json` |
| `maxTurns` | `int` | `campaign.json` |
| `initialHuayePower` / `initialFortStrength` | `int` | `campaign.json` |

`UnitSpec` 和 `ReinforcementWave` 是纯数据类，用 `fromJson` 析出。

## 依赖关系

```
CampaignConfig ← Game ─→ GameController → Unit/Campaign (变异)
                        ↕
                   CombatService (combat.dart, 纯函数)
```

- Game 不依赖 GameController
- 战斗逻辑已抽离到 `combat.dart`（`resolveCombat` 纯函数，仅含 `Random` 副作用）
- 回合管理、AI 逻辑、UI 通知全部在 GameController

## 未解决的问题

- `getMoveRange` 在调用时展开 BFS，无缓存。如果未来需要频繁查询，考虑预计算可达域
- `checkVictory` 副作用直接改 `campaign`，不是纯函数（但与 GameController 模式一致：方法改状态，不返回新对象）
- `spawnReinforcements` 同时做生成和日志，两层耦合。必要时可拆为 spawner + logger