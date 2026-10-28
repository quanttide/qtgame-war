# Task 模块

命令档位与疲劳规则。每个回合玩家为每个纵队指定一个 Task，Task 决定该纵队参与哪条战线、结算加值与疲劳增量。规格来自 `examples/prototype/龙王店战斗.html` 的 `TASK` 表与 `resolve()`，逐项等价。

## TaskType（本体，七档）

| 值 | 标签 | atkMod | fat | 战线 | 说明 |
|----|------|--------|-----|------|------|
| assault | 强攻 | 0 | 2 | 攻城 | 直接攻打工事，疲劳最重 |
| siege | 围困 | 0 | 0 | 攻城 | 不给加值也不给疲劳的消耗打法 |
| feint | 佯攻 | -2 | 1 | 攻城 | 牵制守军，攻击力打折 |
| block | 正面 | 0 | 1 | 阻援 | 正面阻击整25师 |
| flank | 侧翼 | 0 | 1 | 阻援 | 侧翼包抄，失败则敌冒进 |
| lure | 诱敌 | 0 | 0 | 阻援 | 放敌近一步，为伏击创造条件 |
| standby | 待命 | 0 | 0 | 恢复 | 不参战，恢复疲劳 |

- **攻城线**（assault / siege / feint）：结算时打工事。
- **阻援线**（block / flank / lure）：结算时制整25师推进。
- **恢复**（standby）：结算时疲劳 -2。

## TaskRole（角色决定可用档位）

| 角色 | 可用档位 |
|------|---------|
| assault | assault / siege / feint |
| reserve | block / flank / lure / standby / assault |

攻城纵队不能去阻援，预备队（11纵）五档皆可——含 assault，允许预备队最后投入攻城。

## 疲劳规则

| 规则 | 值 | 来源 |
|------|-----|------|
| 阈值 | fat ≥ 4 时攻击受罚 | `resolve()` 的 `pen` |
| 惩罚 | 1（从攻击/佯攻的 diff 中减去） | 同上 |
| 增量 | 按档位 fat 字段累加（攻城/阻援档位均计） | `u.fat += m.fat` |
| 恢复 | standby：`fat = max(0, fat - 2)` | `u.fat = Math.max(0, u.fat - 2)` |
| 轮换信号 | 攻城角色中 fat 最高且 ≥4 者，应转 siege | `rotate()` |

疲劳只由档位增量与 standby 恢复驱动，无时间自然衰减。

## 接口

```dart
enum TaskRole { assault, reserve }
enum TaskType { assault, siege, feint, block, flank, lure, standby }

// TaskType 扩展：label / atkMod / fat / 所属战线分组
// slotsFor(TaskRole) → 该角色可用档位（顺序如上表）
// fatiguePenalty(int fat) → 0 或 1（fat ≥ fatigueThreshold 时 1）
// fatigueThreshold = 4；standbyRecovery = 2
```

## 归属

TaskType/TaskRole 是剧本无关的规则词汇，不含坐标与数值调整来源；每局的纵队名、初始 role、坐标由剧本数据提供（v0.1.0 待建 `assets/campaigns/longwangdian/`）。per-Unit 的 `task`/`fat` 字段接线与结算消费在后续任务落地。

## 变更记录

- 初版：从原型 `TASK` 表、`slots()`、`resolve()` 抽取，含战线分组与疲劳规则
