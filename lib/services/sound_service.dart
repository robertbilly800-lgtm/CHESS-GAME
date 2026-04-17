import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;

  bool get isMuted => _isMuted;
  void setMuted(bool v) => _isMuted = v;
  void toggleMute() => _isMuted = !_isMuted;

  Future<void> _play(String asset) async {
    if (_isMuted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('[Sound] $asset error: $e');
    }
  }

  Future<void> playMove() => _play('sounds/move.mp3');
  Future<void> playCapture() => _play('sounds/capture.mp3');
  Future<void> playCheck() => _play('sounds/check.mp3');
  Future<void> playGameOver() => _play('sounds/game_over.mp3');
  Future<void> playButtonTap() => _play('sounds/move.mp3');

  void dispose() => _player.dispose();
}
