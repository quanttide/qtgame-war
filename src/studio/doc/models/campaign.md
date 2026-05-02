# Campaign 模块现状

## 当前状态

战役状态容器，跟踪 huayePower、fortStrength、援军状态、胜负标记。配置（qiuReinforceTurn 等）与状态混杂。

## 核心问题

1. **命名污染** — huayePower、qiuReinforceTurn 等拼音+英文混用
2. **配置/状态混杂** — 援军回合（不变）与战力（常变）在同一对象
3. **硬编码阈值** — hitMod/moveMod 的 if-else 链数值写死
4. **被动无逻辑** — 只提供数据，不驱动战役推进
5. **victory 语义模糊** — bool? 字段，失败分支未实现

## 改进方向

拆分为三层：
- **CampaignConfig** — 不可变配置（援军回合、初始战力等）
- **CampaignState** — 不可变状态，提供 `reducePower()` 等转换方法
- **CampaignRules** — 战力→修正的映射（可配置阈值表）

命名优化：huayePower → offensivePower，fortStrength → fortIntegrity
