import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multistockfish/multistockfish.dart';

class AiService {
  // Create a single instance of Stockfish
  late final Stockfish _stockfish;
  final _outputController = StreamController<String>.broadcast();
  bool _isReady = false;
  bool _isHardwareSupported = true;
  bool _disposed = false;
  bool _thinking = false;

  bool get isReady => _isReady;
  bool get isHardwareSupported => _isHardwareSupported;
  bool get isThinking => _thinking;
  String _errorMsg = '';
  String get errorMsg => _errorMsg;

  Future<void> init() async {
    if (_disposed) return;

    try {
      // 1. Create the Stockfish instance. This is the correct way.
      _stockfish = Stockfish();

      // 2. Listen to the engine's stdout stream.
      _stockfish.stdout.listen((line) {
        if (_disposed) return;
        if (line.trim() == 'readyok' || line.trim() == 'uciok') {
          _isReady = true;
        }
        _outputController.add(line);
      });

      // 3. Wait for the engine to be in 'ready' state.
      // The state is a ValueListenable, we need to check it periodically.
      // A simple and reliable way is to wait a short moment and then check the state.
      // A more robust way is to use a timer to check the state.
      int waited = 0;
      while (_stockfish.state.value != StockfishState.ready) {
        if (waited > 8000) throw Exception('Stockfish boot timeout.');
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }

      // 4. Send initial UCI commands to finalize the engine's startup.
      _stockfish.stdin = 'uci';
      _stockfish.stdin = 'isready';

      // Give it a short moment to respond with 'readyok'
      await Future.delayed(const Duration(milliseconds: 500));
      _isReady = true;

      debugPrint('[AI] Engine initialized successfully');
    } catch (e) {
      _isHardwareSupported = false;
      _errorMsg = e.toString();
      debugPrint('[AI] Init error: $e');
    }
  }

  void setDifficulty(int level) {
    if (!_isHardwareSupported || !_isReady) return;
    // Skill level ranges from 0 to 20. The provided level (1-20) is mapped accordingly.
    final skill = (level.clamp(1, 20) - 1);
    _stockfish.stdin = 'setoption name Skill Level value $skill';
    if (level < 5) {
      _stockfish.stdin = 'setoption name Move Overhead value 50';
    }
  }

  /// Returns best move UCI string (e.g. "e2e4"), or null on failure.
  Future<String?> getBestMove(String fen, {int movetime = 800}) async {
    if (!_isReady || _thinking) return null;
    _thinking = true;

    final completer = Completer<String?>();
    StreamSubscription? sub;

    final timeout = Timer(Duration(milliseconds: movetime + 2000), () {
      if (!completer.isCompleted) {
        completer.complete(null);
        sub?.cancel();
      }
    });

    sub = _outputController.stream.listen((line) {
      if (line.startsWith('bestmove')) {
        final parts = line.trim().split(' ');
        final move = parts.length >= 2 ? parts[1] : null;
        if (!completer.isCompleted) {
          completer.complete(move == '(none)' ? null : move);
          sub?.cancel();
          timeout.cancel();
        }
      }
    });

    // Stop any previous search first
    _stockfish.stdin = 'stop';
    _stockfish.stdin = 'position fen $fen';
    _stockfish.stdin = 'go movetime $movetime';

    final result = await completer.future;
    _thinking = false;
    return result;
  }

  void dispose() {
    _disposed = true;
    _thinking = false;
    try {
      _stockfish.stdin = 'stop';
    } catch (_) {}
    try {
      _stockfish.stdin = 'quit';
    } catch (_) {}
    _stockfish.dispose();
    _outputController.close();
  }
}
