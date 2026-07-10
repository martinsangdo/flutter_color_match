import 'package:flutter/material.dart';

import '../../../data/models/piece.dart';
import '../game_engine.dart';
import 'piece_widget.dart';

/// The bottom tray of draggable pieces. Emits global drag coordinates so the
/// gameplay screen can drive the board hover + placement.
class TrayWidget extends StatelessWidget {
  final List<Piece?> tray;
  final double boardWidth;
  final int? activeIndex; // hide the piece currently being dragged
  final void Function(int trayIndex, Offset globalPosition) onDragStart;
  final void Function(int trayIndex, Offset globalPosition) onDragUpdate;
  final void Function(int trayIndex) onDragEnd;

  const TrayWidget({
    super.key,
    required this.tray,
    required this.boardWidth,
    required this.activeIndex,
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
          // While this slot is the one being dragged we render it invisibly
          // rather than removing it: the _TrayItem owns the GestureDetector
          // whose PanGestureRecognizer is mid-drag. Unmounting it here would
          // dispose that recognizer, so onPanUpdate/onPanEnd would stop firing
          // and the piece would freeze / never place. Opacity(0) keeps the
          // recognizer alive for the whole drag while hiding the tray copy.
          final isActive = activeIndex == i;
          return Expanded(
            child: Center(
              child: Opacity(
                opacity: isActive ? 0.0 : 1.0,
                child: _TrayItem(
                  piece: piece,
                  boardWidth: boardWidth,
                  onDragStart: (pos) => onDragStart(i, pos),
                  onDragUpdate: (pos) => onDragUpdate(i, pos),
                  onDragEnd: () => onDragEnd(i),
                ),
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
  final void Function(Offset globalPosition) onDragStart;
  final void Function(Offset globalPosition) onDragUpdate;
  final VoidCallback onDragEnd;

  const _TrayItem({
    required this.piece,
    required this.boardWidth,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  double _calcCellSize() {
    final maxDim = piece.cols > piece.rows ? piece.cols : piece.rows;
    final slotSize = boardWidth / kTraySize;
    final available = slotSize * 0.85;
    return (available / maxDim).clamp(8.0, 24.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => onDragStart(d.globalPosition),
      onPanUpdate: (d) => onDragUpdate(d.globalPosition),
      onPanEnd: (_) => onDragEnd(),
      onPanCancel: onDragEnd,
      child: PieceWidget(piece: piece, cellSize: _calcCellSize()),
    );
  }
}
