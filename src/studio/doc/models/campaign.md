# 战役模块

这个 Campaign 类比你刚刚吐槽的 Game 类清晰得多，但它也不是没毛病。它的问题和 Game 类正好相反——它太“老实”了，老实到把自己的致命缺陷直接暴露了出来。

—

表面功能解读

Campaign 类本质是一个战役状态容器，用于跟踪宏观战役数据，并提供其对战斗/移动的修正。

状态字段（游戏过程中会变）

字段 含义
huayePower 华野（华东野战军）总战力，从 85 开始
fortStrength 核心要塞强度，初始 3
qiuArrived / huArrived 邱清泉/胡琏援军是否已进场
gameOver 游戏结束标记
victory nullable bool：true 胜、false 败、null 未结束
victoryDetail 胜利/失败的描述文案

配置字段（开局后不变）

字段 含义
qiuReinforceTurn 邱清泉援军触发回合，默认 8
huReinforceTurn 胡琏援军触发回合，默认 7

计算属性（从 huayePower 推导）

· powerDesc：华野战力的文字描述（充沛/尚可/吃紧/濒临极限）。
· hitMod：命中率修正，战力高 +5，极低 -12。
· moveMod：移动力惩罚，战力低时移动力下降 1~2 点。

copy() 方法

返回一个值相同的全新 Campaign 对象，用于不可变状态管理（这在状态管理框架如 Riverpod/Bloc 中很重要）。

—

主要问题（这决定了它为什么“怪”）

1. 命名污染：拼音 + 英文混用

huayePower 这个命名搭配，是整份代码最刺眼的瑕疵之一：

· huaye 是拼音（华野），Power 是英文。
· 队友（以及未来的你）读代码时要不停在“中文拼音思维”和“英文语义思维”之间切换。

建议用语义命名：

· plaOffensiveCapacity （解放军进攻能力）
· supplyLevel / offensiveMomentum
· 或者直接中文注释 + offensivePower

同理，qiuReinforceTurn 和 huReinforceTurn 里的 qiu、hu 是将领姓氏拼音。如果用全英文，可以叫 qiuQingquanArrivalTurn；如果坚持缩写，起码加注释说明是谁。

2. 配置与状态混在一起

看这个类的字段，有两类截然不同的东西：

· 一经设定不再变的配置：qiuReinforceTurn、huReinforceTurn。
· 每回合都在变的状态：huayePower、fortStrength、qiuArrived、gameOver 等。

它们被一视同仁地塞进同一个对象，导致：

· copy() 必须把所有字段都复制一遍，但配置（援军回合）从开局后就不该被修改。每次复制时带上一堆永远不变的字段，纯属多余。
· 如果有多个剧本，剧本 A 的援军触发回合是 7/8，剧本 B 可能是 5/10。现在这样写，换剧本就得改类本身或传参，而不是从外部配置文件读。

3. 硬编码阈值在计算属性里

hitMod 和 moveMod 的 if-else 链完全硬编码数值和边界（70, 45, 25）。

· 数值本身就是设计决策，但没有常量化。
· 如果要调平衡，要改类的源码逻辑，而不是改配置。

4. victory 的语义模糊

bool? victory：

· null = 未结束
· true = 胜利
· false = 失败

但 victoryDetail 字段里并没有任何“失败”对应的文案（checkVictory 里只写胜利分支），而且类里也不提供任何设置失败的方法。这意味着“失败”这个分支虽然有字段预留，但实际上在整个代码里是孤儿逻辑——没人设它。

5. 单向依赖但职责不清

Campaign 在 Game 的方法签名中频繁出现：

· resolveCombat(..., Campaign campaign) 只读 hitMod。
· checkVictory(..., Campaign campaign) 直接写 campaign.gameOver、campaign.victory 等。

但 Campaign 本身并不知道 Game 的存在，它只是一堆数据的篮子。这意味着所有真正驱动 Campaign 状态变化的逻辑（战力怎么降、要塞强度怎么减、何时判定失败）全都在外部的调用方——而目前看 Game 类几乎没做这些。

所以 Campaign 是一个“被动的布告栏”：别人往上贴战报，它负责提供修正值，但它不决定任何事。

这本身不算错，但它和 Game 类的关系就会显得微妙：到底谁该负责扣减 huayePower？是战斗结算时顺便减？还是回合结束统一减？这些都没有答案。

—

与 Game 类的关系：一对难兄难弟

· Game 类：有大量操作逻辑，却缺少回合状态。
· Campaign 类：有大量状态，却没有逻辑去改变自己（除了被外部瞎改）。

合在一起，它们构成了一个诡异的画面：

一个叫 Game 的类不懂回合，一个叫 Campaign 的类不懂战役推进。

真正丢失的那块“主线”——回合调度、事件触发、状态自动机——依然在代码里不存在。Campaign 的存在只是让这个空洞更明显了，因为它已经准备好了 gameOver、victory 这些字段，却没人知道在何时、由谁来设置失败。

—

📌 总结

Campaign 类本身作为“战役状态容器”是合格甚至清晰的（除了命名），但它：

· 混淆了静态配置与动态状态；
· 硬编码了设计值，可调性差；
· 缺乏自我变化的能力，被动等待外部修改；
· 暴露了整体架构中“游戏主驱动力”缺失的老问题。

它越清晰，就越反衬出那个迟迟没出现的“真正的游戏控制器”有多么迫切。

