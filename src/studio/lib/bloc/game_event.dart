import 'package:equatable/equatable.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class SelectUnit extends GameEvent {
  final int unitId;
  const SelectUnit(this.unitId);

  @override
  List<Object?> get props => [unitId];
}

class ClickHex extends GameEvent {
  final int col;
  final int row;
  const ClickHex(this.col, this.row);

  @override
  List<Object?> get props => [col, row];
}

class EndTurn extends GameEvent {
  const EndTurn();
}

class ResetGame extends GameEvent {
  const ResetGame();
}

class AiStep extends GameEvent {
  const AiStep();
}

class ClearSelection extends GameEvent {
  const ClearSelection();
}
