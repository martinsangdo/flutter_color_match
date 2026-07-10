import '../levels/level_generator.dart';
import '../models/level.dart';

/// Lazily produces and caches level definitions so we never hold all 90 levels
/// (and their piece pools) in memory at once. Definitions are deterministic per
/// index, so a cached level is always identical to a freshly generated one.
class LevelRepository {
  final Map<int, LevelDefinition> _cache = {};

  int get levelCount => kLevelCount;

  LevelDefinition level(int index) {
    return _cache.putIfAbsent(index, () => LevelGenerator.generate(index));
  }

  /// Drop cached definitions to reclaim memory (e.g. on memory pressure).
  void evictAll() => _cache.clear();
}
