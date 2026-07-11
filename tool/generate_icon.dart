import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_match/data/models/piece.dart';

/// One-off generator: rasterises the [AppLogo] brand mark into the source PNGs
/// that `flutter_launcher_icons` fans out into every platform density. Run with:
///
///   flutter test tool/generate_icon.dart
///
/// Writes:
///  - `assets/icon/app_icon.png`            — full-bleed 1024² (iOS + legacy).
///  - `assets/icon/app_icon_foreground.png` — transparent, grid inside the
///    adaptive-icon safe zone (Android 8+ foreground layer).
///
/// Re-run whenever the mark changes.
const _bg = Color(0xFF16283A);
const _empty = Color(0xFF23364A);

// Same fixed arrangement as AppLogo (-1 = empty cell).
const _grid = [
  [0, 0, -1],
  [2, 0, 3],
  [2, 3, 3],
];

/// Paints the 3×3 grid so it fills the square inset by [pad] on every side.
void _paintGrid(Canvas canvas, double size, double pad) {
  final inner = size - pad * 2;
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
      canvas.drawRRect(
        rrect,
        Paint()..color = colorIndex < 0 ? _empty : kPieceColors[colorIndex],
      );
    }
  }
}

Future<void> _writePng(File file, ui.Picture picture, int px) async {
  final image = await picture.toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
  stdout.writeln('Wrote ${file.path} (${bytes.lengthInBytes} bytes)');
}

void main() {
  const size = 1024.0;

  test('generate app_icon.png (full-bleed, iOS + legacy)', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Opaque background — iOS forbids alpha; both OSes mask the corners.
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, size, size), Paint()..color = _bg);
    _paintGrid(canvas, size, size * 0.16);
    await _writePng(File('assets/icon/app_icon.png'),
        recorder.endRecording(), size.toInt());
    expect(File('assets/icon/app_icon.png').existsSync(), isTrue);
  });

  test('generate app_icon_foreground.png (adaptive foreground)', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Transparent background; grid sized so its corners stay inside the
    // adaptive safe circle after flutter_launcher_icons' own 16% inset — the
    // circular system mask never clips a tile.
    _paintGrid(canvas, size, size * 0.20);
    await _writePng(File('assets/icon/app_icon_foreground.png'),
        recorder.endRecording(), size.toInt());
    expect(File('assets/icon/app_icon_foreground.png').existsSync(), isTrue);
  });
}
