// import 'package:audioplayers/audioplayers.dart'; // Temporarily disabled

class SoundService {
  // final AudioPlayer _player = AudioPlayer(); // Temporarily disabled
  bool _isMuted = false;

  bool get isMuted => _isMuted;

  void setMuted(bool value) {
    _isMuted = value;
  }

  Future<void> playButtonTap() async {
    if (_isMuted) return;
    // Infrastructure for feedback sounds
  }

  void toggleMute() {
    _isMuted = !_isMuted;
  }

  Future<void> playMove() async {
    if (_isMuted) return;
    // await _player.play(AssetSource('sounds/move.mp3'));
  }

  Future<void> playCapture() async {
    if (_isMuted) return;
    // await _player.play(AssetSource('sounds/capture.mp3'));
  }

  Future<void> playCheck() async {
    if (_isMuted) return;
    // await _player.play(AssetSource('sounds/check.mp3'));
  }

  Future<void> playGameOver() async {
    if (_isMuted) return;
    // await _player.play(AssetSource('sounds/game_over.mp3'));
  }

  void dispose() {
    // _player.dispose();
  }
}
