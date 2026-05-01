整体看完这四个模型模块加上新引入的 GameBloc、GameState、GameEvent，目前的代码状态可以用一句话概括：

主线终于就位，但底层仍是原型的泥潭。上面跑着新架构，下面踩着旧坑。

下面从全局视角把核心问题串起来，然后给出一条可逐步执行的重构路线。

—

一、当前全局架构（隐式）

```text
UI → GameBloc (事件驱动) → GameState (快照)
            ↓
        Game engine (旧逻辑 + 副作用)
            ↓
        Unit / Campaign / Battlefield (可变数据)
```

· GameBloc 负责事件处理和阶段切换（这是正确的）。
· GameState 试图做不可变快照，但容器里面的 Unit、Campaign 仍然可变。
· Game 类仍然作为“引擎”被 Bloc 调用，内部方法依然直接修改传入的对象、硬编码业务规则、混杂援军与胜利判定。
· Battlefield 是唯一干净的纯计算模块。

症状：Bloc 里大量出现 unit.col = ...、defender.revealed = true、campaign.huayePower -= 1 这种直接写入。状态表面上是发出的新 GameState，但实际上新旧状态共享同一个 Unit 实例，历史状态被污染。

—

二、最关键的 3 个全局病灶

1. 单位与战役对象可变 → 不可变状态无法成立 → 回放/测试/撤销全部受阻。
2. Game 类仍在充当“规则+副作用+工厂” → 即使 Bloc 兜住了流程，底层还是不可控的修改 + 硬编码。
3. Bloc 内部混杂了时序、AI、状态直接修改 → 单一职责被破坏，Bloc 成了新的“大杂烩”。

—

三、重构路线（按优先级，每步都可单独验证）

第 1 步：让 Unit 和 Campaign 真正不可变（基础设施）

这是所有改动的基石，不改这一步，上层再怎么修都是补丁。

具体改造：

· Unit 所有字段 final，移除公开 setter（包括 hp, hasActed 等）。
· 提供状态转换方法，返回新实例：
  ```dart
  Unit moveTo(int col, int row);
  Unit takeDamage(int amount);
  Unit markActed();
  Unit reveal();
  ```
· Campaign 拆分为 CampaignConfig（不可变配置）和 CampaignState（不可变状态，含 copyWith）。
· CampaignState 提供类似 reducePower(int amount) 的方法返回新状态。

预期效果：

· GameState 的 copyWith 不再需要 units.map((u) => u.copy()) 的全量深拷贝，可以直接复用引用。
· GameBloc 中任何对单位的修改都将产生新单位和新列表，通过 emit 发出，避免污染历史状态。

第 2 步：抽取纯服务，肢解 Game 类

Game 类目前包含：移动查询、攻击查询、战斗结算、援军生成、胜利判定、地形查询静态方法、初始单位工厂。

新建服务类（全部为纯函数，不修改任何参数）：

服务 职责 输入 输出
MovementService 计算可达格 Unit, List<Unit>, TerrainMap Map<String, int>
CombatService 计算战斗结果 Unit, Unit, int hitMod, TerrainMap CombatResult
VisibilityService 更新单位揭示 List<Unit>, TerrainMap List<Unit> (新列表)
ReinforcementService 生成援军数据 CampaignState, int turn List<Unit>, List<Dispatch>
VictoryService 检查胜利/失败 List<Unit>, CampaignState, int turn, TerrainMap CampaignState (新)

迁移步骤：

· 将 Game.getMoveRange 逻辑搬入 MovementService，移除对 Game 实例的依赖，改为接收地图参数。
· 将 Game.resolveCombat 逻辑搬入 CombatService，不再修改 defender，只返回 CombatResult。
· 将 Game.spawnReinforcements 改为纯数据生成函数，放入 ReinforcementService，只返回新单位列表和日志。
· 将 Game.checkVictory 改为 VictoryService.check，返回新的 CampaignState（可能带有 gameOver 标记）。
· 地形静态方法 (terrainDefense, inFullCover, inCore) 移到 Battlefield 或独立 TerrainHelper。

完成后，可以彻底删除 Game 类。

第 3 步：重构 GameBloc，成为真正的调度中心

现在 GameBloc 依赖 Game engine，重构后它依赖一堆纯服务。

改造要点：

