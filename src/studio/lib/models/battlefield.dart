import 'dart:math';
import 'package:hex_toolkit/hex_toolkit.dart';

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

  static Hex _hex(int col, int row) =>
      Hex.fromOffset(GridOffset(col, row));

  static HexPoint hexCenter(int col, int row) {
    final p = _hex(col, row).centerPoint(hexSize);
    return HexPoint(paddingX + p.x, paddingY + p.y);
  }

  static List<HexPoint> hexVertices(double cx, double cy, double size) {
    return List.generate(6, (i) {
      final a = pi / 180 * (60 * i);
      return HexPoint(cx + size * cos(a), cy + size * sin(a));
    });
  }

  static (int col, int row)? pixelToHex(double mx, double my) {
    final hex = Hex.fromPixelPoint(
      PixelPoint(mx - paddingX, my - paddingY), hexSize);
    final off = hex.toOffset();
    if (off.q >= 0 && off.q < cols && off.r >= 0 && off.r < rows) {
      return (off.q, off.r);
    }
    return null;
  }

  static List<(int, int)> getNeighbors(int col, int row) {
    return _hex(col, row).neighbors()
        .map((h) {
          final o = h.toOffset();
          return (o.q, o.r);
        })
        .where((n) => n.$1 >= 0 && n.$1 < cols && n.$2 >= 0 && n.$2 < rows)
        .toList();
  }

  static int hexDistance(int c1, int r1, int c2, int r2) {
    return _hex(c1, r1).distanceTo(_hex(c2, r2));
  }

  // Computed for 10x7 grid, hexSize=27
  // Pointy-top hex grid: widest at col=9, odd row; tallest at row=6
  static const double canvasWidth = 572;
  static const double canvasHeight = 350;

  static List<List<TerrainType>> createMapFromJson(Map<String, dynamic> json) {
    final grid = List.generate(rows, (_) => List.filled(cols, TerrainType.plain));
    void st(int c, int r, TerrainType t) {
      if (r >= 0 && r < rows && c >= 0 && c < cols) grid[r][c] = t;
    }
    final terrains = json['terrains'] as Map<String, dynamic>;
    for (final entry in terrains.entries) {
      final t = _terrainFromKey(entry.key);
      for (final cell in (entry.value as List)) {
        st(cell[0], cell[1], t);
      }
    }
    return grid;
  }

  static TerrainType _terrainFromKey(String key) {
    switch (key) {
      case 'river': return TerrainType.river;
      case 'core_fort': return TerrainType.coreFort;
      case 'town': return TerrainType.town;
      case 'village': return TerrainType.village;
      default: return TerrainType.plain;
    }
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
