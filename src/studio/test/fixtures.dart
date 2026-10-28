import 'package:studio/models/battlefield.dart';

/// 测试用注入式地形目录（模拟帝丘店，字符串 id）。
///
/// 核心不再持有全局地形单例，测试通过此目录注入 props。
final Map<String, TerrainProps> testTerrainCatalog = {
  'plain': const TerrainProps(
    name: '平原',
    moveCost: 1,
    defenseBonus: 0,
    color: 0xffb8a068,
    fillColor: 0xffa89458,
    icon: '',
  ),
  'village': const TerrainProps(
    name: '村庄',
    moveCost: 1,
    defenseBonus: 1,
    color: 0xff7a8a6a,
    fillColor: 0xff6a7a5a,
    icon: '\u25a3',
  ),
  'town': const TerrainProps(
    name: '城镇据点',
    moveCost: 2,
    defenseBonus: 2,
    color: 0xff5a4a3a,
    fillColor: 0xff4a3a2a,
    icon: '\u25a3',
  ),
  'river': const TerrainProps(
    name: '惠济河',
    moveCost: 4,
    defenseBonus: 0,
    color: 0xff3a5a7a,
    fillColor: 0xff2a4a6a,
    icon: '\u2248',
  ),
  'core_fort': const TerrainProps(
    name: '帝丘店核心',
    moveCost: 3,
    defenseBonus: 4,
    color: 0xff3a1a1a,
    fillColor: 0xff2a0a0a,
    icon: '\u{1F3F0}',
    fullCover: true,
    isCore: true,
    assaultOnly: true,
  ),
};

/// 10x7 帝丘店地图网格（字符串 id），等价于原 `Battlefield.createMapTerrain()`。
List<List<String>> testMapGrid() {
  final grid = List.generate(7, (_) => List.filled(10, 'plain'));
  void st(int c, int r, String t) {
    if (r >= 0 && r < 7 && c >= 0 && c < 10) grid[r][c] = t;
  }

  const riverCells = [
    (0, 5),
    (1, 5),
    (2, 4),
    (3, 4),
    (4, 3),
    (5, 3),
    (6, 3),
    (7, 2),
    (8, 2),
    (9, 2),
    (0, 6),
    (1, 6),
  ];
  for (final (c, r) in riverCells) {
    st(c, r, 'river');
  }

  st(5, 4, 'core_fort');
  st(6, 4, 'town');
  st(4, 4, 'town');
  st(5, 5, 'town');
  st(3, 2, 'town');

  st(4, 2, 'village');
  st(2, 5, 'village');
  st(1, 4, 'village');
  st(7, 1, 'village');
  st(6, 1, 'village');
  st(4, 1, 'village');
  st(1, 2, 'village');
  st(8, 5, 'village');
  st(0, 3, 'village');
  st(9, 4, 'village');

  return grid;
}
