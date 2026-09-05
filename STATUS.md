# qtgame-war 状态报告

## 已实现

- **兵棋推演引擎**（帝丘店战役）：Flutter 实现，六角格地图、单位移动/攻击、战斗结算、援军触发，可运行
- **4 个实验原型**：intent-prototype（HTML，已验证意图→行动过滤机制）、intent-llm-test（情报→判断→意图映射自然成立）、chief-of-staff-prototype（参谋长模式交互原型）、prototype
- **完整文档体系**：PRD、ADD、BRD、IXD、QA、spec、roadmap、insight，覆盖概念层到实现层

## 设计已明确但未实现

指挥官层（Phase 2）设计方案完整，等待实现：
- 情报系统：Intel 模型（时效/可信度/来源）、IntelGenerator、情报看板 UI
- 意图系统：通过参谋长模式连接指挥官和兵棋引擎，设计评审待决策
- 命令协议：Command 模型、CommandExecutor（抽象指令→兵棋操作序列）
- 多维度后果：军事态势、己方消耗、政治影响三条线

## 差距

文档与代码存在系统性不同步（`docs/STATUS.md` 列出 5 项），引擎层 Campaign 硬编码未通用化。



