# 地图

这个 Battlefield 模块是目前整个项目里职责最纯粹、实现最扎实的一个。它专注于六边形网格的数学、像素映射和地形定义，没有越界去管回合、单位或战斗——这种克制在之前两个类中差不多丢光了，所以读起来舒服得多。

—

模块职责一览

组成 职责
TerrainType 枚举 地形种类标识
TerrainProps 类 地形属性容器：名称、移动消耗、防御、颜色、图标、掩体/核心
terrainProps 全局字典 枚举→属性映射，全局只读
HexPoint 轻量坐标 (x, y)
Battlefield 静态类 六边形网格几何、邻居、距离、像素点击、地图工厂

—

亮点

1. 六边形算法干净且正确

· 奇数行偏移 (odd‑r) 的布局规整，hexCenter 正确处理了奇数行右移 0.75 个边长。
· getNeighbors 使用六方向偏移表，奇数行/偶数行分开，无重复计算。
· hexDistance 采用轴向转换公式，避免了逐格 BFS，高效且数学优雅。
· pixelToHex 的剔除逻辑（外接圆快速判断 + 斜边约束）贴近六边形几何，选点准确性高。

这些底层算法很容易写错，但当前实现没有明显 bug，说明作者对六边形网格坐标系理解到位。

2. 地形属性分离得当

· TerrainProps 存储所有静态数据，terrainProps 全局映射一次性定义。
· Game 类里的 terrainDefense / inFullCover / inCore 都从这个映射取数据，避免了散落在各处的魔法数字。
· 颜色和图标也被收纳进来，使得渲染层可以直接用，不需要额外查表。

3. 地图工厂纯函数

createMapTerrain() 返回一个新的二维 TerrainType 列表，不依赖外部状态，无副作用。内部用辅助函数 st 赋值，写法虽朴素，但保证了地图生成的清晰性。

4. 常量集中，UI 尺度易得

canvasWidth / canvasHeight 基于行列数和间距自动计算，调用方可以直接用这些值建画布，无需自己推导。

—

可优化与扩展点

1. 地图数据与工厂硬编码

目前的河流、城镇坐标直接以常量列表的形式写入 createMapTerrain。如果要增加第二个地图（比如另一个战场），就必须写一个新的工厂函数。

建议：将地图数据抽离为纯数据描述，例如：

```dart
const defaultTerrainMapData = [
  // (col, row, type)
  (5,4, TerrainType.coreFort),
  ...
];
```

createMapTerrain 接收这类数据作为参数，或提供静态方法 fromData，让自己成为一个通用地图渲染器。这样地图变成配置，可以放在 JSON 或独立文件中。

2. 可变二维列表暴露

createMapTerrain 返回的 List<List<TerrainType>> 是标准的可变列表，外部拿到后可以随意修改 grid[r][c]。在 Game 里这张地图是被多处读取的，但理论上并没有去改地形的逻辑（地形应该是静态的）。如果某处代码意外修改了格子，会导致诡异 bug。

建议：返回不可变视图，例如使用 UnmodifiableListView，或将地形封装成专门的 TerrainMap 类，仅提供 terrainAt(col, row) 接口，底层用内部二维列表。

3. 六边形常数假定唯一战役

cols = 10、rows = 7、hexSize = 27、paddingX/Y 全部写死。地图尺寸和 UI 缩放被耦合在一起。若需要放大地图或适配不同屏幕，就必须改动这些常量。

建议：

· 将网格尺寸 (cols, rows) 与屏幕布局参数分离。前者属于地图配置，后者属于渲染参数。
· hexSize 可由外部传入，或根据视口动态计算；canvasWidth/Height 也可以变成方法而不是静态常量，接受 hexSize 等参数。

4. 像素选点的精度代价

pixelToHex 双层循环（遍历所有 70 个格子）对目前的地图规模完全没问题，但如果未来地图扩大，可能带来性能瓶颈。更高效的算法是直接通过轴向坐标反算，但当前规模下优化没必要，这只是个潜在的笔记。

5. 缺失注释

算法部分（尤其是 hexDistance 的轴向转换和 pixelToHex 的几何判断）没有注释，其他开发者需要花时间反推公式。六边形坐标系的转换公式对不熟悉的人很晦涩，加几行注释会极大提升可维护性。

—

与主线的连接

Battlefield 不参与回合、胜负、AI，但它是整条主线的物理基础：

· 移动：Game.getMoveRange 调用 Battlefield.getNeighbors 获取相邻格子，依赖 terrainProps 的 moveCost。
· 攻击：Game.getAttackTargets 调用 hexDistance 计算距离。
· UI 交互：pixelToHex 负责将鼠标/触摸坐标转为格子，使玩家可以点选单位或移动目标。
· 绘制：hexCenter / hexVertices 提供 Canvas 绘制所需坐标，TerrainProps 提供颜色和图标。

目前它只是一个静态工具箱，被 Game 类里那些“规则函数”反复调用。重构时，Battlefield 几乎不需要动，只需要把地图数据喂给新的 Game 或 Scenario 类即可。

—

总体评价

Battlefield 模块做到了单一职责、算法正确、接口清晰，是三个类里设计最好的一个。它的缺点集中在“静态常量硬编码”和“地图数据耦合”，而不是结构或逻辑混乱。在后续迭代中，只需要将这些硬编码转移到配置文件里，就能从“特定战场的网格工具”平滑升级为“通用六边形战棋地形系统”。与你之前吐槽的 Game 和 Campaign 相比，这个模块算是一股清流，正好说明了不同研发模块间的水平落差。
