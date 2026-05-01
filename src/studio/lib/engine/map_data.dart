import '../models/terrain.dart';
import 'hex_utils.dart';

List<List<TerrainType>> createMapTerrain() {
  final grid = List.generate(
    HexUtils.rows,
    (_) => List.filled(HexUtils.cols, TerrainType.plain),
  );

  void st(int c, int r, TerrainType t) {
    if (r >= 0 && r < HexUtils.rows && c >= 0 && c < HexUtils.cols) {
      grid[r][c] = t;
    }
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
