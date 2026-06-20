import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board.dart';
import '../models/piece.dart';

const int kTraySize = 3;
const String _kHighScoreKey = 'high_score';

enum GameState { playing, gameOver }

class GameController extends ChangeNotifier {
  final Board board = Board();
  final List<Piece?> tray = List.filled(kTraySize, null, growable: false);
  int score = 0;
  int highScore = 0;
  int combo = 0;
  GameState state = GameState.playing;

  final Random _random = Random();

  GameController() {
    _loadHighScore().then((_) => _refillTray());
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt(_kHighScoreKey) ?? 0;
    notifyListeners();
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHighScoreKey, highScore);
  }

  void _refillTray() {
    for (int i = 0; i < kTraySize; i++) {
      if (tray[i] == null) {
        tray[i] = _generatePiece();
      }
    }
  }

  Piece _generatePiece() {
    final shapeIndex = _random.nextInt(kPieceShapes.length);
    final shape = kPieceShapes[shapeIndex];
    // Each cell gets its own independent random color
    final coloredCells = shape.cells.map((cell) => PieceCell(
      row: cell[0],
      col: cell[1],
      colorIndex: _random.nextInt(kPieceColors.length),
    )).toList();
    return Piece(shape: shape, coloredCells: coloredCells);
  }

  bool canPlacePiece(Piece piece, int row, int col) {
    for (final cell in piece.coloredCells) {
      final r = row + cell.row;
      final c = col + cell.col;
      if (!board.isCellEmpty(r, c)) return false;
    }
    return true;
  }

  // Returns true if placement succeeded
  bool placePiece(int trayIndex, int row, int col) {
    final piece = tray[trayIndex];
    if (piece == null) return false;
    if (!canPlacePiece(piece, row, col)) return false;

    // Place each cell with its individual color
    for (final cell in piece.coloredCells) {
      board.setCell(row + cell.row, col + cell.col, cell.colorIndex, isNew: true);
    }
    tray[trayIndex] = null;

    // Trigger clear check with animation
    _processClearings();

    // Refill tray if all pieces used
    if (tray.every((p) => p == null)) {
      _refillTray();
    }

    // Check game over
    if (_isGameOver()) {
      state = GameState.gameOver;
      if (score > highScore) {
        highScore = score;
        _saveHighScore();
      }
    }

    notifyListeners();
    return true;
  }

  void _processClearings() {
    final groups = board.findClearableGroups();
    if (groups.isEmpty) {
      combo = 0;
      board.resetNewFlags();
      return;
    }

    combo++;
    int cleared = 0;
    for (final group in groups) {
      cleared += group.length;
    }

    // Score: base per block + combo bonus
    final baseScore = cleared * 10;
    final comboBonus = combo > 1 ? (combo - 1) * 50 : 0;
    score += baseScore + comboBonus;

    board.clearGroups(groups);
    board.resetNewFlags();

    // Check for cascading clears
    _processClearings();
  }

  bool _isGameOver() {
    // Check if any remaining piece in tray can be placed anywhere
    for (final piece in tray) {
      if (piece == null) continue;
      for (int r = 0; r < kBoardSize; r++) {
        for (int c = 0; c < kBoardSize; c++) {
          if (canPlacePiece(piece, r, c)) return false;
        }
      }
    }
    return true;
  }

  void restart() {
    for (int r = 0; r < kBoardSize; r++) {
      for (int c = 0; c < kBoardSize; c++) {
        board.clearCell(r, c);
      }
    }
    for (int i = 0; i < kTraySize; i++) {
      tray[i] = null;
    }
    score = 0;
    combo = 0;
    state = GameState.playing;
    _refillTray();
    notifyListeners();
  }

  // Get valid drop row/col from drag position on the board
  // boardOffset: top-left of board on screen, cellSize: pixel size of each cell
  // dragPos: global position of drag
  int? getDropRow(Offset dragPos, Offset boardOffset, double cellSize, Piece piece) {
    final localY = dragPos.dy - boardOffset.dy;
    final row = (localY / cellSize).floor();
    // Clamp so piece fits
    return row.clamp(0, kBoardSize - piece.shape.rows).toInt();
  }

  int? getDropCol(Offset dragPos, Offset boardOffset, double cellSize, Piece piece) {
    final localX = dragPos.dx - boardOffset.dx;
    final col = (localX / cellSize).floor();
    return col.clamp(0, kBoardSize - piece.shape.cols).toInt();
  }
}
