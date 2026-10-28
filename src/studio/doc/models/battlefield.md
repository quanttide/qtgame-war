# Battlefield 模块

## 职责

六边形战场几何（静态方法，基于 hex_toolkit）+ 地形容器 `TerrainBook`。**地形是剧本数据**：地图网格、地形目录（props per id）、网格尺寸全部由剧本注入，核心不持有任何全局地形单例，也检索不到「帝丘店」「惠济河」这类剧本专名。

## 地形：字符串 id + 注入目录

地形不再用 `enum TerrainType`，改用**字符串 id**（如 `'plain'`/`'river'`/`'core_fort'`，与 `map.json` 的 terrains 键一致）。每种地形的属性（名称、移动消耗、防御、颜色、图标、掩体、是否核心、是否仅突击可入）由剧本的 **catalog**（`Map<String, TerrainProps>`）提供，`TerrainBook` 把网格 + 目录 + 尺寸绑成一个值对象一起流动。

### TerrainProps
| 字段 | 类型 | 说明 |
|------|------|------|
| name | String | 显示名称（剧本地名，如「惠济河」；通用剧本可叫「河流」） |
| moveCost | int | 移动消耗 |
| defenseBonus | int | 防御加成 |
| color | int | 边框颜色（ARGB） |
| fillColor | int | 填充颜色（ARGB） |
| icon | String | 地形图标 |
| fullCover | bool | 全掩体（隔格不可命中） |
| isCore | bool | 核心据点（攻占胜负条件） |
| assaultOnly | bool | 仅突击部队可进入（要塞） |

`TerrainProps.plain` 是回退默认（越界/未知 id 时返回），中性无地名。

### TerrainBook
| 字段 | 类型 | 说明 |
|------|------|------|
| grid | `List<List<String>>` | grid[row][col] = 地形 id |
| catalog | `Map<String, TerrainProps>` | id → 属性 |
| cols / rows | int | 网格尺寸 |

方法：
- `propsAt(col, row)` → 该格 `TerrainProps`（越界/未知 id 回退 `TerrainProps.plain`）
- 核心读 `book.propsAt(col, row)` 取地形效果；不读全局。

## 几何常量

| 常量 | 值 | 说明 |
|------|-----|------|
| hexSize | 27 | 六边形半径（像素），跨剧本共用 |
| paddingX / paddingY | 50 / 40 | 画布留白 |

网格尺寸（cols/rows）不再由 `Battlefield` 静态持有，改由 `TerrainBook` / `CampaignConfig.gridCols·gridRows` 提供——不同剧本可有不同地图大小。

## 方法

- `hexCenter(col, row)` → 像素中心点
- `hexVertices(cx, cy, size)` → 六边形六顶点
- `hexDistance(c1, r1, c2, r2)` → 六边形距离（纯几何，不需尺寸）
- `pixelToHex(mx, my, cols, rows)` → 网格坐标（超出返回 null，需尺寸判界）
- `getNeighbors(col, row, cols, rows)` → 相邻格子列表（需尺寸判界）
- `canvasSize(cols, rows)` → 由全部格中心推出的画布尺寸（任意网格自适应）
- `createMapGrid(json, cols, rows)` → 从 `map.json`（`{"terrains": {id: [[c,r],…]}}`）生成 `List<List<String>>`，默认 `'plain'`

## 帝丘店剧本数据（非核心）

帝丘店的地形目录与地图坐标属剧本数据，经 `CampaignConfig` 注入，见 `doc/models/game.md`；本模块不含任何帝丘店专名。

## 变更记录

- 初版：`TerrainType` 枚举 + 全局 `terrainProps` map + 静态 `cols/rows` + 硬编码 `createMapTerrain()`
- v0.1.0：**地形数据化**——枚举改字符串 id，全局 map 改注入 catalog，静态尺寸改随 `TerrainBook`/config，硬编码地图改由 `map.json` 注入；`TerrainProps` 增 `assaultOnly`（要塞仅突击可入，取代原 `TerrainType.coreFort` 分支）
