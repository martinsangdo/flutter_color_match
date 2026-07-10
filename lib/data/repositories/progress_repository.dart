import 'package:hive/hive.dart';

import '../models/progress.dart';

/// Structured, per-level progress store backed by Hive (a real schema, as the
/// 80+ levels of state warrant). Keys are the level index as a string; values
/// are small maps of {completed, stars, bestCleared}.
class ProgressRepository {
  static const String boxName = 'level_progress';

  final Box _box;

  ProgressRepository(this._box);

  /// Open the box. Call once at startup after Hive.initFlutter().
  static Future<ProgressRepository> open() async {
    final box = await Hive.openBox(boxName);
    return ProgressRepository(box);
  }

  LevelProgress get(int index) {
    final raw = _box.get(index.toString());
    if (raw is Map) return LevelProgress.fromMap(index, raw);
    return LevelProgress(index: index);
  }

  Map<int, LevelProgress> all(int levelCount) {
    final result = <int, LevelProgress>{};
    for (int i = 0; i < levelCount; i++) {
      result[i] = get(i);
    }
    return result;
  }

  Future<LevelProgress> record(
    int index, {
    required bool completed,
    required int stars,
    required int cleared,
  }) async {
    final updated = get(index)
        .merge(completed: completed, stars: stars, cleared: cleared);
    await _box.put(index.toString(), updated.toMap());
    return updated;
  }

  /// A level is unlocked if it's the first one or the previous is completed.
  bool isUnlocked(int index) => index == 0 || get(index - 1).completed;

  Future<void> resetAll() => _box.clear();
}