1. 注入服务：
   ```dart
   GameBloc(MovementService, CombatService, VisibilityService, 
            ReinforcementService, VictoryService, CampaignConfig)
   ```
2. 消除直接状态修改：
   · _executeMove 中：
     ```dart
     // 旧： unit.col = tc;
     // 新：
     final movedUnit = unit.moveTo(tc, tr);
     final newUnits = state.units.map((u) => u.id == movedUnit.id ? movedUnit : u).toList();
     ```
   · _executeAttack 中：
     ```dart
     final result = combatService.resolve(attacker, defender, state.campaign.hitMod, map);
     // 应用结果：
     final damagedDefender = defender.takeDamage(result.damage).reveal();
     final actedAttacker = attacker.markActed();
     final newUnits = ... // 替换这两个单位
     // 然后检查胜利，可能修改campaignState
     ```
3. 清理 _onAiStep：
   创建 AiService，接收当前状态，返回一系列 AI 操作（移动、攻击）的效果列表。Bloc 只需应用这些效果并推出新状态。
   AI 不再直接调用 engine.resolveCombat 并修改单位，而是调用 combatService.resolve 并累积状态变化。
4. 移除 Future.delayed：
   _onEndTurn 中直接 emit AI 阶段状态。在 UI 层监听 phase == GamePhase.ai 后，延迟调用 bloc.add(AiStep())。或者将 AiStep 改为 Bloc 的私有方法，由 UI 的 Timer 触发。
5. ClearSelection 事件可保留，但处理函数改为调用 state.clearSelection() 方法（在 GameState 中定义）。

第 4 步：优化 GameState 和 GameEvent

· GameState：
  · 移除 clearSelection 标志，改用显式字段或命名方法。
  · props 改为基于实际不可变对象的比较（如 ListEquatable 或直接比较单位列表的标识），不再用字符串拼接。
  · 单位列表改为不可变列表（IList from fast_immutable_collections 或就用 List<Unit>，前提是 Unit 不可变，引用安全）。
· GameEvent：
  · 如果不想引入 MoveOrder / AttackOrder 事件，保持现有结构也可以，但需在 Bloc 内将 _onClickHex 拆分为可读的私有方法（_handleMove, _handleAttack 等）。
  · 可选：添加 InvalidAction 事件或状态字段，用于 UI 提示。

第 5 步：命名与类型彻底清理

· side → enum Side { pla, nationalist }
· special → enum UnitAbility { assault }（或 List<UnitAbility>）
· huayePower → offensivePower 或 supplyLevel
· 所有拼音缩写改为语义英文或完整名称，并加注释。
· 地图数据、初始单位、援军配置从 createInitialUnits() 等工厂方法中迁移到独立的数据类或 JSON。

—

四、重构后的目标架构

```text
UI  →  GameBloc (事件→状态)
           ↓ 调用
      MovementService
      CombatService
      AiService          ← 所有纯计算
      ReinforcementService
      VictoryService
           ↓ 返回
      新 GameState (不可变)
      内含 List<Unit> (不可变)
      内含 CampaignState (不可变)
      内含 Battlefield (只读地形)
```

特征：

· 任何一次 emit 的状态都是完全独立的快照，可序列化、可回放。
· Bloc 中不再出现 对象.字段 = 新值 的直接写入。
· 添加新剧本只需提供新的 CampaignConfig 和单位数据，不改服务代码。
· 单元测试可以针对任何服务独立进行，可以模拟任意状态快照。

—

五、从哪里开始动手

建议从第 1 步开始：让 Unit 不可变。这一步的影响面最大，但收益立竿见影——你会发现 Bloc 里所有 unit.col = ... 报错，然后被迫把状态变更都改成返回新实例。这会自然逼迫你写出更干净的状态更新逻辑，也为后续移除 Game 铺路。

完成第 1、2 步后，整个项目的可维护性会跃升一个台阶。第 3、4、5 步则是在新地基上打磨细节。

—

总结：当前代码有了很好的骨架（Bloc + 事件 + 状态），但肌肉和器官还在用原型的临时部件。只要按顺序把基础零件（Unit/Campaign）换成不可变版本，把旧引擎（Game）拆成纯服务，再把 Bloc 清洗干净，这套代码就能从“能跑的翻译原型”进化成“可长期迭代的正式产品”。
