import 'dart:math';
import 'package:hex_toolkit/hex_toolkit.dart';

/// 地形属性。一条记录 = 一种地形 id 在某剧本下的全部属性。
/// 字段全部中性，地名（如「惠济河」「帝丘店核心」）由剧本 catalog 取值，核心不写死。
class TerrainProps {
  final String name;
  final int moveCost;
  final int defenseBonus;
  final int color;
  final int fillColor;
  final String icon;
  final bool fullCover;
  final bool isCore;
  final bool assaultOnly;

  const TerrainProps({
    required this.name,
    required this.moveCost,
    required this.defenseBonus,
    required this.color,
    required this.fillColor,
    required this.icon,
    this.fullCover = false,
    this.isCore = false,
    this.assaultOnly = false,
  });

  /// 越界/未知 id 的回退默认（中性平原，无地名）。
  static const plain = TerrainProps(
    name: '',
    moveCost: 1,
    defenseBonus: 0,
    color: 0xffb8a068,
    fillColor: 0xffa89458,
    icon: '',
  );
}

/// 地形容器：把「网格 + 地形目录 + 尺寸」绑成一个值对象一起流动。
/// 核心只读注入的 [catalog]，不持有任何全局地形单例。
class TerrainBook {
  /// grid[row][col] = 地形 id（字符串，如 'plain'/'core_fort'）
  final List<List<String>> grid;

  /// id → 属性（剧本注入）
  final Map<String, TerrainProps> catalog;

  final int cols;
  final int rows;

  TerrainBook({
    required this.grid,
    required this.catalog,
    required this.cols,
    required this.rows,
  });

  /// 取该格地形属性；越界或未知 id 回退 [TerrainProps.plain]。
  TerrainProps propsAt(int col, int row) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) {
      return TerrainProps.plain;
    }
    return catalog[grid[row][col]] ?? TerrainProps.plain;
  }
}

class HexPoint {
  final double x, y;
  const HexPoint(this.x, this.y);
}

class Battlefield {
  static const double hexSize = 27;
  static const double paddingX = 50;
  static const double paddingY = 40;

  static Hex _hex(int col, int row) => Hex.fromOffset(GridOffset(col, row));

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

  static (int col, int row)? pixelToHex(
    double mx,
    double my,
    int cols,
    int rows,
  ) {
    final hex = Hex.fromPixelPoint(
      PixelPoint(mx - paddingX, my - paddingY),
      hexSize,
    );
    final off = hex.toOffset();
    if (off.q >= 0 && off.q < cols && off.r >= 0 && off.r < rows) {
      return (off.q, off.r);
    }
    return null;
  }

  static List<(int, int)> getNeighbors(int col, int row, int cols, int rows) {
    return _hex(col, row)
        .neighbors()
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

  /// 由全部格中心推出画布尺寸（任意网格自适应）。返回 (宽, 高)。
  /// 尖顶六边形：水平半宽 = √3/2·size，垂直半高 = size。
  static (double, double) canvasSize(int cols, int rows) {
    double maxX = 0, maxY = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final p = hexCenter(c, r);
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }
    final halfW = sqrt(3) / 2 * hexSize;
    return (maxX + halfW + paddingX, maxY + hexSize + paddingY);
  }

  /// 从 map.json（`{"terrains": {id: [[c,r],…]}}`）生成地形网格，默认 'plain'。
  /// 键即地形 id，须在剧本 catalog 中有对应 props。
  static List<List<String>> createMapGrid(
    Map<String, dynamic> json,
    int cols,
    int rows,
  ) {
    final grid = List.generate(rows, (_) => List.filled(cols, 'plain'));
    void st(int c, int r, String t) {
      if (r >= 0 && r < rows && c >= 0 && c < cols) grid[r][c] = t;
    }

    final terrains = json['terrains'] as Map<String, dynamic>;
    for (final entry in terrains.entries) {
      for (final cell in (entry.value as List)) {
        st(cell[0], cell[1], entry.key);
      }
    }
    return grid;
  }
}
