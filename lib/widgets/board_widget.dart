import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/piece.dart';

class BoardWidget extends StatelessWidget {
  final Board board;
  final Piece? hoverPiece;
  final int? hoverRow;
  final int? hoverCol;
  final bool hoverValid;

  const BoardWidget({
    super.key,
    required this.board,
    this.hoverPiece,
    this.hoverRow,
    this.hoverCol,
    this.hoverValid = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / kBoardSize;
          return CustomPaint(
            painter: BoardPainter(
              board: board,
              cellSize: cellSize,
              hoverPiece: hoverPiece,
              hoverRow: hoverRow,
              hoverCol: hoverCol,
              hoverValid: hoverValid,
            ),
          );
        },
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final Board board;
  final double cellSize;
  final Piece? hoverPiece;
  final int? hoverRow;
  final int? hoverCol;
  final bool hoverValid;

  static const double _cornerRadius = 3.0;
  static const double _padding = 1.5;

  BoardPainter({
    required this.board,
    required this.cellSize,
    this.hoverPiece,
    this.hoverRow,
    this.hoverCol,
    this.hoverValid = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = const Color(0xFF1A2A3A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    // Build hover set: map board position → colorIndex for preview
    final hoverCells = <String, int>{};
    if (hoverPiece != null && hoverRow != null && hoverCol != null) {
      for (final cell in hoverPiece!.coloredCells) {
        hoverCells['${hoverRow! + cell.row},${hoverCol! + cell.col}'] = cell.colorIndex;
      }
    }

    // Draw cells
    for (int r = 0; r < kBoardSize; r++) {
      for (int c = 0; c < kBoardSize; c++) {
        final cell = board.get(r, c);
        final hoverColorIndex = hoverCells['$r,$c'];
        _drawCell(canvas, r, c, cell, hoverColorIndex);
      }
    }

    // Draw grid lines on top (subtle)
    final gridPaint = Paint()
      ..color = const Color(0xFF0D1B29)
      ..strokeWidth = 0.5;
    for (int i = 1; i < kBoardSize; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }
  }

  void _drawCell(Canvas canvas, int row, int col, Cell cell, int? hoverColorIndex) {
    final rect = Rect.fromLTWH(
      col * cellSize + _padding,
      row * cellSize + _padding,
      cellSize - _padding * 2,
      cellSize - _padding * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_cornerRadius));

    if (cell.isEmpty && hoverColorIndex == null) {
      // Empty cell - dark background
      final paint = Paint()..color = const Color(0xFF243447);
      canvas.drawRRect(rrect, paint);
    } else if (hoverColorIndex != null && cell.isEmpty) {
      // Hover preview — show actual piece cell color at reduced opacity
      final baseColor = kPieceColors[hoverColorIndex];
      final color = hoverValid
          ? baseColor.withValues(alpha: 0.55)
          : const Color(0xFFFF4444).withValues(alpha: 0.4);
      final paint = Paint()..color = color;
      canvas.drawRRect(rrect, paint);
    } else {
      // Filled cell
      final color = kPieceColors[cell.colorIndex];
      _drawFilledCell(canvas, rrect, color, cell.isNew);
    }
  }

  void _drawFilledCell(Canvas canvas, RRect rrect, Color color, bool isNew) {
    canvas.drawRRect(rrect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(BoardPainter old) => true;
}
