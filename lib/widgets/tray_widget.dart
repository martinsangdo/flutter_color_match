import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../game/game_controller.dart';
import 'piece_widget.dart';

class TrayWidget extends StatelessWidget {
  final List<Piece?> tray;
  final double boardWidth;
  final void Function(int trayIndex, Offset startPosition) onDragStart;
  final void Function(int trayIndex, DragUpdateDetails details) onDragUpdate;
  final void Function(int trayIndex, DragEndDetails details) onDragEnd;

  const TrayWidget({
    super.key,
    required this.tray,
    required this.boardWidth,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: boardWidth * 0.22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(kTraySize, (i) {
          final piece = tray[i];
          if (piece == null) {
            return const Expanded(child: SizedBox());
          }
          return Expanded(
            child: Center(
              child: _TrayItem(
                piece: piece,
                boardWidth: boardWidth,
                onDragStart: (pos) => onDragStart(i, pos),
                onDragUpdate: (d) => onDragUpdate(i, d),
                onDragEnd: (d) => onDragEnd(i, d),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TrayItem extends StatelessWidget {
  final Piece piece;
  final double boardWidth;
  final void Function(Offset startPosition) onDragStart;
  final void Function(DragUpdateDetails) onDragUpdate;
  final void Function(DragEndDetails) onDragEnd;

  const _TrayItem({
    required this.piece,
    required this.boardWidth,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  double _calcCellSize() {
    // Scale piece to fit in tray, max 5 cells wide/tall
    final maxDim = piece.shape.cols > piece.shape.rows
        ? piece.shape.cols
        : piece.shape.rows;
    final slotSize = boardWidth / kTraySize;
    final available = slotSize * 0.85;
    return (available / maxDim).clamp(8.0, 24.0);
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = _calcCellSize();

    return GestureDetector(
      onPanStart: (d) => onDragStart(d.globalPosition),
      onPanUpdate: onDragUpdate,
      onPanEnd: onDragEnd,
      child: PieceWidget(piece: piece, cellSize: cellSize),
    );
  }
}
