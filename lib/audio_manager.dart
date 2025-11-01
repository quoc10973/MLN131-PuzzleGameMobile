import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  late AudioPlayer _backgroundPlayer;
  late AudioPlayer _flipPlayer;
  late AudioPlayer _correctPlayer;
  bool _isInitialized = false;
  bool _isPlayingFlip = false;
  bool _isPlayingCorrect = false;
  bool _isMenuMusicPlaying = false;

  void initialize() {
    if (_isInitialized) return;
    _backgroundPlayer = AudioPlayer(playerId: 'global_background');
    _flipPlayer = AudioPlayer(playerId: 'global_flip');
    _correctPlayer = AudioPlayer(playerId: 'global_correct');
    
    _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    _flipPlayer.setReleaseMode(ReleaseMode.release);
    _correctPlayer.setReleaseMode(ReleaseMode.release);
    
    _isInitialized = true;
  }

  Future<void> playMenuMusic() async {
    print('playMenuMusic called');
    initialize();
    try {
      print('Stopping background player');
      await _backgroundPlayer.stop();
      print('Playing main_menu.mp3');
      await _backgroundPlayer.play(AssetSource('music/main_menu.mp3'));
      _isMenuMusicPlaying = true;
      print('Menu music playing');
    } catch (e) {
      print('Error playing menu music: $e');
      _isMenuMusicPlaying = false;
    }
  }

  Future<void> playGameMusic() async {
    initialize();
    try {
      await _backgroundPlayer.stop();
      _isMenuMusicPlaying = false;
    } catch (e) {
      print('Error stopping menu music: $e');
    }
  }

  Future<void> playFlipSound() async {
    if (_isPlayingFlip) return;
    _isPlayingFlip = true;
    try {
      await _flipPlayer.play(AssetSource('music/flip.mp3'));
    } catch (e) {
      print('Error playing flip sound: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 200), () {
        _isPlayingFlip = false;
      });
    }
  }

  Future<void> playCorrectSound() async {
    if (_isPlayingCorrect) return;
    _isPlayingCorrect = true;
    try {
      await _correctPlayer.play(AssetSource('music/correct.mp3'));
    } catch (e) {
      print('Error playing correct sound: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isPlayingCorrect = false;
      });
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    try {
      await _backgroundPlayer.stop();
    } catch (e) {
      print('Error stopping music: $e');
    }
  }

  void dispose() {
    if (_isInitialized) {
      _backgroundPlayer.dispose();
      _flipPlayer.dispose();
      _correctPlayer.dispose();
      _isInitialized = false;
    }
  }
}

