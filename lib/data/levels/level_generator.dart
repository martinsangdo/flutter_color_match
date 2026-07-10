import 'dart:math';

import '../../features/gameplay/game_engine.dart';
import '../models/board.dart';
import '../models/level.dart';
import '../models/piece.dart';
import 'placement_strategy.dart';

/// Total hand-curated + generated levels in the campaign.
const int kLevelCount = 90;

/// Produces campaign levels deterministically from their index.
///
/// Every level is built by letting a greedy "designer" actually play the real
/// engine over a recorded piece pool; the objective is then set at or below
/// what the designer achieved. Because the designer's own moves are a valid
/// solution the player can reproduce (identical pool, identical tray rules),
/// each level is solvable *by construction*. [LevelSolver.verify] double-checks.
class LevelGenerator {
  static const int _baseSeed = 0x5EED;

  static LevelDefinition generate(int index) {
    final params = _Difficulty.forIndex(index);

    _Design? best;
    for (int attempt = 0; attempt < 10; attempt++) {
      final seed = _baseSeed + index * 1315423 + attempt * 2654435;
      final design = _play(params, seed);
      if (design.totalCleared >= params.minAchieved) {
        return _build(index, seed, params, design);
      }
      if (best == null || design.totalCleared > best.totalCleared) best = design;
    }
    // Fall back to the best attempt; objective is clamped to what it achieved,
    // so it stays solvable even if modest.
    return _build(index, best!.seed, params, best);
  }

  /// Run the greedy designer, recording the piece pool it drew.
  static _Design _play(_Difficulty p, int seed) {
    final rng = Random(seed);
    final board = _buildObstacles(rng, p);
    final initialGrid = board.toGrid();

    final pool = <Piece>[];
    final tray = List<Piece?>.filled(kTraySize, null, growable: false);
    int movesUsed = 0;
    int totalCleared = 0;
    final byColor = <int, int>{};

    while (movesUsed < p.desiredMoves) {
      if (tray.every((e) => e == null)) {
        for (int i = 0; i < kTraySize; i++) {
          final piece = GameEngine.randomPiece(rng, p.colorCount);
          tray[i] = piece;
          pool.add(piece);
        }
      }
      final move = bestPlacement(board, tray);
      if (move == null) break; // stuck

      final piece = tray[move.trayIndex]!;
      for (final cell in piece.coloredCells) {
        board.setCell(move.row + cell.row, move.col + cell.col, cell.colorIndex);
      }
      tray[move.trayIndex] = null;
      movesUsed++;

      final outcome = GameEngine.resolveBoard(board);
      totalCleared += outcome.totalCleared;
      outcome.byColor.forEach((k, v) => byColor[k] = (byColor[k] ?? 0) + v);
    }

    return _Design(
      seed: seed,
      initialGrid: initialGrid,
      pool: pool,
      movesUsed: movesUsed,
      totalCleared: totalCleared,
      byColor: byColor,
    );
  }

  /// Scatter isolated obstacle blocks, never adjacent to the same colour so they
  /// don't clear on their own before the player acts.
  static Board _buildObstacles(Random rng, _Difficulty p) {
    final board = Board();
    int placed = 0;
    int guard = 0;
    while (placed < p.obstacles && guard < p.obstacles * 40 + 20) {
      guard++;
      final r = rng.nextInt(kBoardSize);
      final c = rng.nextInt(kBoardSize);
      if (!board.isCellEmpty(r, c)) continue;
      final color = rng.nextInt(p.colorCount);
      const deltas = [[-1, 0], [1, 0], [0, -1], [0, 1]];
      bool clash = false;
      for (final d in deltas) {
        final nr = r + d[0];
        final nc = c + d[1];
        if (board.isValidPosition(nr, nc)) {
          final n = board.get(nr, nc);
          if (!n.isEmpty && n.colorIndex == color) {
            clash = true;
            break;
          }
        }
      }
      if (clash) continue;
      board.setCell(r, c, color);
      placed++;
    }
    return board;
  }

  static LevelDefinition _build(int index, int seed, _Difficulty p, _Design d) {
    final achieved = d.totalCleared;
    int target = (achieved * p.targetFraction).floor();
    target = target.clamp(0, achieved);
    if (achieved >= p.minTarget) target = target.clamp(p.minTarget, achieved);

    final slack = achieved - target;

    // Optional per-colour quota on the designer's dominant colour.
    final byColorTarget = <int, int>{};
    if (p.useColorQuota && d.byColor.isNotEmpty) {
      final dominant = d.byColor.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final quota = (dominant.value * p.colorQuotaFraction).floor();
      if (quota >= kClearThreshold) byColorTarget[dominant.key] = quota;
    }

    return LevelDefinition(
      index: index,
      seed: seed,
      initialGrid: d.initialGrid,
      pieceQueue: List.unmodifiable(d.pool),
      objective: LevelObjective(targetTotal: target, targetByColor: byColorTarget),
      moveLimit: d.pool.length,
      colorCount: p.colorCount,
      twoStarBonus: max(1, (slack * 0.35).floor()),
      threeStarBonus: max(2, (slack * 0.70).floor()),
    );
  }
}

class _Design {
  final int seed;
  final List<List<int>> initialGrid;
  final List<Piece> pool;
  final int movesUsed;
  final int totalCleared;
  final Map<int, int> byColor;

  _Design({
    required this.seed,
    required this.initialGrid,
    required this.pool,
    required this.movesUsed,
    required this.totalCleared,
    required this.byColor,
  });
}

/// Difficulty knobs derived from the (0-based) level index.
class _Difficulty {
  final int colorCount;
  final int desiredMoves;
  final int obstacles;
  final int minTarget;
  final int minAchieved;
  final double targetFraction;
  final bool useColorQuota;
  final double colorQuotaFraction;

  const _Difficulty({
    required this.colorCount,
    required this.desiredMoves,
    required this.obstacles,
    required this.minTarget,
    required this.minAchieved,
    required this.targetFraction,
    required this.useColorQuota,
    required this.colorQuotaFraction,
  });

  factory _Difficulty.forIndex(int index) {
    // Tutorial: levels 1-3 (index 0-2) — trivial, near impossible to fail.
    if (index < 3) {
      return const _Difficulty(
        colorCount: 3,
        desiredMoves: 6,
        obstacles: 0,
        minTarget: 3,
        minAchieved: 4,
        targetFraction: 0.35,
        useColorQuota: false,
        colorQuotaFraction: 0.5,
      );
    }

    final colorCount = index < 20
        ? 4
        : index < 50
            ? 5
            : 6;
    final desiredMoves = (6 + index ~/ 3).clamp(6, 27);
    final obstacles = index < 8 ? 0 : ((index - 8) ~/ 5).clamp(0, 16);
    final targetFraction = (0.5 + (index - 3) / 80 * 0.3).clamp(0.5, 0.8);

    return _Difficulty(
      colorCount: colorCount,
      desiredMoves: desiredMoves,
      obstacles: obstacles,
      minTarget: 5,
      minAchieved: 6,
      targetFraction: targetFraction,
      useColorQuota: index >= 15,
      colorQuotaFraction: 0.5,
    );
  }
}
