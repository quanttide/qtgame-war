# game event

GameEvent 体系是整个 Bloc 的输入端口——它定义了所有能从外界（UI、系统或其他 Bloc）注入游戏核心的意图。这组事件清晰且克制，但有一个隐含的结构性问题值得留意。

—

事件分类与职责

事件 触发者 含义
SelectUnit 玩家点击己方单位 试图选中指定单位
ClickHex 玩家点击地图格 尝试移动、攻击或切换选中
EndTurn 玩家结束回合按钮 结束玩家阶段，启动 AI
ResetGame 玩家重置 重新开始一局
AiStep 内部（_onEndTurn 后） 执行 AI 行动
ClearSelection 内部（点击无关格等） 取消当前选中

—

优点

· 扁平化设计：没有多余的抽象层，直接对应界面操作，开发初期易理解。
· 基础隔离：事件自身不包含业务逻辑，只携带必要参数（unitId、col、row）。
· Equatable 实现：SelectUnit 和 ClickHex 正确重写了 props，避免无效重建；空事件的 props 返回 []，符合规范。

—

潜在改进点

1. ClearSelection 与 AiStep 是内部事件

这两个事件并不代表“外部意图”，而是状态机内部为了延迟执行或逻辑复用而自产自消的事件。

· ClearSelection：可以在 GameBloc 内通过直接调用一个私有方法完成，不必绕道事件系统。
· AiStep：是在 _onEndTurn 中通过 Future.delayed 后 add 的。这本质上是用事件队列模拟异步步骤。更干净的做法是将 AiStep 作为 Bloc 内的一个私有方法，_onEndTurn 切换到 GamePhase.ai，然后由 UI 监听状态并调用 bloc.add(AiStep()) 或直接执行。

目前的方式虽然能跑，但让事件流带上了“过程控制”的意味，淡化了事件作为“意图声明”的纯度。

2. ClickHex 职责过重

ClickHex 的事件处理函数 (_onClickHex) 内部有复杂的条件分支：判断是移动、攻击、切换选中还是清除选中。这使得单个事件承载了多个不同意图的解析，它的处理函数是 Bloc 中最长的一个。

更规范的做法可以是：

· ClickHex 只表示“玩家点击了某格”。
· 在 Bloc 内部，根据当前状态（是否选中单位、该格是否在移动/攻击候选内）分发到相应的私有处理方法。

或者将移动/攻击拆分为独立事件：

· MoveOrder(col, row)
· AttackOrder(targetId)

这样事件的语义更强，但会增加事件种类。取舍取决于你希望事件是“接近 UI 操作”还是“接近游戏指令”。

3. 缺少某些明确的失败/无效操作事件

当前，如果玩家在非自己的阶段点击，_onSelectUnit 和 _onClickHex 直接 return。这在原型中没问题，但正式产品可能需要 UI 给出反馈（例如“现在不能行动”）。可以引入一个 InvalidOperation 事件携带提示信息，或者直接在状态中增加 message 字段。

—

与主线的衔接

在 Bloc 架构里，事件是驱动状态流转的唯一入口。GameBloc 通过这组事件实现了玩家输入 → 状态变化 → UI 刷新的单向循环。它们成功扮演了“游戏指令”的角色，但距离纯粹的事件驱动还有微妙差距（主要是 AiStep 和 ClearSelection 的自产自消）。

重构建议：将内部过程调用改为私有方法，保留事件队列只给真正的外部意图，这样 GameEvent 系统会变得更干净，也更容易测试。
