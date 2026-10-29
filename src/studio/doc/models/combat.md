# Combat — 战斗结算

> 模块：`lib/models/combat.dart`。纯函数，无状态、无 IO、不依赖剧本模型。

## 职责

`resolveCombat` 一次结算攻击方对防御方的战斗结果，返回不透明的 `CombatResult`。调用方只读四个字段与一句文本，不读内部公式。

## 接口

```dart
CombatResult resolveCombat(
  Unit attacker,
  Unit defender,
  TerrainBook book, {
  required Random rng,   // 随机源，调用方注入
  int hitMod = 0,        // 命中标量，剧本修正经调用方换算后传入
})
```

- `book`：剧本注入的地形册（id → props），结算只查 `propsAt`，不认识剧本名
- `rng`：**必填**，核心不内部构造 `Random`
- `hitMod`：剧本状态（如战力标量）由**调用方**换算成整数修正传入，结算层不收剧本对象

### 应用原语（侧别中立）

```dart
Dispatch applyCombatOutcome(
  Unit attacker,
  Unit defender,
  CombatResult result, {
  required int turn,   // 战报回合号，调用方给
  required String type, // 战报类别，玩家路 'hit' / 敌军路 'urgent'
})
```

- 落盘三样：`defender.takeDamage(result.damage)`、`attacker.markActed()`、产一条 `Dispatch`
- **侧别专属语义不进原语**：`playerPower` 消耗、`fortStrength` 削减、`reveal` 留在玩家路径调用方（`applyAttack`）；敌军路径（`_aiStep`）只调原语
- 玩家与敌军两路共用本原语，战果落盘不再各写一份；不放宽 `applyAttack` 的侧别守卫（它绑着玩家专属资源结算）

## 结算公式

1. 命中率 = `55 + 攻方 baseAttack×6 + hitMod − 地形 defenseBonus×8`
2. 超出射程 1 格每格 −4；命中率 clamp 到 5..92
3. 掷 d100，`roll ≤ 命中率` 则命中
4. 命中伤害 = 1；`roll ≤ 命中率×0.25` 时重创，伤害 = 2；突击对 fullCover 目标必中且伤害 2
5. 伤害 ≥ 防方 hp 则歼灭

## 确定性契约（v0.2.0 双跑比对的结算层基线）

- 同一 `rng` 种子 + 同一输入序列 → 结算结果序列逐项一致
- 不同种子 → 允许偏离
- `rng` 由调用方持有并按调用顺序消耗；结算层不缓存、不重置随机源

当前注入方：`GameController` 持有一个 `Random`（可注入种子，默认非种子化），点击路径与 AI 路径共用。v0.2.0 拆包后由主循环的主种子派生子流替换此处。

## 边界

- `resolveCombat` 不改单位状态：纯掷骰与文案产出；伤害应用（`takeDamage`/`markActed`）由 `applyCombatOutcome` 做
- `applyCombatOutcome` 只落伤害、行动标记与战报，不碰 `playerPower`/`fortStrength`/`reveal`——侧别专属资源结算归各调用方
- 不判胜负：胜负策略是剧本注入，见 `game.md`
- 不认识 `Campaign`：命中修正收标量不收对象
