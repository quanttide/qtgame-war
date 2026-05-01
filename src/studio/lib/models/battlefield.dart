import 'dart:math';

enum TerrainType {
  plain,
  village,
  town,
  river,
  coreFort,
}

class TerrainProps {
  final String name;
  final int moveCost;
  final int defenseBonus;
  final int color;
  final int fillColor;
  final String icon;
  final bool fullCover;
  final bool isCore;

  const TerrainProps({
    required this.name,
    required this.moveCost,
    required this.defenseBonus,
    required this.color,
    required this.fillColor,
    required this.icon,
    this.fullCover = false,
    this.isCore = false,
  });
}

final Map<TerrainType, TerrainProps> terrainProps = {
  TerrainType.plain: TerrainProps(
    name: '平原', moveCost: 1, defenseBonus: 0,
    color: 0xffb8a068, fillColor: 0xffa89458, icon: '',
  ),
  TerrainType.village: TerrainProps(
    name: '村庄', moveCost: 1, defenseBonus: 1,
    color: 0xff7a8a6a, fillColor: 0xff6a7a5a, icon: '\u25a3',
  ),
  TerrainType.town: TerrainProps(
    name: '城镇据点', moveCost: 2, defenseBonus: 2,
    color: 0xff5a4a3a, fillColor: 0xff4a3a2a, icon: '\u25a3',
  ),
  TerrainType.river: TerrainProps(
    name: '惠济河', moveCost: 4, defenseBonus: 0,
    color: 0xff3a5a7a, fillColor: 0xff2a4a6a, icon: '\u2248',
  ),
  TerrainType.coreFort: TerrainProps(
    name: '帝丘店核心', moveCost: 3, defenseBonus: 4,
    color: 0xff3a1a1a, fillColor: 0xff2a0a0a, icon: '\u{1F3F0}',
    fullCover: true, isCore: true,
  ),
};

class HexPoint {
  final double x, y;
  const HexPoint(this.x, this.y);
}

class Battlefield {
  static const double hexSize = 27;
  static const int cols = 10;
  static const int rows = 7;
  static const double paddingX = 50;
  static const double paddingY = 40;

  static double get sqr3 => sqrt(3);
  static double get colSpacing => 1.5 * hexSize;
  static double get rowSpacing => sqr3 * hexSize;
  static double get oddRowOffset => 0.75 * hexSize;
  static double get canvasWidth => cols * colSpacing + hexSize * 0.5 + paddingX * 2;
  static double get canvasHeight => rows * rowSpacing + hexSize * 0.5 + paddingY * 2;

  static HexPoint hexCenter(int col, int row) {
    double x = paddingX + col * colSpacing + hexSize;
    if (row % 2 == 1) x += oddRowOffset;
    double y = paddingY + row * rowSpacing + rowSpacing / 2;
    return HexPoint(x, y);
  }

  static List<HexPoint> hexVertices(double cx, double cy, double size) {
    return List.generate(6, (i) {
      double a = pi / 180 * (60 * i);
      return HexPoint(cx + size * cos(a), cy + size * sin(a));
    });
  }

  static (int col, int row)? pixelToHex(double mx, double my) {
    (int, int)? best;
    double bestDist = double.infinity;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final center = hexCenter(c, r);
        double dx = (mx - center.x).abs();
        double dy = (my - center.y).abs();
        if (dx > hexSize || dy > rowSpacing / 2) continue;
        if (dx > hexSize / 2 && dy > (hexSize - dx) * sqr3) continue;
        double dist = sqrt(dx * dx + dy * dy);
        if (dist < bestDist) {
          bestDist = dist;
          best = (c, r);
        }
      }
    }
    return best;
  }

  static List<(int, int)> getNeighbors(int col, int row) {
    final offsets = row % 2 == 1
        ? [(0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 0)]
        : [(-1, -1), (0, -1), (1, 0), (0, 1), (-1, 1), (-1, 0)];
    final result = <(int, int)>[];
    for (final (dc, dr) in offsets) {
      int nc = col + dc;
      int nr = row + dr;
      if (nc >= 0 && nc < cols && nr >= 0 && nr < rows) {
        result.add((nc, nr));
      }
    }
    return result;
  }

  static int hexDistance(int c1, int r1, int c2, int r2) {
    int q1 = c1 - (r1 - (r1 & 1)) ~/ 2;
    int q2 = c2 - (r2 - (r2 & 1)) ~/ 2;
    return max(max((q1 - q2).abs(), (r1 - r2).abs()), (-q1 - r1 - (-q2 - r2)).abs());
  }

  static List<List<TerrainType>> createMapTerrain() {
    final grid = List.generate(rows, (_) => List.filled(cols, TerrainType.plain));

    void st(int c, int r, TerrainType t) {
      if (r >= 0 && r < rows && c >= 0 && c < cols) grid[r][c] = t;
    }

    const riverCells = [
      (0, 5), (1, 5), (2, 4), (3, 4), (4, 3),
      (5, 3), (6, 3), (7, 2), (8, 2), (9, 2),
      (0, 6), (1, 6),
    ];
    for (final (c, r) in riverCells) { st(c, r, TerrainType.river); }

    st(5, 4, TerrainType.coreFort);
    st(6, 4, TerrainType.town);
    st(4, 4, TerrainType.town);
    st(5, 5, TerrainType.town);

    st(3, 2, TerrainType.town);
    st(4, 2, TerrainType.village);

    st(2, 5, TerrainType.village);
    st(1, 4, TerrainType.village);
    st(7, 1, TerrainType.village);
    st(6, 1, TerrainType.village);
    st(4, 1, TerrainType.village);

    st(1, 2, TerrainType.village);
    st(8, 5, TerrainType.village);
    st(0, 3, TerrainType.village);
    st(9, 4, TerrainType.village);

    return grid;
  }
}
