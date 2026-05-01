# game state

GameState 是 Bloc 架构中的状态核心，承担了“传递战场切片”的职责。它采用 Equatable 优化了 UI 刷新，并通过 copyWith 尝试提供不可变语义，但现状仍是个半成品式的不可变容器——设计意图正确，实现细节却留下了多个裂缝。

—

当前设计意图

· Equatable + props：将单位列表压缩为一个状态签名字符串，任何单位的位置、血量、行动状态变化都会触发 UI 重绘。
· copyWith 深拷贝：在未传入 units 时，对当前单位列表进行全量 copy()，意图隔离内外引用。
· 派生 getter：playerUnits、readyPlayerUnits、selectedUnit 等，方便 Bloc 和 UI 使用。
· clearSelection 标记：简化“取消选中”的状态更新。

这些设计表明作者意识到了“不可变状态”的必要，并且尝试用它来配合 Bloc 的事件驱动。

—

主要裂缝

1. copyWith 默认深拷贝：成本高、逻辑怪

```dart
units: units ?? this.units.map((u) => u.copy()).toList(),
```

每次调用 copyWith 更新任何字段（比如只添加一条日志），都会复制全体单位对象。这实现了一种“深层不可变”假象，但有两个问题：

· 性能浪费：频繁的状态更新（AI 步骤中可能有多步战斗）会制造大量不必要的副本。
· 语义曲解：真正要实现不可变，应该让 Unit 自身不可变，这样 units ?? this.units 就可以安全复用。现在因为 Unit 是可变的，只能靠全量拷贝自保，治标不治本。

2. clearSelection 是控制逻辑逃逸

copyWith 内部通过一个布尔标记来决定是否清空 selectedUnitId，这等于让状态对象自己执行了一段业务逻辑。正确的做法是：

```dart
// 调用方直接写
state.copyWith(selectedUnitId: null, moveCandidates: {}, attackCandidates: {});
```

clearSelection 的存在说明调用方觉得这样写太啰嗦，它实际上是“便捷方法”的变体——但位置错了，应该放在 GameBloc 的辅助方法或 GameState 的一个命名工厂里，而不是混在通用 copyWith 中。

3. props 字符串签名脆弱

```dart
units.map((u) => ’${u.id}:${u.col},${u.row}:${u.hp}:${u.alive}:${u.hasActed}:${u.revealed}‘).join(’|‘),
```

· 依赖 units 列表的顺序，如果顺序因排序变动就会误判状态变更。
· 字符串拼接容易因格式对齐问题导致调试困难。
· 更适合使用 ListEquatable 或对单位列表的 map 结果做深度相等比较，但目前的写法也能工作，只是不够稳健。

4. Unit 与 Campaign 的可变性仍然在

GameBloc 中大量出现了：

```dart
unit.col = tc;
attacker.hasActed = true;
newCampaign.huayePower = (newCampaign.huayePower - 1).clamp(5, 100);
```

GameState 虽然提供了 copyWith，但它的 units 列表里的 Unit 对象仍然可以被外部拿到并直接修改。Campaign 同理。这导致状态不可变性只存在于容器层，个体对象全部裸奔。

5. selectedUnit getter 的冗余 cast

```dart
units.cast<Unit?>().firstWhere((u) => u!.id == selectedUnitId, ...)
```

units 已经是 List<Unit>，不需要 cast。这属于原型翻译时的残留写法。

—

改进路径

第一步：让 Unit 真正不可变

这我们在之前详细讨论过。Unit 应改为所有字段 final，提供 moveTo、takeDamage 等方法返回新实例。GameState 中 units 就成为 List<Unit>（不可变对象的列表，引用可安全复用）。

第二步：精简 copyWith

```dart
GameState copyWith({
  List<Unit>? units,
  int? selectedUnitId,
  Set<String>? moveCandidates,
  Set<String>? attackCandidates,
  int? currentTurn,
  GamePhase? phase,
  CampaignState? campaign,   // 假设 Campaign 也已不可变
  List<Dispatch>? logMessages,
  // 移除 clearSelection
}) {
  return GameState(
    units: units ?? this.units,   // 直接复用，因为 Unit 不可变
    selectedUnitId: selectedUnitId ?? this.selectedUnitId,
    // ...
  );
}
```

第三步：改进 props

使用 Equatable 的列表属性比较：

```dart
@override
List<Object?> get props => [
  units.map((u) => [u.id, u.col, u.row, u.hp, u.alive, u.hasActed, u.revealed]),
  selectedUnitId,
  moveCandidates,
  attackCandidates,
  currentTurn,
  phase,
  campaign,
  logMessages.length,
];
```

或使用 DeepCollectionEquality。

第四步：将清理选中封装为专用方法

```dart
GameState clearSelection() => copyWith(
  selectedUnitId: null,
  moveCandidates: const {},
  attackCandidates: const {},
);
```

调用方使用 state.clearSelection()，语义清晰且不污染通用 copyWith。

—

总结

GameState 是 Bloc 化过程中正确的一步，它试图成为不可变的战场快照，但因为 Unit 和 Campaign 仍是可变对象，导致它只能通过“笨重”的全量拷贝来模拟不可变性，反而暴露了性能化和设计不一致的问题。当底层的模型类也完成不可变改造后，这个 GameState 只需微调就能成为一个干净、高效的状态载体。它现在的问题不是方向错误，而是孤军深入，友军没跟上。