要让 Campaign 类走出目前“被动的布告栏”困境，并能与 Game 清晰协作，可以按关注点分离 + 显式状态机 + 数据驱动配置的思路重构。下面是一个可行的设计方案。

—

1. 拆分为三个独立层次

核心原则：

· 配置只读，一个战役一套。
· 运行时状态可写，但只能通过明确的方法修改，内部维护一致性。
· 计算规则可外部供给，便于调整平衡。

类结构概览

```
CampaignConfig          → 静态剧本配置
CampaignState            → 动态战役状态（不变量风格）
CampaignRules            → 战力→修正的映射逻辑（可由配置构造）
+ 一个轻量级的 Campaign 作为以上三者的持有者
```

—

2. CampaignConfig – 纯配置，不可变

```dart
class CampaignConfig {
  final String name;
  final int initialOffensivePower;    // 原 huayePower
  final int initialFortStrength;
  final int qiuReinforceTurn;
  final int huReinforceTurn;

  // 其他可能扩展的配置：失败条件、回合上限等

  const CampaignConfig({...});
}
```

· 完全无状态，只描述“剧本设定”。
· 初始化时可从 JSON/常量读入，不再硬编码在 Campaign 里。

—

3. CampaignState – 运行时状态，不可变数据类

```dart
class CampaignState {
  final int offensivePower;
  final int fortStrength;
  final bool qiuArrived;
  final bool huArrived;
  final bool gameOver;
  final bool? victory;     // true=胜, false=败, null=进行中
  final String victoryDetail;

  const CampaignState({...});

  // 状态转换方法：返回新实例
  CampaignState reducePower(int amount) => copy(offensivePower: offensivePower - amount);
  CampaignState reduceFort(int amount) => copy(fortStrength: fortStrength - amount);
  CampaignState markQiuArrived() => copy(qiuArrived: true);
  // ... 其他转换
}
```

· 完全不可变，通过 copy() 产生新状态，适合与状态管理框架配合。
· 状态转换方法语义明确，调用者不必直接改字段，避免误用。

—

4. CampaignRules – 修正值计算，参数化且可换

```dart
class CampaignRules {
  final List<PowerThreshold> thresholds;

  CampaignRules(this.thresholds);

  int hitMod(int currentPower) { ... }
  int moveMod(int currentPower) { ... }
  String powerDesc(int currentPower) { ... }
}

// 数据模型
class PowerThreshold {
  final int minPower;
  final int hitMod;
  final int moveMod;
  final String description;
}
```

· 原 if-else 链变成可配置的列表。
· 默认规则可以仍用原值，但换剧本/调平衡时只需更换阈值表，不改代码。
· hitMod/moveMod 的计算直接从 thresholds 中查找当前战力对应的效果。

—

5. Campaign – 轻量门面，关联三者

```dart
class Campaign {
  final CampaignConfig config;
  final CampaignRules rules;
  CampaignState state;

  Campaign({required this.config, this.rules = defaultRules, required this.state});

  // 委托给 rules
  int get hitMod => rules.hitMod(state.offensivePower);
  int get moveMod => rules.moveMod(state.offensivePower);
  String get powerDesc => rules.powerDesc(state.offensivePower);

  // 委托给 state，并更新自身状态
  void applyOffensivePowerLoss(int amount) {
    state = state.reducePower(amount);
  }
  void applyFortDamage(int amount) {
    state = state.reduceFort(amount);
  }
  // ... 其他修改方法

  // 胜利/失败判定也放在这里，使用专用方法
  void checkVictory(List<Unit> units, TerrainMap map) { ... }
}
```

· Campaign 现在是“活的”：它拥有 state，并根据规则计算修正值。
· 修改状态的方法有明确的业务语义，内聚了原本散落在 Game 中的状态修改逻辑。

—

6. 与 Game 的协作方式

在重构后的 Game 类中，回合结束时只需要：

```dart
// 回合结束处理
void endTurn() {
  campaign.applyOffensivePowerLoss(turnCost);  // 因拖延产生的战力衰减
  campaign.checkVictory(units, map);
  if (campaign.state.gameOver) { ... }
  // 刷新 unit 状态等
}
```

而战斗结算不再直接接收 Campaign 整个对象，只接收需要的修正值：

```dart
CombatResult resolveCombat(Unit attacker, Unit defender, int hitMod, List<List<TerrainType>> map) {
  // hitMod 从 campaign.hitMod 传入
}
```

这样：

· Game 只负责回合流转和单位调度。
· Campaign 封装所有战役层面的状态和规则。
· 耦合降低，测试更容易（战斗计算不再依赖整个 Campaign）。

—

7. 命名优化

原用名 建议
huayePower offensivePower 或 supplyLevel
fortStrength fortIntegrity 或 coreDefense
qiuReinforceTurn qiuQingquanArrivalTurn 或配置文件中的 reinforcements.qiu.turn
huReinforceTurn 同上

命名以英语语义为主，拼音仅用于注释或配置说明。

—

设计收益

1. 可测试：CampaignState 是纯数据，CampaignRules 是纯函数，均可独立单元测试。
2. 可配置：剧本数据来自 CampaignConfig，修正规则来自 CampaignRules，换战役无需改类。
3. 状态安全：通过不可变状态 + 显式方法控制变更，防止意外字段修改。
4. 职责收敛：Campaign 聚焦自己的状态与规则，不再被动等待别人修改它。

—

这一设计将“被动的布告栏”变成了能自我管理的战役对象，既保留了原有数据的清晰性，又补上了缺失的“战役推进”驱动力，很好匹配了战棋游戏主线的需求。

