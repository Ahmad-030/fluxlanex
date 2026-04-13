import 'package:audioplayers/audioplayers.dart';
import '../utils/prefs_manager.dart';


class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _musicEnabled = true;
  bool _isPlaying = false;

  Future<void> init() async {
    _musicEnabled = await PrefsManager.getMusicEnabled();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.5);
  }

  Future<void> playMusic() async {
    if (!_musicEnabled) return;
    if (_isPlaying) return;
    try {
      await _player.play(AssetSource('audio/music.mp3'));
      _isPlaying = true;
    } catch (_) {}
  }

  Future<void> pauseMusic() async {
    if (!_isPlaying) return;
    await _player.pause();
    _isPlaying = false;
  }

  Future<void> resumeMusic() async {
    if (!_musicEnabled) return;
    await _player.resume();
    _isPlaying = true;
  }

  Future<void> stopMusic() async {
    await _player.stop();
    _isPlaying = false;
  }

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    await PrefsManager.saveMusicEnabled(_musicEnabled);
    if (_musicEnabled) {
      await playMusic();
    } else {
      await stopMusic();
    }
  }

  bool get isMusicEnabled => _musicEnabled;
  bool get isPlaying => _isPlaying;

  void dispose() {
    _player.dispose();
  }
}
