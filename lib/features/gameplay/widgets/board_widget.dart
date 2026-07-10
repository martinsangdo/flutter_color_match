import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/board.dart';
import '../../../data/models/piece.dart';

class BoardWidget extends StatelessWidget {
  final Board board;
  final Piece? hoverPiece;
  final int? hoverRow;
  final int? hoverCol;
  final bool hoverValid;

  /// Cells to pulse as a hint (flattened row*size+col ids).
  final Set<int> hintCells;

  const BoardWidget({
    super.key,
    required this.board,
    this.hoverPiece,
    this.hoverRow,
    this.hoverCol,
    this.hoverValid = false,
    this.hintCells = const {},
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / kBoardSize;
          return CustomPaint(
            painter: _BoardPainter(
              board: board,
              cellSize: cellSize,
              hoverPiece: hoverPiece,
              hoverRow: hoverRow,
              hoverCol: hoverCol,
              hoverValid: hoverValid,
              hintCells: hintCells,
            ),
          );
        },
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final Board board;
  final double cellSize;
  final Piece? hoverPiece;
  final int? hoverRow;
  final int? hoverCol;
  final bool hoverValid;
  final Set<int> hintCells;

  static const double _radius = 3.0;
  static const double _padding = 1.5;

  _BoardPainter({
    required this.board,
    required this.cellSize,
    required this.hoverPiece,
    required this.hoverRow,
    required this.hoverCol,
    required this.hoverValid,
    required this.hintCells,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.panel;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    final hoverCells = <int, int>{};
    if (hoverPiece != null && hoverRow != null && hoverCol != null) {
      for (final cell in hoverPiece!.coloredCells) {
        hoverCells[(hoverRow! + cell.row) * kBoardSize + (hoverCol! + cell.col)] =
            cell.colorIndex;
      }
    }

    for (int r = 0; r < kBoardSize; r++) {
      for (int c = 0; c < kBoardSize; c++) {
        final cell = board.get(r, c);
        final id = r * kBoardSize + c;
        _drawCell(canvas, r, c, cell, hoverCells[id], hintCells.contains(id));
      }
    }

    final gridPaint = Paint()
      ..color = AppColors.grid
      ..strokeWidth = 0.5;
    for (int i = 1; i < kBoardSize; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), gridPaint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), gridPaint);
    }
  }

  void _drawCell(Canvas canvas, int row, int col, Cell cell, int? hoverColorIndex, bool isHint) {
    final rect = Rect.fromLTWH(
      col * cellSize + _padding,
      row * cellSize + _padding,
      cellSize - _padding * 2,
      cellSize - _padding * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_radius));

    if (!cell.isEmpty) {
      canvas.drawRRect(rrect, Paint()..color = kPieceColors[cell.colorIndex]);
    } else if (hoverColorIndex != null) {
      final base = hoverValid
          ? kPieceColors[hoverColorIndex].withValues(alpha: 0.55)
          : AppColors.danger.withValues(alpha: 0.4);
      canvas.drawRRect(rrect, Paint()..color = base);
    } else {
      canvas.drawRRect(rrect, Paint()..color = AppColors.panelLight);
    }

    if (isHint) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.star,
      );
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true;
}
