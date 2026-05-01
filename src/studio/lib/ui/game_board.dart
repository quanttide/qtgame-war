import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/game_event.dart';
import '../models/game_state.dart';
import '../engine/hex_utils.dart';
import '../bloc/game_bloc.dart';
import 'hex_map_painter.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return GestureDetector(
          onTapUp: (details) {
            if (state.isGameOver || state.phase != GamePhase.player) return;
            final renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(details.globalPosition);
            final hex = HexUtils.pixelToHex(localPos.dx, localPos.dy);
            if (hex != null) {
              final (col, row) = hex;
              context.read<GameBloc>().add(ClickHex(col, row));
            }
          },
          onLongPress: () {
            context.read<GameBloc>().add(const ClearSelection());
          },
          child: CustomPaint(
            size: Size(HexUtils.canvasWidth, HexUtils.canvasHeight),
            painter: HexMapPainter(
              state: state,
              mapTerrain: context.read<GameBloc>().engine.mapTerrain,
            ),
          ),
        );
      },
    );
  }
}
