import 'package:audioplayers/audioplayers.dart';

/// Thin wrapper over audioplayers for short SFX and looping music.
///
/// Every call is wrapped so a missing asset (none ship in the repo yet — drop
/// files into assets/audio/) simply no-ops instead of crashing. Sound and music
/// can be toggled independently; the flags are driven by persisted settings.
class AudioService {
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  bool soundOn = true;
  bool musicOn = true;
  bool _musicWanted = false;

  void applySettings({required bool soundOn, required bool musicOn}) {
    this.soundOn = soundOn;
    this.musicOn = musicOn;
    if (!musicOn) {
      _stopMusic();
    } else if (_musicWanted) {
      startMusic();
    }
  }

  Future<void> _play(String file) async {
    if (!soundOn) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource('audio/$file'));
    } catch (_) {
      // Asset not present / platform without audio — ignore.
    }
  }

  Future<void> tap() => _play('tap.mp3');
  Future<void> place() => _play('place.mp3');
  Future<void> clear() => _play('clear.mp3');
  Future<void> combo() => _play('combo.mp3');
  Future<void> win() => _play('win.mp3');
  Future<void> lose() => _play('lose.mp3');

  Future<void> startMusic() async {
    _musicWanted = true;
    if (!musicOn) return;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(AssetSource('audio/music.mp3'));
    } catch (_) {
      // No music asset yet — ignore.
    }
  }

  void stopMusic() {
    _musicWanted = false;
    _stopMusic();
  }

  void _stopMusic() {
    try {
      _music.stop();
    } catch (_) {}
  }

  void dispose() {
    _sfx.dispose();
    _music.dispose();
  }
}
