import 'piece.dart';

/// What the player must achieve to win a level.
///
/// [targetTotal] is the minimum number of cells that must be cleared overall.
/// [targetByColor] optionally requires a minimum cleared count per colour
/// index — used from the mid-game on to force deliberate matching.
class LevelObjective {
  final int targetTotal;
  final Map<int, int> targetByColor;

  const LevelObjective({required this.targetTotal, this.targetByColor = const {}});

  bool isMetBy(int totalCleared, Map<int, int> clearedByColor) {
    if (totalCleared < targetTotal) return false;
    for (final entry in targetByColor.entries) {
      if ((clearedByColor[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  /// Human readable requirement lines for the objective bar.
  List<String> describe() {
    final lines = <String>['Clear $targetTotal blocks'];
    for (final entry in targetByColor.entries) {
      lines.add('${entry.value}× colour');
    }
    return lines;
  }
}

/// A fully-resolved, playable level. Levels are produced deterministically from
/// their index by [LevelGenerator], so only the index needs to be persisted —
/// the definition is regenerated (and cached) on demand.
class LevelDefinition {
  final int index; // 0-based
  final int seed;
  final List<List<int>> initialGrid; // 10x10 colour indices, -1 = empty
  final List<Piece> pieceQueue; // fed to the tray, in order
  final LevelObjective objective;
  final int moveLimit; // max pieces the player may place
  final int colorCount; // colours in play for this level

  /// Extra clears beyond the objective needed for 2 / 3 stars.
  final int twoStarBonus;
  final int threeStarBonus;

  const LevelDefinition({
    required this.index,
    required this.seed,
    required this.initialGrid,
    required this.pieceQueue,
    required this.objective,
    required this.moveLimit,
    required this.colorCount,
    required this.twoStarBonus,
    required this.threeStarBonus,
  });

  int get number => index + 1;

  /// Stars (1-3) earned for clearing [totalCleared] cells, assuming the
  /// objective was met. More overkill above the target earns more stars.
  int starsFor(int totalCleared) {
    if (totalCleared >= objective.targetTotal + threeStarBonus) return 3;
    if (totalCleared >= objective.targetTotal + twoStarBonus) return 2;
    return 1;
  }
}
