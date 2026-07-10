import '../../features/gameplay/game_engine.dart';
import '../models/board.dart';
import '../models/piece.dart';

/// A concrete candidate move and how good it looks.
class Placement {
  final int trayIndex;
  final int row;
  final int col;
  final int cleared; // cells cleared immediately by this move
  final int score; // heuristic tie-breaker

  const Placement({
    required this.trayIndex,
    required this.row,
    required this.col,
    required this.cleared,
    required this.score,
  });
}

/// Deterministic greedy move selection shared by the level generator (to build
/// a solvable playthrough), the solver (to witness a solution) and the in-game
/// hint. Given a board and the current tray, returns the best legal move, or
/// null if nothing can be placed.
Placement? bestPlacement(Board board, List<Piece?> tray) {
  Placement? best;

  for (int t = 0; t < tray.length; t++) {
    final piece = tray[t];
    if (piece == null) continue;

    for (int r = 0; r <= kBoardSize - piece.rows; r++) {
      for (int c = 0; c <= kBoardSize - piece.cols; c++) {
        if (!_canPlace(board, piece, r, c)) continue;

        final trial = Board.from(board);
        for (final cell in piece.coloredCells) {
          trial.setCell(r + cell.row, c + cell.col, cell.colorIndex);
        }
        final cleared = GameEngine.resolveBoard(trial).totalCleared;

        // Prefer clears; then building same-colour adjacency; then keeping the
        // board emptier. The weights keep this ordering total & deterministic.
        final adjacency = _adjacencyBonus(board, piece, r, c);
        final fill = trial.filledCount;
        final score = cleared * 1000 + adjacency * 10 - fill;

        if (best == null ||
            cleared > best.cleared ||
            (cleared == best.cleared && score > best.score)) {
          best = Placement(
            trayIndex: t,
            row: r,
            col: c,
            cleared: cleared,
            score: score,
          );
        }
      }
    }
  }
  return best;
}

bool _canPlace(Board board, Piece piece, int row, int col) {
  for (final cell in piece.coloredCells) {
    if (!board.isCellEmpty(row + cell.row, col + cell.col)) return false;
  }
  return true;
}

/// Count neighbours of the placed cells that already share their colour —
/// rewards moves that grow toward a future clear.
int _adjacencyBonus(Board board, Piece piece, int row, int col) {
  int bonus = 0;
  const deltas = [[-1, 0], [1, 0], [0, -1], [0, 1]];
  for (final cell in piece.coloredCells) {
    final r = row + cell.row;
    final c = col + cell.col;
    for (final d in deltas) {
      final nr = r + d[0];
      final nc = c + d[1];
      if (board.isValidPosition(nr, nc)) {
        final n = board.get(nr, nc);
        if (!n.isEmpty && n.colorIndex == cell.colorIndex) bonus++;
      }
    }
  }
  return bonus;
}
