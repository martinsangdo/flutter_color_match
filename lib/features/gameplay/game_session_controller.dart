import 'package:flutter/foundation.dart';

import '../../core/audio/audio_service.dart';
import '../../data/levels/level_solver.dart';
import '../../data/levels/placement_strategy.dart';
import '../../data/models/level.dart';
import 'game_engine.dart';

/// Screen-scoped controller wrapping a [GameEngine] for one play session
/// (a campaign level or an endless run). The engine holds all rules; this adds
/// audio feedback, the hint highlight, and restart — and notifies the UI.
class GameSessionController extends ChangeNotifier {
  final LevelDefinition? level;
  final int endlessColorCount;
  final AudioService audio;

  late GameEngine engine;
  Placement? hint;

  GameSessionController({
    this.level,
    required this.audio,
    this.endlessColorCount = 5,
  }) {
    engine = _build();
  }

  bool get isEndless => level == null;

  GameEngine _build() => level != null
      ? GameEngine.forLevel(level!)
      : GameEngine.endless(colorCount: endlessColorCount);

  int get movesLeft =>
      engine.moveLimit < 0 ? -1 : (engine.moveLimit - engine.movesUsed);

  PlacementResult place(int trayIndex, int row, int col) {
    final result = engine.place(trayIndex, row, col);
    if (result.placed) {
      hint = null;
      final clears = result.clears;
      if (clears != null && clears.totalCleared > 0) {
        if (clears.cascades > 1) {
          audio.combo();
        } else {
          audio.clear();
        }
      } else {
        audio.place();
      }
      if (engine.status == GameStatus.won) {
        audio.win();
      } else if (engine.status == GameStatus.lost) {
        audio.lose();
      }
      notifyListeners();
    }
    return result;
  }

  void requestHint() {
    hint = LevelSolver.hint(engine);
    notifyListeners();
  }

  void clearHint() {
    if (hint != null) {
      hint = null;
      notifyListeners();
    }
  }

  void restart() {
    engine = _build();
    hint = null;
    notifyListeners();
  }
}
