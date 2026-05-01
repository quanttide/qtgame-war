# 架构设计文档

指挥官决策系统：架构设计思路

—

## 一、核心认知：这不是游戏，是叙事型决策支持系统

传统游戏以帧循环驱动，核心是视觉表现与实时交互。
我们的系统以事件驱动，核心是复杂状态管理、信息不对称下的决策、以及决策后果的多线程推演。

它更接近一个军事指挥信息系统的叙事化变体——用互动小说的方式包裹，但底层是规则引擎、事件溯源和响应式状态管理。因此，架构设计遵循业务系统的分层原则，而非游戏引擎的场景-实体模型。

—

## 二、架构分层（自上而下）

```
┌─────────────────────────────────┐
│         Presentation Layer      │  Flutter UI (Widgets, Pages)
├─────────────────────────────────┤
│         Application Layer       │  Blocs (Commander, Force, Battlefield, Time, Intel)
├─────────────────────────────────┤
│         Domain Layer            │  Entities, Value Objects, Rules Engine, Intent System
├─────────────────────────────────┤
│         Infrastructure Layer    │  Event Store, Logging, Persistence, AI Adapter
└─────────────────────────────────┘
```

各层职责：

· Presentation Layer：纯UI渲染，通过 BlocBuilder 订阅状态变化，没有任何业务逻辑。包括态势面板、决策面板、部队卡片、日志时间线、意图选择器。
· Application Layer：所有 Bloc 驻留于此。负责接收用户事件（或系统内部事件），协调领域对象，产出新状态。Bloc 之间通过事件流协作，不直接调用。
· Domain Layer：纯 Dart 代码，不依赖 Flutter 和 Bloc。包含：
  · 实体：Commander（风格、意图）、ForceUnit（体力、士气、编制、韧性）、BattlefieldSituation（部队位置、敌军据报）
  · 值对象：IntelligenceReport（可信度、时间戳）、CommandOrder（目标、时限、方式）、Consequence
  · 规则引擎：红线校验器、意图-选项过滤器、后果计算器
· Infrastructure Layer：事件存储（支持复盘和分支推演）、日志持久化、敌军 AI 适配器、随机数种子管理。

—

## 三、核心模块划分

| 模块 | 对应 Bloc | 核心职责 |
|------|-----------|---------|
| 指挥官模块 | CommanderBloc | 接收玩家决策事件，锁定意图，发布命令事件 |
| 部队模块 | ForceBloc (可多实例) | 维护每支部队状态，校验能力红线，响应命令事件，产生损耗事件 |
| 战场模块 | BattlefieldBloc | 维护战场真实态势，处理敌军 AI 决策，计算交战结果，广播态势变化事件 |
| 时间模块 | TimeBloc | 发射 TimeElapsed 事件，驱动体力衰减、情报时效性降低、敌军行动周期 |
| 情报模块 | IntelBloc | 从战场获取真实数据，施加延迟和可信度过滤，产出 IntelligenceReport 供指挥官消费 |
| 日志/审计模块 | AuditBloc | 监听所有 Bloc 的事件，序列化存储，提供回放和分支推演的数据源 |

关键设计原则：每个 Bloc 只知道自己领域的状态，通过事件与其他 Bloc 通信，形成松耦合的事件网络。

—

## 四、核心数据流（示例：一次进攻决策的生命周期）

1. 玩家在UI上锁定意图并选择"发动进攻" → 产生 AttackIntent 事件
2. CommanderBloc 收到事件，构造 CommandOrder，发布 CommandIssued 事件
3. ForceBloc 监听到 CommandIssued，执行红线校验：
   · 若校验失败，发布 CommandBlocked 事件，指挥官收到失败反馈
   · 若校验通过，发布 CommandAccepted 事件，并开始计算行军/战斗耗时
