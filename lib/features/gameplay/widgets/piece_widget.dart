import 'package:flutter/material.dart';

import '../../../data/models/piece.dart';

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
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: piece.cols * cellSize,
        height: piece.rows * cellSize,
        child: CustomPaint(painter: _PiecePainter(piece: piece, cellSize: cellSize)),
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  final Piece piece;
  final double cellSize;
  static const double _padding = 1.5;
  static const double _radius = 3.0;

  const _PiecePainter({required this.piece, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final cell in piece.coloredCells) {
      final rect = Rect.fromLTWH(
        cell.col * cellSize + _padding,
        cell.row * cellSize + _padding,
        cellSize - _padding * 2,
        cellSize - _padding * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(_radius)),
        Paint()..color = kPieceColors[cell.colorIndex],
      );
    }
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.piece != piece || old.cellSize != cellSize;
}
