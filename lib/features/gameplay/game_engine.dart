import 'dart:math';

import '../../data/models/board.dart';
import '../../data/models/level.dart';
import '../../data/models/piece.dart';

const int kTraySize = 3;

enum GameStatus { playing, won, lost }

/// Supplies pieces to the tray. Returns null when exhausted (finite levels).
typedef PieceSource = Piece? Function();

/// Outcome of resolving all cascading clears after a placement.
class ClearOutcome {
  final int totalCleared;
  final int cascades;
  final Map<int, int> byColor;
  final List<Set<int>> groups; // grouped per cascade wave, for animation

  const ClearOutcome(this.totalCleared, this.cascades, this.byColor, this.groups);
}

class PlacementResult {
  final bool placed;
  final ClearOutcome? clears;

  const PlacementResult({required this.placed, this.clears});

  static const PlacementResult rejected = PlacementResult(placed: false);
}

/// The shared, UI-agnostic game logic. One instance drives a single play
/// session (a level or an endless run). It is deliberately free of Flutter so
/// the level generator and solver can run it head-less.
class GameEngine {
  final Board board;
  final List<Piece?> tray = List<Piece?>.filled(kTraySize, null, growable: false);
  final PieceSource _source;
  final int moveLimit; // -1 == unlimited (endless)
  final bool endless;

  int movesUsed = 0;
  int totalCleared = 0;
  int score = 0;
  int combo = 0;
  final Map<int, int> clearedByColor = {};
  GameStatus status = GameStatus.playing;

  final bool Function(GameEngine)? _isObjectiveMet;

  GameEngine({
    required Board initialBoard,
    required PieceSource source,
    this.moveLimit = -1,
    this.endless = false,
    bool Function(GameEngine)? objectiveMet,
  })  : board = initialBoard,
        _source = source,
        _isObjectiveMet = objectiveMet {
    _refillTray();
    _updateStatus();
  }

  /// Endless run with an infinite random source over [colorCount] colours.
  /// While the board still has room, pieces that cannot be placed anywhere are
  /// rerolled a few times so the run doesn't die on an unlucky, impossible draw.
  factory GameEngine.endless({required int colorCount, int? seed}) {
    final rng = Random(seed);
    final board = Board();
    Piece gen() {
      var piece = randomPiece(rng, colorCount);
      if (board.filledCount < 80) {
        int tries = 0;
        while (!_fitsAnywhere(board, piece) && tries < 6) {
          piece = randomPiece(rng, colorCount);
          tries++;
        }
      }
      return piece;
    }

    return GameEngine(initialBoard: board, endless: true, source: gen);
  }

  /// Build an engine that plays a specific campaign level: pieces come from the
  /// level's fixed queue and the win check uses the level's objective.
  factory GameEngine.forLevel(LevelDefinition level) {
    int cursor = 0;
    final pool = level.pieceQueue;
    return GameEngine(
      initialBoard: Board.fromGrid(level.initialGrid),
      moveLimit: level.moveLimit,
      source: () => cursor < pool.length ? pool[cursor++] : null,
      objectiveMet: (engine) =>
          level.objective.isMetBy(engine.totalCleared, engine.clearedByColor),
    );
  }

  static bool _fitsAnywhere(Board b, Piece piece) {
    for (int r = 0; r <= kBoardSize - piece.rows; r++) {
      for (int c = 0; c <= kBoardSize - piece.cols; c++) {
        bool ok = true;
        for (final cell in piece.coloredCells) {
          if (!b.isCellEmpty(r + cell.row, c + cell.col)) {
            ok = false;
            break;
          }
        }
        if (ok) return true;
      }
    }
    return false;
  }

  bool get isMovesExhausted => moveLimit >= 0 && movesUsed >= moveLimit;

  bool canPlacePiece(Piece piece, int row, int col) {
    for (final cell in piece.coloredCells) {
      if (!board.isCellEmpty(row + cell.row, col + cell.col)) return false;
    }
    return true;
  }

  bool canPlaceAnywhere(Piece piece) {
    for (int r = 0; r <= kBoardSize - piece.rows; r++) {
      for (int c = 0; c <= kBoardSize - piece.cols; c++) {
        if (canPlacePiece(piece, r, c)) return true;
      }
    }
    return false;
  }