4. BattlefieldBloc 监听到 CommandAccepted，同时接收 TimeElapsed 事件推进，计算交战结果（结合敌军 AI 决策）
5. 交战结束后，BattlefieldBloc 发布 EngagementResult 事件（包含双方损耗、位置变化）
6. ForceBloc 监听到 EngagementResult，应用损耗，更新部队状态，可能触发 UnitExhausted 事件
7. IntelBloc 从 EngagementResult 生成延迟的 IntelligenceReport，发送给 CommanderBloc
8. CommanderBloc 收到情报后，更新态势状态，UI 自动刷新，玩家看到战报，进入下一决策循环

时间如何参与？
TimeBloc 按战役设置的速度（例如"每现实5秒 = 游戏内1小时"）发射 TimeElapsed，所有监听此事件的 Bloc 自行更新时效性数据（体力衰减、情报过期等）。时间不是单独的计时器，而是统一的事件脉冲。

—

## 五、支撑复杂性的关键设计决策

### 1. 事件溯源（Event Sourcing）

所有状态变化都由事件引发，事件被 AuditBloc 持久化为有序日志。
这带来：

· 复盘模式：按时间轴回放任意战役
· 分支推演：从任意历史节点克隆状态，注入不同事件序列，探索"如果当时"
· 测试能力：可重放事件流，验证规则引擎修改后行为是否一致

### 2. 信息不对称建模

战场真实状态由 BattlefieldBloc 掌握，但 CommanderBloc 只消费 IntelBloc 过滤后的报告。
报告携带：

· observedAt：情报代表哪个时间点的真实情况
· confidence：可信度（0~1），影响UI上标记的模糊程度
· source：情报来源（侦察、友邻通报、截获电讯）

指挥官永远在"据报"的基础上决策，UI 上对过期或低可信度情报用视觉差异（褪色、闪烁、问号标记）提示。

### 3. 领域规则引擎独立

红线校验、意图-选项匹配、后果计算等规则全部实现在 Domain Layer 的纯函数或规则对象中，不依赖 Flutter 或 Bloc。
好处：

· 可单独单元测试
· 未来可用 JSON/YAML 配置新战役的规则
· 容易接入 AI 辅助生成规则变体（例如让 AI 生成不同的意图-选项映射）

### 4. 敌军 AI 作为独立 Bloc，且共享相同的决策框架

EnemyCommanderBloc 可以复用 CommanderBloc 的逻辑，只是它的事件来源不是UI，而是一个战术策略引擎（基于规则或行为树）。
这为未来 PvP 留下空间：两个玩家分别通过各自的客户端发送事件，服务端进行事件合并。

—

## 六、与叙事层的接口：将状态翻译成故事

业务逻辑产生的是事件流和状态快照，叙事层负责把它们转化为玩家读到的文本。
在架构中，叙事生成器位于 Presentation Layer 之上，作为一个视图模型转换器：它读取当前 Bloc 状态与最近事件，调用模板引擎和文本编织器，生成情境描述、选项文案和后果反馈。

之前讨论的"文本编织器"就挂在这里，而非在领域逻辑中拼凑字符串。

—

## 七、从原型到完整系统的演进路径

1. **第一阶段：Cubit 原型**
   · 单个场景，CommanderCubit + 简化的 Force 状态
   · 验证意图过滤器、后果计算的基本体验
   · 无时间系统，事件不持久化

2. **第二阶段：引入 Bloc + 核心模块**
   · CommanderBloc、ForceBloc（单部队）、BattlefieldBloc（简单敌军脚本）
   · 时间模块上线，体力衰减生效
   · 情报延迟简单模拟（固定延迟5分钟）
   · 日志开始记录事件，但未持久化

3. **第三阶段：多部队、多线程后果、事件持久化**
   · ForceBloc 支持多实例（每个纵队一个）
   · 情报模块加入可信度与时效性
   · 审计模块接入，支持复盘
   · 撤退机制、组织韧性实现

4. **第四阶段：完整战役 + 分支推演 + AI 对手**
   · 完整战役剧本（如豫东），多节点动态目标
   · 分支推演 UI：从历史节点创建分支，独立运行
   · 敌军 AI 升级为可配置策略的 Bloc
   · 可能与后端集成，实现多人异步对战
