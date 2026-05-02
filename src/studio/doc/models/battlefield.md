# Battlefield 模块现状

## 当前状态

六边形网格几何委托给 **hex_toolkit**（RedBlobGames 标准算法），地形定义自行维护。修复了旧实现中坐标间距误差（相邻 hex 间距从 50.96 修正为 46.77）。

## 优点

- 几何层由 `hex_toolkit 1.0.4` 处理（零依赖，框架无关，Cube/Offset 坐标转换）
- 地形属性分离（TerrainProps + terrainProps 映射）
- 地图工厂纯函数
- 获得免费扩展：寻路（cheapestPathTo）、范围（ring/spiral）、视线（line）

## 可优化点

1. **地图数据硬编码** — 河流/城镇坐标写在 createMapTerrain()，换地图需改代码
2. **可变列表暴露** — 返回的 List<List<TerrainType>> 可被外部修改
3. **常量绑定特定战役** — cols=10, rows=7, hexSize=27 写死

## 改进方向

- 地图数据抽离为配置（常量表或 JSON）
- 返回不可变视图或封装为 TerrainMap 类
- 网格尺寸与渲染参数分离

## 依赖决策

| 选项 | 结论 |
|------|------|
| 自己封装六边形算法 | 否决：hex_toolkit 零依赖、代码量和维护成本相近 |
| 引入 hex_toolkit | **采用**：标准算法 + 路径寻找/范围算法免费获得 |
| 其他六边形库（hexagon、hexagonal_grid_widget） | 否决：偏 UI 或已过时 |

选型理由：hex_toolkit 基于 RedBlobGames 标准算法，零依赖，框架无关，替换成本低。地形系统始终自行维护。如果未来库不维护，可回退为最小自实现（算法固定、可预测）。
