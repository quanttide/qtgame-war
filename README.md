# qtgame-war

量潮战旗游戏 — 一个"指挥官视角"的回合制战棋游戏原型。

## 项目结构

```
qtgame-war/
├── docs/
│   ├── index.md            # 游戏设计文档（概念层：动机、玩法、建模）
│   └── qa/
│       ├── interaction.md  # 交互设计评估报告
│       └── prototype.md    # 原型展开分析 & 量化评分
├── examples/
│   └── prototype.html      # 可运行的 HTML 原型（505行，无依赖）
├── tests/
│   └── audit.py            # 视觉量化审计工具（依赖 Pillow）
├── CONTRIBUTING.md         # 贡献指南（设计评审流程）
├── AGENTS.md               # AI 协作规范（元认知）
└── README.md               # 本文件
```

## 核心设计

- **游戏类型**：回合制战棋，指挥官视角决策
- **两种玩法**：互动剧本模式（判断→命令→结算） + 兵棋推演模式（自定义部署）
- **技术选型**：纯前端单文件 HTML/CSS/JS，零依赖
- **渲染方式**：SVG 六角格地图（9x11 网格）

## 关键文件

| 文件 | 用途 | 行数 |
|------|------|------|
| `docs/index.md` | 设计概念起点 | 29 |
| `examples/prototype.html` | 可交互原型 | 548 |
| `docs/qa/prototype.md` | 展开分析 + 五项评分 | ~220 |
| `docs/qa/interaction.md` | 交互设计评审 v2 | ~140 |
| `tests/audit.py` | 量化视觉测量 | ~80 |

## 原型交互流程

选命令 → 确认弹窗(看风险) → 确认执行 → 结果弹窗 + 地图更新 + 日志记录 → 关闭继续

## 运行时

原型可直接在浏览器打开，无需构建工具。
审计工具需 Python 3 + Pillow，配合 Chrome headless 截图使用。
