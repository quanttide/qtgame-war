import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/unit.dart';
import '../models/battlefield.dart';
import '../bloc/game_state.dart';
import '../bloc/game_event.dart';
import '../bloc/game_bloc.dart';

class HexGrid extends StatelessWidget {
  const HexGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return GestureDetector(
          onTapUp: (details) {
            if (state.isGameOver || state.phase != GamePhase.player) return;
            final renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(details.globalPosition);
            final hex = Battlefield.pixelToHex(localPos.dx, localPos.dy);
            if (hex != null) {
              final (col, row) = hex;
              context.read<GameBloc>().add(ClickHex(col, row));
            }
          },
          onLongPress: () {
            context.read<GameBloc>().add(const ClearSelection());
          },
          child: CustomPaint(
            size: Size(Battlefield.canvasWidth, Battlefield.canvasHeight),
            painter: _HexGridPainter(state: state, mapTerrain: context.read<GameBloc>().engine.mapTerrain),
          ),
        );
      },
    );
  }
}

class _HexGridPainter extends CustomPainter {
  final GameState state;
  final List<List<TerrainType>> mapTerrain;
  final double hexSize;

  _HexGridPainter({required this.state, required this.mapTerrain}) : hexSize = 27;

  @override
  void paint(Canvas canvas, Size size) {
    for (int r = 0; r < Battlefield.rows; r++) {
      for (int c = 0; c < Battlefield.cols; c++) {
        final center = Battlefield.hexCenter(c, r);
        final terrain = mapTerrain[r][c];
        final props = terrainProps[terrain]!;
        final key = '$c,$r';

        Color fill = Color(props.fillColor);
        Color stroke = const Color.fromRGBO(50, 40, 30, 0.5);
        double lw = 1.3;

        if (state.moveCandidates.contains(key)) {
          fill = const Color.fromRGBO(70, 140, 210, 0.3);
          stroke = const Color.fromRGBO(100, 170, 240, 0.85);
          lw = 2.5;
        }
        if (state.attackCandidates.contains(key)) {
          fill = const Color.fromRGBO(220, 80, 50, 0.35);
          stroke = const Color.fromRGBO(250, 100, 60, 0.85);
          lw = 2.5;
        }
        if (state.selectedUnitId != null) {
          final su = state.selectedUnit;
          if (su != null && su.col == c && su.row == r) {
            stroke = const Color(0xfff0c040);
            lw = 3.5;
          }
        }

        _drawHex(canvas, center.x, center.y, hexSize, fill, stroke, lw);
        _drawTerrainIcon(canvas, center.x, center.y, terrain);
      }
    }

    for (final unit in state.units) {
      if (!unit.alive) continue;
      if (unit.side == 'nationalist' && !unit.revealed) continue;
      final center = Battlefield.hexCenter(unit.col, unit.row);
      _drawUnit(canvas, center.x, center.y, unit, hexSize);
    }

    for (final unit in state.units) {
      if (!unit.alive || unit.side != 'nationalist' || unit.revealed) continue;
      final center = Battlefield.hexCenter(unit.col, unit.row);
      _drawHiddenEnemy(canvas, center.x, center.y, hexSize);
    }
  }

  void _drawHex(Canvas canvas, double cx, double cy, double size, Color fill, Color stroke, double lw) {
    final path = Path();
    final verts = Battlefield.hexVertices(cx, cy, size);
    path.moveTo(verts[0].x, verts[0].y);
    for (int i = 1; i < 6; i++) { path.lineTo(verts[i].x, verts[i].y); }
    path.close();
    canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = lw);
  }

  void _drawTerrainIcon(Canvas canvas, double cx, double cy, TerrainType terrain) {
    final props = terrainProps[terrain]!;
    if (props.icon.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: props.icon,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: hexSize * 0.55),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawUnit(Canvas canvas, double cx, double cy, Unit unit, double size) {
    final r = size * 0.48;
    final path = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawPath(path, Paint()
      ..color = unit.side == 'pla' ? const Color(0xff3a1a10) : const Color(0xff0a1a2a)
      ..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()
      ..color = unit.side == 'pla' ? const Color(0xffc44b3c) : const Color(0xff4a80b4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2);

    String sym = '\u25A0';
    if (unit.special == 'assault') { sym = '\u26A1'; }
    else if (unit.attackRange >= 2) { sym = '\u25C8'; }
    else if (unit.baseMoveRange >= 5) { sym = '\u25C6'; }

    final tp = TextPainter(
      text: TextSpan(
        text: sym,
        style: TextStyle(
          color: unit.side == 'pla' ? const Color(0xfff0c0a0) : const Color(0xffa0c8f0),
          fontSize: r * 1.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    if (unit.maxHp > 1) {
      final bw = r * 1.3;
      final bh = 3.5;
      final by = cy - r - 6;
      canvas.drawRect(Rect.fromLTWH(cx - bw / 2, by, bw, bh), Paint()..color = const Color(0xff333333));
      final hpRatio = unit.hp / unit.maxHp;
      canvas.drawRect(
        Rect.fromLTWH(cx - bw / 2, by, bw * hpRatio, bh),
        Paint()..color = hpRatio > 0.5 ? const Color(0xff55aa55) : const Color(0xffee5555),
      );
    }

    if (unit.hasActed && unit.side == 'pla') {
      canvas.drawPath(path, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.4)..style = PaintingStyle.fill);
      final dot = TextPainter(
        text: const TextSpan(text: '\u2713', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      dot.layout();
      dot.paint(canvas, Offset(cx - dot.width / 2, cy - dot.height / 2));
    }
  }

  void _drawHiddenEnemy(Canvas canvas, double cx, double cy, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: const Color.fromRGBO(200, 70, 40, 0.65),
          fontSize: size * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    final path = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: size * 0.38));
    canvas.drawPath(path, Paint()
      ..color = const Color.fromRGBO(200, 70, 40, 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8);
  }

  @override
  bool shouldRepaint(covariant _HexGridPainter old) => old.state != state;
}
