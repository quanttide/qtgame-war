import 'dart:math';

class HexPoint {
  final double x, y;
  const HexPoint(this.x, this.y);
}

class HexUtils {
  static double hexSize = 27;
  static int cols = 10;
  static int rows = 7;
  static double sqr3 = sqrt(3);
  static double colSpacing = 1.5 * hexSize;
  static double rowSpacing = sqr3 * hexSize;
  static double oddRowOffset = 0.75 * hexSize;
  static double paddingX = 50;
  static double paddingY = 40;

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
    final List<(int, int)> offsets = row % 2 == 1
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
}
