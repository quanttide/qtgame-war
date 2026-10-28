# Battlefield 模块

## 职责

六边形战场工具类（静态方法），基于 hex_toolkit 实现网格几何、坐标转换和地形系统。

## 枚举与数据结构

### TerrainType
```dart
enum TerrainType { plain, village, town, river, coreFort }
```

### TerrainProps
| 字段 | 类型 | 说明 |
|------|------|------|
| name | String | 显示名称 |
| moveCost | int | 移动消耗 |
| defenseBonus | int | 防御加成 |
| color | int | 边框颜色（ARGB） |
| fillColor | int | 填充颜色（ARGB） |
| icon | String | 地形图标 |
| fullCover | bool | 全掩护 |
| isCore | bool | 核心据点 |

### terrainProps 映射表
| 地形 | 名称 | 移动消耗 | 防御加成 | 特殊 |
|------|------|---------|---------|------|
| plain | 平原 | 1 | 0 | - |
| village | 村庄 | 1 | 1 | - |
| town | 城镇据点 | 2 | 2 | - |
| river | 惠济河 | 4 | 0 | - |
| coreFort | 帝丘店核心 | 3 | 4 | fullCover, isCore |

## 常量

| 常量 | 值 | 说明 |
|------|-----|------|
| hexSize | 27 | 六边形半径（像素） |
| cols | 10 | 网格列数 |
| rows | 7 | 网格行数 |
| canvasWidth | 572 | 画布宽度 |
| canvasHeight | 350 | 画布高度 |

## 方法

- `hexCenter(col, row)` → 像素中心点
- `pixelToHex(mx, my)` → 网格坐标（超出返回 null）
- `getNeighbors(col, row)` → 相邻格子列表
- `hexDistance(c1, r1, c2, r2)` → 六边形距离
- `createMapFromJson(json)` → 从 JSON 创建地形网格
