import 'package:flutter/material.dart';

/// The relative cell layout of a piece, independent of colour.
class PieceShape {
  final List<List<int>> cells; // [row, col] offsets from the origin
  final int rows;
  final int cols;

  const PieceShape({required this.cells, required this.rows, required this.cols});

  int get size => cells.length;
}

/// Catalogue of shapes, ordered roughly small -> large. The index into this
/// list is the stable id used when (de)serialising a piece.
const List<PieceShape> kPieceShapes = [
  PieceShape(cells: [[0, 0]], rows: 1, cols: 1),
  PieceShape(cells: [[0, 0], [0, 1]], rows: 1, cols: 2),
  PieceShape(cells: [[0, 0], [1, 0]], rows: 2, cols: 1),
  PieceShape(cells: [[0, 0], [0, 1], [0, 2]], rows: 1, cols: 3),
  PieceShape(cells: [[0, 0], [1, 0], [2, 0]], rows: 3, cols: 1),
  PieceShape(cells: [[0, 0], [0, 1], [0, 2], [0, 3]], rows: 1, cols: 4),
  PieceShape(cells: [[0, 0], [1, 0], [2, 0], [3, 0]], rows: 4, cols: 1),
  PieceShape(cells: [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]], rows: 1, cols: 5),
  PieceShape(cells: [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]], rows: 5, cols: 1),
  PieceShape(cells: [[0, 0], [0, 1], [1, 0], [1, 1]], rows: 2, cols: 2),
  PieceShape(cells: [[0, 0], [0, 1], [1, 0], [1, 1], [2, 0], [2, 1]], rows: 3, cols: 2),
  PieceShape(cells: [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2]], rows: 2, cols: 3),
  PieceShape(cells: [
    [0, 0], [0, 1], [0, 2],
    [1, 0], [1, 1], [1, 2],
    [2, 0], [2, 1], [2, 2],
  ], rows: 3, cols: 3),
  // L / J
  PieceShape(cells: [[0, 0], [1, 0], [2, 0], [2, 1]], rows: 3, cols: 2),
  PieceShape(cells: [[0, 1], [1, 1], [2, 0], [2, 1]], rows: 3, cols: 2),
  PieceShape(cells: [[0, 0], [1, 0], [1, 1], [1, 2]], rows: 2, cols: 3),
  PieceShape(cells: [[0, 2], [1, 0], [1, 1], [1, 2]], rows: 2, cols: 3),
  // T
  PieceShape(cells: [[0, 0], [0, 1], [0, 2], [1, 1]], rows: 2, cols: 3),
  PieceShape(cells: [[0, 1], [1, 0], [1, 1], [1, 2]], rows: 2, cols: 3),
  // S / Z
  PieceShape(cells: [[0, 1], [0, 2], [1, 0], [1, 1]], rows: 2, cols: 3),
  PieceShape(cells: [[0, 0], [0, 1], [1, 1], [1, 2]], rows: 2, cols: 3),
  // small corners
  PieceShape(cells: [[0, 0], [1, 0], [1, 1]], rows: 2, cols: 2),
  PieceShape(cells: [[0, 1], [1, 0], [1, 1]], rows: 2, cols: 2),
  PieceShape(cells: [[0, 0], [0, 1], [1, 0]], rows: 2, cols: 2),
  PieceShape(cells: [[0, 0], [0, 1], [1, 1]], rows: 2, cols: 2),
];

/// Palette. Levels use a leading slice of this list; the number of colours in
/// play grows with difficulty, so early levels are easier to match.
const List<Color> kPieceColors = [
  Color(0xFFE74C3C), // Red
  Color(0xFF3498DB), // Blue
  Color(0xFF2ECC71), // Green
  Color(0xFFF39C12), // Orange
  Color(0xFF9B59B6), // Purple
  Color(0xFF1ABC9C), // Teal
  Color(0xFFE91E63), // Pink
];

int get kMaxColors => kPieceColors.length;

/// A single coloured square within a piece.
class PieceCell {
  final int row;
  final int col;
  final int colorIndex;

  const PieceCell({required this.row, required this.col, required this.colorIndex});
}

/// A piece is a shape in which every cell carries its own colour. The core
/// mechanic is matching same-coloured cells from different pieces on the board.
class Piece {
  final int shapeIndex;
  final List<PieceCell> coloredCells;

  const Piece({required this.shapeIndex, required this.coloredCells});

  PieceShape get shape => kPieceShapes[shapeIndex];
  int get rows => shape.rows;
  int get cols => shape.cols;

  /// Build a piece from a shape id and one colour per cell (in `shape.cells`
  /// order). Keeps generation and storage compact and deterministic.
  factory Piece.fromColors(int shapeIndex, List<int> colors) {
    final shape = kPieceShapes[shapeIndex];
    final cells = <PieceCell>[];
    for (int i = 0; i < shape.cells.length; i++) {
      cells.add(PieceCell(
        row: shape.cells[i][0],
        col: shape.cells[i][1],
        colorIndex: colors[i % colors.length],
      ));
    }
    return Piece(shapeIndex: shapeIndex, coloredCells: cells);
  }

  Map<String, dynamic> toMap() => {
        's': shapeIndex,
        'c': coloredCells.map((e) => e.colorIndex).toList(),
      };

  factory Piece.fromMap(Map<String, dynamic> map) =>
      Piece.fromColors(map['s'] as int, (map['c'] as List).cast<int>());
}
