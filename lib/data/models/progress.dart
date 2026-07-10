/// Persisted progress for a single level.
class LevelProgress {
  final int index;
  final bool completed;
  final int stars; // 0..3
  final int bestCleared;

  const LevelProgress({
    required this.index,
    this.completed = false,
    this.stars = 0,
    this.bestCleared = 0,
  });

  LevelProgress merge({required bool completed, required int stars, required int cleared}) {
    return LevelProgress(
      index: index,
      completed: this.completed || completed,
      stars: stars > this.stars ? stars : this.stars,
      bestCleared: cleared > bestCleared ? cleared : bestCleared,
    );
  }

  Map<String, dynamic> toMap() => {
        'completed': completed,
        'stars': stars,
        'bestCleared': bestCleared,
      };

  factory LevelProgress.fromMap(int index, Map map) => LevelProgress(
        index: index,
        completed: map['completed'] as bool? ?? false,
        stars: map['stars'] as int? ?? 0,
        bestCleared: map['bestCleared'] as int? ?? 0,
      );
}
