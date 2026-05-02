# Battlefield 模块现状

## 当前状态

六边形战场工具类（静态方法），基于 hex_toolkit 实现网格几何、坐标转换和地形系统。无实例状态，所有方法为静态。

## 枚举与数据结构

### TerrainType 枚举
```dart
enum TerrainType { plain, village, town, river, coreFort }
```

### TerrainProps 地形属性
| 字段 | 类型 | 说明 |
|------|------|------|
| name | String | 显示名称（如"平原"、"村庄"） |
| moveCost | int | 移动消耗，越大越难通过 |
| defenseBonus | int | 防御加成，影响战斗防御计算 |
| color | int | 边框颜色（ARGB） |
| fillColor | int | 填充颜色（ARGB） |
| icon | String | 地形图标字符，空字符串表示无图标 |
| fullCover | bool | 是否提供全掩护，默认 false |
| isCore | bool | 是否为核心据点（帝丘店），默认 false |

### terrainProps 映射表
| 地形 | 名称 | 移动消耗 | 防御加成 | 图标 | 特殊 |
|------|------|---------|---------|------|------|
| plain | 平原 | 1 | 0 | 无 | - |
| village | 村庄 | 1 | 1 | ■ | - |
| town | 城镇据点 | 2 | 2 | ■ | - |
| river | 惠济河 | 4 | 0 | ≈ | - |
| coreFort | 帝丘店核心 | 3 | 4 | 🏰 | fullCover=true, isCore=true |

### HexPoint 类
| 字段 | 类型 | 说明 |
|------|------|------|
| x | double | 像素坐标 X |
| y | double | 像素坐标 Y |

## 常量说明

| 常量 | 类型 | 值 | 说明 |
|------|------|-----|------|
| hexSize | double | 27 | 六边形半径（像素） |
| cols | int | 10 | 网格列数 |
| rows | int | 7 | 网格行数 |
| paddingX | double | 50 | 画布左内边距 |
| paddingY | double | 40 | 画布上内边距 |
| canvasWidth | double | 572 | 画布宽度（根据网格计算） |
| canvasHeight | double | 350 | 画布高度（根据网格计算） |

## 方法说明

### 坐标转换
- `static HexPoint hexCenter(int col, int row)` — 返回指定网格坐标的像素中心点
- `static (int col, int row)? pixelToHex(double mx, double my)` — 像素坐标转网格坐标，超出范围返回 null

### 网格几何
- `static List<HexPoint> hexVertices(double cx, double cy, double size)` — 返回六边形 6 个顶点的像素坐标
- `static List<(int, int)> getNeighbors(int col, int row)` — 返回指定格子的相邻坐标列表（过滤边界）
- `static int hexDistance(int c1, int r1, int c2, int r2)` — 计算两个格子之间的六边形距离

### 地图生成
- `static List<List<TerrainType>> createMapTerrain()` — 创建 10×7 的地形网格（硬编码方式，已弃用）
- `static List<List<TerrainType>> createMapFromJson(Map<String, dynamic> json)` — 从 JSON 数据创建地形网格，数据格式参见 `assets/campaigns/diqiudian/map.json`

## 使用示例

```dart
// 获取格子中心像素坐标
final center = Battlefield.hexCenter(5, 3);
print('像素坐标: (${center.x}, ${center.y})');

// 点击像素坐标转网格坐标
final hex = Battlefield.pixelToHex(tapX, tapY);
if (hex != null) {
  final (col, row) = hex;
  print('点击格子: ($col, $row)');
}

// 获取相邻格子
final neighbors = Battlefield.getNeighbors(5, 3);
print('相邻格子: $neighbors'); // [(5,2), (6,3), (5,4), (4,3)...]

// 计算距离
final dist = Battlefield.hexDistance(0, 0, 9, 6);
print('距离: $dist');

// 创建地图（JSON 方式）
final mapJson = jsonDecode(...);
final terrain = Battlefield.createMapFromJson(mapJson);
print('地形: ${terrain[5][4]}'); // TerrainType.coreFort

// 查询地形属性
final props = terrainProps[terrain[3][2]]!;
print('${props.name}, 移动消耗: ${props.moveCost}, 防御: ${props.defenseBonus}');
```

## 问题与技术债

| 问题 | 状态 | 说明 |
|------|------|------|
| 地图数据硬编码 | ✅ 已解决 | 通过 createMapFromJson 从 JSON 加载 |
| 可变列表暴露 | ❌ 待解决 | createMapTerrain() 返回 List<List<TerrainType>>，可被外部修改 |
| 常量绑定特定战役 | ❌ 待解决 | cols=10, rows=7, hexSize=27 写死，无法复用给其他战役 |
| 地形属性硬编码 | ❌ 待解决 | terrainProps 映射表写死，无法动态配置 |
| 无 TerrainMap 封装 | ❌ 待解决 | 缺少封装类，直接操作二维列表，无类型安全 |

## 已解决

- ✅ 六边形算法外置：基于 hex_toolkit（RedBlobGames 标准算法），零依赖
- ✅ 地形属性分离：TerrainProps 类 + terrainProps 映射表
- ✅ 地图工厂纯函数：createMapTerrain() 无副作用

## 改进方向

- 地图数据抽离为配置（常量表或 JSON），支持多战役
- 返回不可变视图或封装为 TerrainMap 类，提供类型安全的访问方法
- 网格尺寸与渲染参数分离，支持动态画布大小
- 地形属性配置化，支持不同战役的地形变体