  bool get hasAnyValidMove {
    for (final piece in tray) {
      if (piece != null && canPlaceAnywhere(piece)) return true;
    }
    return false;
  }

  /// Attempt to place [trayIndex] with its origin at (row, col).
  PlacementResult place(int trayIndex, int row, int col) {
    if (status != GameStatus.playing) return PlacementResult.rejected;
    final piece = tray[trayIndex];
    if (piece == null || !canPlacePiece(piece, row, col)) {
      return PlacementResult.rejected;
    }

    for (final cell in piece.coloredCells) {
      board.setCell(row + cell.row, col + cell.col, cell.colorIndex, isNew: true);
    }
    tray[trayIndex] = null;
    movesUsed++;

    final outcome = _resolveClears();
    totalCleared += outcome.totalCleared;
    outcome.byColor.forEach((k, v) => clearedByColor[k] = (clearedByColor[k] ?? 0) + v);

    // Scoring (used mainly by endless; harmless for levels).
    if (outcome.totalCleared > 0) {
      final comboBonus = combo > 1 ? (combo - 1) * 50 : 0;
      score += outcome.totalCleared * 10 + comboBonus;
    }

    if (tray.every((p) => p == null)) _refillTray();
    _updateStatus();

    return PlacementResult(placed: true, clears: outcome);
  }

  void _updateStatus() {
    if (_isObjectiveMet?.call(this) ?? false) {
      status = GameStatus.won;
      return;
    }
    if (endless) {
      if (!hasAnyValidMove) status = GameStatus.lost;
      return;
    }
    // Level: lose if out of moves, or stuck with no refill possible.
    final trayEmpty = tray.every((p) => p == null);
    if (isMovesExhausted) {
      status = GameStatus.lost;
    } else if (!trayEmpty && !hasAnyValidMove) {
      status = GameStatus.lost;
    } else if (trayEmpty) {
      status = GameStatus.lost; // source exhausted, objective not yet met
    }
  }

  void _refillTray() {
    for (int i = 0; i < kTraySize; i++) {
      if (tray[i] == null) tray[i] = _source();
    }
  }

  /// Repeatedly clear qualifying groups until none remain; combos cascade.
  ClearOutcome _resolveClears() {
    int total = 0;
    int cascades = 0;
    final byColor = <int, int>{};
    final waves = <Set<int>>[];

    while (true) {
      final groups = board.findClearableGroups();
      if (groups.isEmpty) {
        if (cascades == 0) combo = 0;
        board.resetNewFlags();
        break;
      }
      combo++;
      cascades++;
      final wave = <int>{};
      for (final group in groups) {
        final colorIdx = board.get(group.first ~/ kBoardSize, group.first % kBoardSize).colorIndex;
        byColor[colorIdx] = (byColor[colorIdx] ?? 0) + group.length;
        total += group.length;
        wave.addAll(group);
      }
      waves.add(wave);
      board.clearGroups(groups);
      board.resetNewFlags();
    }
    return ClearOutcome(total, cascades, byColor, waves);
  }

  /// Resolve all cascading clears on an arbitrary board (mutating it), counting
  /// what was removed. Used by the level generator and solver to evaluate a
  /// hypothetical placement without touching a live engine.
  static ClearOutcome resolveBoard(Board b) {
    int total = 0;
    int cascades = 0;
    final byColor = <int, int>{};
    while (true) {
      final groups = b.findClearableGroups();
      if (groups.isEmpty) break;
      cascades++;
      for (final group in groups) {
        final first = group.first;
        final colorIdx = b.get(first ~/ kBoardSize, first % kBoardSize).colorIndex;
        byColor[colorIdx] = (byColor[colorIdx] ?? 0) + group.length;
        total += group.length;
      }
      b.clearGroups(groups);
    }
    return ClearOutcome(total, cascades, byColor, const []);
  }

  /// A random piece over the leading [colorCount] colours.
  static Piece randomPiece(Random rng, int colorCount) {
    final shapeIndex = rng.nextInt(kPieceShapes.length);
    final shape = kPieceShapes[shapeIndex];
    final colors = List<int>.generate(
      shape.cells.length,
      (_) => rng.nextInt(colorCount),
    );
    return Piece.fromColors(shapeIndex, colors);
  }
}
