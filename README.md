# qtgame-war

量潮战旗 — 以豫东战役（帝丘店战斗）为切入的回合制六角格战棋，当前以「指挥部视角」为交互原型。

长期方向：兵棋引擎作底座，指挥官的决策与意图作上层，两者之间由 LLM「参谋长」把意图翻译成可执行的作战选项——既降低战棋的入门门槛，也让指挥官游戏不再完全依赖预先写死的剧本。元目标是探究**复杂情境的建模与模拟机制**。

## 当前状态

| 模块 | 状态 |
|------|------|
| 兵棋引擎（帝丘店） | 可用：六角格地图、移动/攻击、地形、战斗结算、援军触发、回合与 AI |
| 指挥部界面 | 早期三栏稿已移除（git 历史可查）；现行交互原型见 `examples/prototype/` 龙王店战斗版 |
| 参谋长（LLM）层 | 仅 HTML/Python 原型验证，未接入 Flutter |
| 剧本（if 线） | 4 篇战役推演稿 + 剧本管理工具原型 |
| 单元测试 | 覆盖 models / controllers / views / screens |

阶段计划与结论见 [docs/dev-guide/roadmap.md](docs/dev-guide/roadmap.md)。

## 目录结构

```
qtgame-war/
├── src/studio/                  Flutter 应用
│   ├── lib/
│   │   ├── models/              领域模型（兵种、战场、战役、战斗）
│   │   ├── controllers/         GameController（ChangeNotifier）
│   │   ├── screens/             指挥部页面
│   │   └── views/               情报栏、战场、计划栏
│   ├── assets/campaigns/        战役数据（campaign / map / units.json）
│   ├── doc/                     架构与模块说明
│   └── test/                    单元测试
├── docs/
│   └── dev-guide/               开发方向、推演方法、路线图
├── examples/                    HTML/Python 实验原型，不进产品
├── assets/                      史料与剧本素材（history / scenario）
├── scripts/run.sh               启动脚本
├── STATUS.md                    现状与差距
├── CONTRIBUTING.md              工作流程与文档规范
└── AGENTS.md                    AI 协作规范
```

## 运行

```bash
scripts/run.sh            # 默认设备
scripts/run.sh linux
scripts/run.sh web
```

```bash
cd src/studio && flutter test
```

依赖 Flutter SDK `^3.11.5`；地图渲染使用 `hex_toolkit`，其余为 Flutter 模板自带依赖。

## 文档导航

| 文档 | 内容 |
|------|------|
| [docs/dev-guide/index.md](docs/dev-guide/index.md) | 开发方向：剧本为核心，AI 推演为机制核心 |
| [docs/dev-guide/method.md](docs/dev-guide/method.md) | 反事实军事推演的五层递进分析法 |
| [docs/dev-guide/roadmap.md](docs/dev-guide/roadmap.md) | Phase A–D 路线图与已完成实验结论 |
| [docs/dev-guide/yudong-sample.md](docs/dev-guide/yudong-sample.md) | 豫东样本：三个核心机制、时窗与胜利条件、验收测试 |
| [docs/dev-guide/params.md](docs/dev-guide/params.md) | 数值参数的具体落地：参数组、初值、写入位置与启用阶段 |
| [examples/scene-manager/scenes/](examples/scene-manager/scenes/) | 豫东、辽沈、淮海、平津战役 if 线（frontmatter 格式） |
| [STATUS.md](STATUS.md) | 已实现 / 未实现 / 差距 |
| [src/studio/doc/index.md](src/studio/doc/index.md) | 架构与状态管理现状 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 层级判断、重构红线、提交与文档规范 |
| [AGENTS.md](AGENTS.md) | AI 协作原则与技术约束 |

## 实验原型

`examples/` 下均为验证设计假设的独立原型，不进入产品代码：

| 目录 | 验证内容 |
|------|---------|
| `intent-prototype/` | 行动面板随意图过滤 |
| `intent-llm-test/` | 情报 → 判断 → 意图的映射链路 |
| `intent-to-action/` | 意图 → 具体作战选项的翻译 |
| `chief-of-staff-prototype/` | 参谋长五场景交互（含误导与矛盾） |
| `prototype/` | 龙王店战斗可玩原型（决心卡 + 六角格结算）；指挥部/抉择界面早期稿已移除 |
| `scene-manager/` | if 线剧本的浏览、状态流转与 DAG 分支图 |

## 工作约定

- 增量优先：只改 `src/` 直接动手；涉及 3 个以上文档才动概念层，先写 PRD。
- 功能未完成前不重构。
- 主干开发，提交即发布。规范见 [CONTRIBUTING.md](CONTRIBUTING.md)。
