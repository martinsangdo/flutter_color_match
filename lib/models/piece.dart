import 'package:flutter/material.dart';

class PieceShape {
  final List<List<int>> cells; // [row, col] offsets from origin
  final int rows;
  final int cols;

  const PieceShape({required this.cells, required this.rows, required this.cols});
}

const List<PieceShape> kPieceShapes = [
  // 1x1
  PieceShape(cells: [[0, 0]], rows: 1, cols: 1),
  // 1x2
  PieceShape(cells: [[0, 0], [0, 1]], rows: 1, cols: 2),
  // 2x1
  PieceShape(cells: [[0, 0], [1, 0]], rows: 2, cols: 1),
  // 1x3
  PieceShape(cells: [[0, 0], [0, 1], [0, 2]], rows: 1, cols: 3),
  // 3x1
  PieceShape(cells: [[0, 0], [1, 0], [2, 0]], rows: 3, cols: 1),
  // 1x4
  PieceShape(cells: [[0, 0], [0, 1], [0, 2], [0, 3]], rows: 1, cols: 4),
  // 4x1
  PieceShape(cells: [[0, 0], [1, 0], [2, 0], [3, 0]], rows: 4, cols: 1),
  // 1x5
  PieceShape(cells: [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]], rows: 1, cols: 5),
  // 5x1
  PieceShape(cells: [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]], rows: 5, cols: 1),
  // 2x2
  PieceShape(cells: [[0, 0], [0, 1], [1, 0], [1, 1]], rows: 2, cols: 2),
  // 3x2
  PieceShape(cells: [[0, 0], [0, 1], [1, 0], [1, 1], [2, 0], [2, 1]], rows: 3, cols: 2),
  // 2x3
  PieceShape(cells: [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2]], rows: 2, cols: 3),
  // 3x3
  PieceShape(cells: [
    [0, 0], [0, 1], [0, 2],
    [1, 0], [1, 1], [1, 2],
    [2, 0], [2, 1], [2, 2],
  ], rows: 3, cols: 3),
  // L-shapes
  PieceShape(cells: [[0, 0], [1, 0], [2, 0], [2, 1]], rows: 3, cols: 2),
  PieceShape(cells: [[0, 1], [1, 1], [2, 0], [2, 1]], rows: 3, cols: 2),
  PieceShape(cells: [[0, 0], [1, 0], [1, 1], [1, 2]], rows: 2, cols: 3),
  PieceShape(cells: [[0, 2], [1, 0], [1, 1], [1, 2]], rows: 2, cols: 3),
  // T-shapes
  PieceShape(cells: [[0, 0], [0, 1], [0, 2], [1, 1]], rows: 2, cols: 3),
  PieceShape(cells: [[0, 1], [1, 0], [1, 1], [1, 2]], rows: 2, cols: 3),
  // S/Z-shapes
  PieceShape(cells: [[0, 1], [0, 2], [1, 0], [1, 1]], rows: 2, cols: 3),
  PieceShape(cells: [[0, 0], [0, 1], [1, 1], [1, 2]], rows: 2, cols: 3),
  // Corner 2x2 missing one
  PieceShape(cells: [[0, 0], [1, 0], [1, 1]], rows: 2, cols: 2),
  PieceShape(cells: [[0, 1], [1, 0], [1, 1]], rows: 2, cols: 2),
  PieceShape(cells: [[0, 0], [0, 1], [1, 0]], rows: 2, cols: 2),
  PieceShape(cells: [[0, 0], [0, 1], [1, 1]], rows: 2, cols: 2),
];

const List<Color> kPieceColors = [
  Color(0xFFE74C3C), // Red
  Color(0xFF3498DB), // Blue
  Color(0xFF2ECC71), // Green
  Color(0xFFF39C12), // Orange
  Color(0xFF9B59B6), // Purple
  Color(0xFF1ABC9C), // Teal
  Color(0xFFE91E63), // Pink
];

/// A single colored square within a piece.
class PieceCell {
  final int row;
  final int col;
  final int colorIndex;

  const PieceCell({required this.row, required this.col, required this.colorIndex});
}

/// A piece is a shape where EACH individual cell has its own random color.
/// This is the core mechanic: you match same-colored cells from different pieces.
class Piece {
  final PieceShape shape;
  final List<PieceCell> coloredCells;

  Piece({required this.shape, required this.coloredCells});

  int get rows => shape.rows;
  int get cols => shape.cols;
}
