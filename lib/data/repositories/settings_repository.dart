import 'package:shared_preferences/shared_preferences.dart';

/// Simple persisted flags. Structured level progress lives in [ProgressRepository]
/// (Hive); these lightweight booleans stay in shared_preferences per the spec.
class AppSettings {
  final bool soundOn;
  final bool musicOn;
  final bool howToPlaySeen;

  const AppSettings({
    this.soundOn = true,
    this.musicOn = true,
    this.howToPlaySeen = false,
  });

  AppSettings copyWith({bool? soundOn, bool? musicOn, bool? howToPlaySeen}) =>
      AppSettings(
        soundOn: soundOn ?? this.soundOn,
        musicOn: musicOn ?? this.musicOn,
        howToPlaySeen: howToPlaySeen ?? this.howToPlaySeen,
      );
}

class SettingsRepository {
  static const _kSound = 'sound_on';
  static const _kMusic = 'music_on';
  static const _kHowTo = 'how_to_play_seen';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      soundOn: prefs.getBool(_kSound) ?? true,
      musicOn: prefs.getBool(_kMusic) ?? true,
      howToPlaySeen: prefs.getBool(_kHowTo) ?? false,
    );
  }

  Future<void> setSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSound, value);
  }

  Future<void> setMusic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMusic, value);
  }

  Future<void> setHowToPlaySeen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHowTo, value);
  }
}
