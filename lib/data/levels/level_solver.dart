import '../../features/gameplay/game_engine.dart';
import '../models/level.dart';
import 'placement_strategy.dart';

/// Independently checks that a level can be won and supplies in-game hints.
///
/// [verify] does NOT trust the generator: it spins up a fresh engine from the
/// level's stored pool and plays a greedy strategy from scratch. If that reaches
/// the objective within the move limit, we have a concrete witnessed solution,
/// so the level is solvable. Used in tests and (in debug) at load time.
class LevelSolver {
  static bool verify(LevelDefinition level) {
    final engine = GameEngine.forLevel(level);
    int guard = 0;
    while (engine.status == GameStatus.playing && guard < 1000) {
      guard++;
      final move = bestPlacement(engine.board, engine.tray);
      if (move == null) break;
      engine.place(move.trayIndex, move.row, move.col);
    }
    return engine.status == GameStatus.won;
  }

  /// Best legal move for the engine's current state, or null if none — used by
  /// the Hint button to highlight a suggested placement.
  static Placement? hint(GameEngine engine) =>
      bestPlacement(engine.board, engine.tray);
}
