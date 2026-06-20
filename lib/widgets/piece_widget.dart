import 'package:flutter/material.dart';
import '../models/piece.dart';

class PieceWidget extends StatelessWidget {
  final Piece piece;
  final double cellSize;
  final double opacity;

  const PieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final width = piece.shape.cols * cellSize;
    final height = piece.shape.rows * cellSize;

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: PiecePainter(piece: piece, cellSize: cellSize),
        ),
      ),
    );
  }
}

class PiecePainter extends CustomPainter {
  final Piece piece;
  final double cellSize;
  static const double _padding = 1.5;
  static const double _cornerRadius = 3.0;

  const PiecePainter({required this.piece, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final cell in piece.coloredCells) {
      final r = cell.row;
      final c = cell.col;
      final color = kPieceColors[cell.colorIndex];
      final rect = Rect.fromLTWH(
        c * cellSize + _padding,
        r * cellSize + _padding,
        cellSize - _padding * 2,
        cellSize - _padding * 2,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_cornerRadius));

      canvas.drawRRect(rrect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(PiecePainter old) => true;
}

// Drag feedback widget - shown while dragging
class DraggingPieceWidget extends StatelessWidget {
  final Piece piece;
  final double cellSize;

  const DraggingPieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PieceWidget(
        piece: piece,
        cellSize: cellSize,
        opacity: 0.85,
      ),
    );
  }
}
