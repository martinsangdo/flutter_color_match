import 'package:flutter/material.dart';

import '../../data/models/piece.dart';

/// Original vector logo: a rounded tile holding a small colour-match grid.
/// Reused on the splash and home screens for a consistent brand mark.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  // A pleasing fixed arrangement of palette colours (index into kPieceColors,
  // -1 = empty) so the mark reads as the game itself.
  static const _grid = [
    [0, 0, -1],
    [2, 0, 3],
    [2, 3, 3],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final tile = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(tile, Paint()..color = const Color(0xFF16283A));

    final pad = size.width * 0.16;
    final inner = size.width - pad * 2;
    final cell = inner / 3;
    const gap = 0.10;

    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final colorIndex = _grid[r][c];
        final rect = Rect.fromLTWH(
          pad + c * cell + cell * gap,
          pad + r * cell + cell * gap,
          cell * (1 - gap * 2),
          cell * (1 - gap * 2),
        );
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.18));
        final paint = Paint()
          ..color = colorIndex < 0
              ? const Color(0xFF23364A)
              : kPieceColors[colorIndex];
        canvas.drawRRect(rrect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}
