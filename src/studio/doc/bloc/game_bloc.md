# game bloc

这个 GameBloc 是在我们之前讨论之后出现的实现，它解决了最关键的主线缺失问题——回合流转、阶段管理、事件驱动都有了。但仔细看，它仍然背着原型的一些包袱，而且 Bloc 的用法有几个地方不太规范。

—

✅ 解决的核心问题

1. 主线终于实体化了

```dart
enum GamePhase { player, ai, gameOver }
```

GameBloc 接管了回合骨架：

· 玩家阶段：选单位、移动、攻击
· 结束回合 → 切到 AI 阶段
· AI 执行完 → 切回玩家阶段，turn+1
· 胜负判定 → 切到 gameOver

这就是我们之前说“必须有一个控制器”的东西，现在它在了。

2. 事件驱动成形

SelectUnit、ClickHex、EndTurn、AiStep 这些事件清晰定义了用户/AI 的操作边界。UI 只需要 bloc.add(事件)，不需要知道内部如何调度。

3. 阶段保护

```dart
if (state.phase != GamePhase.player || state.isGameOver) return;
```

这在多个处理函数中出现，确保了不能在 AI 回合或游戏结束时操作己方单位。这个保护在之前散落的方法里完全不存在。

—

⚠️ 遗留问题和新出现的问题

1. 状态被直接修改（最严重）

虽然 Bloc 应该通过 emit(newState) 来更新状态，但代码里大量直接修改了 GameState 内部的字段，然后再 emit。比如：

```dart
// _executeMove 和 _executeAttack 里
unit.col = tc;           // ← 直接改单位
unit.row = tr;           // ← 直接改单位
defender.revealed = true; // ← 直接改单位
attacker.hasActed = true; // ← 直接改单位

// _onEndTurn 里
for (final u in state.units) {
  if (u.side == ’pla‘) u.hasActed = true;  // ← 直接改状态里的单位
}

// _onAiStep 里
state.units.addAll(reinforcements);        // ← 直接改状态里的列表
```

为什么这是错的：

· GameState 应该不可变。emit 发出的是同一个引用，如果内部字段被修改，Bloc 的比较逻辑会认为状态没变（因为引用相同），可能导致 UI 不刷新。
· state 是 getter，返回的是上一个被 emit 的对象。直接修改它，相当于修改了已经发出过的历史状态，破坏了状态的不可变性约定。
· 如果未来做回放/撤销，这些直接修改会让回溯变得不可能。

本应怎么做：
GameState 应该有 copyWith 方法，返回一个全新的状态对象，其中 units 是新列表，其中修改过的单位是新对象。

2. 仍然依赖 Game engine

```dart
final Game engine;
GameBloc(this.engine) : super(...)
```

Game 类（我们之前批评的那个）仍然被当作依赖注入，而且它的方法仍然在做直接修改：

· engine.resolveCombat(attacker, defender, campaign) 内部直接改 defender.hp 和 defender.alive。
· engine.spawnReinforcements(...) 返回新单位，但调用方用 state.units.addAll() 直接往状态列表里加。
· engine.checkVictory(...) 直接改 campaign.gameOver 和 campaign.victory。

GameBloc 虽然是新的调度者，但它调用的底层仍然是旧原型代码。这就变成了新酒瓶装旧酒——流程清晰了，但副作用依然存在。

3. Bloc 中不应该有 Future.delayed

```dart
await Future.delayed(const Duration(milliseconds: 500));
add(const AiStep());
```

Bloc 的 on<Event> 处理函数应该保持纯净。等待 500ms 然后 add 下一个事件属于 UI 层的关注点（比如动画或延迟展示）。放在 Bloc 里会导致：

· 单元测试时被迫等真的时间。
· 混杂了“怎么展示”的职责。

更好的做法是：_onEndTurn 直接 emit AI 阶段开始的状态，然后在 UI 层观察状态变化，用 Timer 或 Future.delayed 后再 add(AiStep())。

4. GameState 的 copyWith 用法不一致

```dart
emit(state.copyWith(clearSelection: true));
```

这里用了一个 clearSelection 布尔标志来清除选中，而不是显式地将 selectedUnitId、moveCandidates 等设为 null。这暗示 GameState 的 copyWith 设计不够直接——它用了一个“控制标志”来驱动内部清空逻辑。这种设计容易出错：如果其他地方调用了 copyWith 但没有同时处理这个标志，状态就不一致。

5. AI 逻辑内嵌在 Bloc 里

_onAiStep 包含了 AI 的全部决策逻辑：

· 援军生成
· 目标选择（按威胁值排序）
· 战力衰减
· 超时判定

AI 部分长达约 60 行，占整个 Bloc 的近三分之一。随着 AI 变复杂（移动、站位、协同），这个方法会快速膨胀。应该抽取 AiService，让 Bloc 只负责调用它并应用结果。

6. 字符串类型和拼音命名仍在

side 仍然是字符串（’pla‘、’nationalist‘），special 仍然是 ’assault‘。huayePower 在 Campaign 里继续被使用。

—

📊 当前阶段评价

这个 GameBloc 是原型向正式产品过渡的中间产物：

维度 状态 说明
主线流程 ✅ 已解决 回合、阶段、事件驱动都到位了
状态不可变 ❌ 残缺 多处直接修改 state 内部字段
旧引擎依赖 ⚠️ 仍在 Game 类仍在被调用，副作用存在
AI 分离 ❌ 未做 逻辑硬编码在 Bloc 里
命名/类型 ❌ 未修 拼音和字符串枚举沿用
UI 职责分离 ⚠️ 边界模糊 Future.delayed 放在 Bloc 里

—

🔧 如果要继续打磨

优先做（最大收益）：

1. 让 GameState 真正不可变，所有修改通过 copyWith 产生新对象，Unit 用我们之前讨论的不可变模式。
2. 把 Future.delayed(500ms) 移到 UI 层。
3. 把 _onAiStep 的核心逻辑抽到 AiService。

后续做：
4. 拆掉 Game engine 依赖，替换为纯 Service（MovementService / CombatService / VisibilityService）。
5. 类型强化（Side 枚举、Special 枚举）。
6. Campaign 重构为配置+不可变状态。

—

一句话总结

这个 Bloc 是你把“翻译过来的原型”朝“真正能运转的游戏”迈出的关键一步——它补上了主线控制器。但它还没有斩断旧模型的副作用链条，Game 类和直接状态修改仍然在底层运作。接下来需要把不可变状态和纯 Service 真正落实，才能让这个 Bloc 从一个“缝合层”变成稳固的核心。
