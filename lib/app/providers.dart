import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/audio_service.dart';
import '../data/models/progress.dart';
import '../data/repositories/level_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/settings_repository.dart';

/// --- Repositories / services ------------------------------------------------

final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => SettingsRepository());

final levelRepositoryProvider =
    Provider<LevelRepository>((ref) => LevelRepository());

final audioServiceProvider = Provider<AudioService>((ref) {
  final audio = AudioService();
  ref.onDispose(audio.dispose);
  return audio;
});

/// Overridden in main() with the opened Hive-backed repository.
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => throw UnimplementedError('progressRepositoryProvider must be overridden'),
);

/// --- Settings ---------------------------------------------------------------

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repo;
  final AudioService _audio;

  SettingsNotifier(this._repo, this._audio) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final settings = await _repo.load();
    state = settings;
    _audio.applySettings(soundOn: settings.soundOn, musicOn: settings.musicOn);
  }

  Future<void> setSound(bool value) async {
    await _repo.setSound(value);
    state = state.copyWith(soundOn: value);
    _audio.applySettings(soundOn: value, musicOn: state.musicOn);
  }

  Future<void> setMusic(bool value) async {
    await _repo.setMusic(value);
    state = state.copyWith(musicOn: value);
    _audio.applySettings(soundOn: state.soundOn, musicOn: value);
  }

  Future<void> markHowToPlaySeen() async {
    await _repo.setHowToPlaySeen(true);
    state = state.copyWith(howToPlaySeen: true);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(
    ref.watch(settingsRepositoryProvider),
    ref.watch(audioServiceProvider),
  );
});

/// --- Progress (reactive: Level Select rebuilds the moment this changes) ------

class ProgressNotifier extends StateNotifier<Map<int, LevelProgress>> {
  final ProgressRepository _repo;
  final int levelCount;

  ProgressNotifier(this._repo, this.levelCount)
      : super(_repo.all(levelCount));

  bool isUnlocked(int index) =>
      index == 0 || (state[index - 1]?.completed ?? false);

  int get totalStars =>
      state.values.fold(0, (sum, p) => sum + p.stars);

  int get completedCount =>
      state.values.where((p) => p.completed).length;

  Future<void> record(
    int index, {
    required bool completed,
    required int stars,
    required int cleared,
  }) async {
    final updated = await _repo.record(
      index,
      completed: completed,
      stars: stars,
      cleared: cleared,
    );
    state = {...state, index: updated};
  }

  Future<void> resetAll() async {
    await _repo.resetAll();
    state = _repo.all(levelCount);
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, Map<int, LevelProgress>>((ref) {
  return ProgressNotifier(
    ref.watch(progressRepositoryProvider),
    ref.watch(levelRepositoryProvider).levelCount,
  );
});
