# Campaign 模块现状

## 当前状态

战役状态容器，跟踪 huayePower、fortStrength、援军状态、胜负标记。配置（qiuReinforceTurn 等）与状态混杂。

## 核心问题

1. **命名污染** — huayePower、qiuReinforceTurn 等拼音+英文混用
2. **配置/状态混杂** — 援军回合（不变）与战力（常变）在同一对象
3. **硬编码阈值** — hitMod/moveMod 的 if-else 链数值写死
4. **被动无逻辑** — 只提供数据，不驱动战役推进
5. **victory 语义模糊** — bool? 字段，失败分支未实现

## 改进方向（Bloc 架构适配）

### 第一步：Campaign 本身优化
1. **命名优化**：`huayePower` → `offensivePower`，`fortStrength` → `fortIntegrity`
2. **不可变化**：`copy()` 改为 `copyWith(...)`，去掉可变字段直接赋值
3. **配置分离**：`qiuReinforceTurn`/`huReinforceTurn` 作为构造参数，不再混入状态

### 第二步：逻辑抽到领域服务
- `powerDesc`/`hitMod`/`moveMod` 抽到 `CombatService`（领域层纯函数）
- GameBloc 调用 `CombatService.getHitMod(state.campaign.offensivePower)` 而非依赖 Campaign 的计算属性

### 第三步：考虑 CampaignBloc（时机未到）
当前 Campaign 逻辑简单（主要是数据容器），拆到独立 Bloc 会导致 GameBloc ↔ CampaignBloc 通信，增加复杂度。
**触发条件**：当出现援军调度、政治影响、多阵营战力等复杂逻辑时，再拆。

### 改造后依赖关系
```
GameBloc
  └─ 持有 Campaign（不可变值对象）
  └─ 调用 CombatService（领域层）

而非：
GameBloc → CampaignBloc → CombatService（过度分层）
```
