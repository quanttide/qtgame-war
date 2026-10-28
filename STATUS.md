# qtgame-war 状态报告

## 已实现

- **兵棋推演引擎**（`src/studio/`，Flutter）：六角格地图、单位移动/攻击、战斗结算、援军触发、回合与 AI，可运行，有单元测试
- **龙王店战斗可玩原型**（`examples/prototype/`）：决心卡 + 六角格结算的完整可玩闭环，史实逐回合对应
- **剧本管理工具**（`examples/scene-manager/`）：frontmatter schema v3 + DAG 分支图，4 篇战役剧本已重构入库
- **Phase A/B 实验**（`examples/intent-*`、`chief-of-staff-prototype`）：意图→行动过滤、情报→意图映射、参谋长交互均已验证，结论见各 examples 目录与 Git 历史

## 未实现（Phase C，见 roadmap）

- 情报系统：Intel 模型（时效/可信度/来源）、IntelGenerator、情报看板联动
- 意图集成：参谋长（LLM）理解意图接口、行动面板随意图过滤
- 命令协议：Command 模型、CommandExecutor（抽象指令→兵棋操作序列）

## 差距

studio 三栏界面中，左右两栏未接引擎：情报为写死的展示（勾选采信不影响任何状态），预案为纯装饰（不影响部署与命令），签署仪式缺失（仅「结束回合」按钮）。
