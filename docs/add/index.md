# 模块化方案

## 当前结构问题

`src/index.html` 是一个 548 行的单文件，所有逻辑平铺在 `<script>` 内：

```
全局变量(6) → 数据初始化 → 纯函数(6) → UI函数(5) → 事件处理(3)
```

问题：
- 没有命名空间，所有函数和变量在全局作用域
- CSS 选择器与 HTML 结构耦合
- 数据变更逻辑与渲染逻辑混在一起
- 场景初始化（unit 位置、intel 文本）硬编码在 JS 中

## 约束条件

- 保持"单文件、零依赖、可直接浏览器打开"
- ES Modules 不可用（file:// 协议不支持 CORS）
- 不引入构建工具

## 模块划分

在单文件内用对象命名空间实现模块化：

```
Game           游戏状态管理
├── State      核心状态（turn, control, hexData）
├── HexGrid    六角格引擎（坐标、地形、渲染）
├── Intel      情报系统（报告、可信度）
├── Command    命令系统（选项、执行、结果）
└── UI         界面管理（面板、弹窗、HUD）
```

## 详细设计

### Game.State — 核心状态

```js
const Game = {};
Game.State = {
    turn: 12,
    control: 68,
    initiative: '我方',
    fogLevel: '高',
    selectedCommand: null,
    hexData: [],
    logs: [],
    
    init() { /* 初始化棋盘和单位 */ },
    nextTurn() { this.turn++; },
    updateControl(val) { this.control = val; },
};
```

职责：纯数据，不操作 DOM。所有状态变更通过方法调用，方便追踪。

### Game.HexGrid — 六角格引擎

```js
Game.HexGrid = {
    HEX_SIZE: 32,
    ROWS: 9,
    COLS: 11,
    
    hexToPixel(row, col) { /* 坐标转换 */ },
    getTerrainColor(type) { /* 颜色映射 */ },
    getTerrainPattern(type) { /* 纹理映射 */ },
    getUnitIcon(name) { /* 图标映射 */ },
};
```

职责：纯计算 + 映射表，不涉及 DOM。可独立测试。

### Game.Intel — 情报系统

```js
Game.Intel = {
    reports: [
        { title: '侦察报告', credibility: 'cred', text: '...' },
        { title: '模糊情报', credibility: 'ques', text: '...' },
        { title: '干扰信息', credibility: 'false', text: '...' },
        { title: '后勤报告', credibility: 'cred', text: '...' },
    ],
    
    render(containerId) { /* 渲染情报列表 */ },
};
```

职责：情报数据 + 渲染逻辑。数据从硬编码逐步迁移为外部输入。

### Game.Command — 命令系统

```js
Game.Command = {
    options: {
        A: { label: '正面推进', risk: '...', desc: '...' },
        B: { label: '侧翼包抄', risk: '...', desc: '...' },
        C: { label: '防守反击', risk: '...', desc: '...' },
        custom: { label: '自定义命令 (AI参谋)', risk: '...' },
    },
    results: { /* 执行结果映射 */ },
    
    select(cmd) { /* 选中命令 */ },
    confirm() { /* 确认弹窗 */ },
    execute() { /* 执行并更新状态 */ },
    updateMap(cmd) { /* 更新 hexData 后触发重绘 */ },
};
```

职责：命令选项定义、选择逻辑、执行逻辑。命令与地图的联动通过回调实现。

### Game.UI — 界面管理

```js
Game.UI = {
    renderHexGrid() { /* 遍历 hexData 生成 SVG */ },
    switchTab(tab) { /* Tab 切换 */ },
    showResult(data) { /* 结果弹窗 */ },
    closeResult() { /* 关闭弹窗 */ },
    updateHUD() { /* 更新回合/控制率等 */ },
    updateLog(text) { /* 追加日志 */ },
};
```

职责：所有 DOM 操作集中在此。数据变更通过调用 Game.State 的方法完成，然后触发 UI 重绘。

## 数据流

```
用户操作 → Game.Command.select()
                  ↓
         Game.Command.confirm()
                  ↓
         Game.Command.execute()
                  ↓
         Game.State.nextTurn()
         Game.State.updateControl()
                  ↓
         Game.UI.updateHUD()
         Game.UI.updateLog()
         Game.UI.renderHexGrid()
```

所有数据变更走 Game.State，所有 DOM 操作走 Game.UI。模块之间不直接操作对方的内部状态。

## 文件内物理组织

单文件内按以下顺序组织：

```
1. /* ====== Game.State ====== */
2. /* ====== Game.HexGrid ====== */  
3. /* ====== Game.Intel ====== */
4. /* ====== Game.Command ====== */
5. /* ====== Game.UI ====== */
6. /* ====== Init ====== */     ← 调用 Game.State.init() + Game.UI.renderHexGrid()
```

每个模块内部：数据定义 → 方法定义。不跨模块引用，只通过 Game 命名空间访问。

## 未来迁移路径

如果后续决定拆分为多文件，只需：

1. 将每个模块放入独立 `.js` 文件
2. 在 HTML 中用 `<script>` 按依赖顺序加载
3. 或者引入构建工具打包回单文件

拆分后的目录结构：

```
src/
├── index.html           # HTML + CSS
├── js/
│   ├── state.js         # Game.State
│   ├── hexgrid.js       # Game.HexGrid
│   ├── intel.js         # Game.Intel
│   ├── command.js       # Game.Command
│   ├── ui.js            # Game.UI
│   └── init.js          # 入口
└── css/
    └── style.css        # 所有样式
```
