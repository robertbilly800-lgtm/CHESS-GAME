import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multistockfish/multistockfish.dart';

class AiService {
  Stockfish? _stockfish;
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
    if (_disposed || _stockfish != null) return;
    try {
      _stockfish = Stockfish(flavor: StockfishFlavor.embeddedNNUE);
      if (_stockfish == null) throw Exception('Stockfish failed to start.');

      // Listen for output immediately
      _stockfish!.stdout.listen((line) {
        if (_disposed) return;
        if (line.trim() == 'readyok' || line.trim() == 'uciok') {
          _isReady = true;
        }
        _outputController.add(line);
      });

      // Wait for engine to be in ready state (max 8 seconds)
      int waited = 0;
      while (_stockfish!.state.value != StockfishState.ready) {
        if (_stockfish!.state.value == StockfishState.error) {
          throw Exception('Stockfish error state.');
        }
        if (waited > 8000) throw Exception('Stockfish boot timeout.');
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }

      _stockfish!.stdin = 'uci';
      _stockfish!.stdin = 'isready';

      // Give it a moment to respond readyok
      await Future.delayed(const Duration(milliseconds: 500));
      _isReady = true;
    } catch (e) {
      _isHardwareSupported = false;
      _errorMsg = e.toString();
      debugPrint('[AI] Init error: $e');
    }
  }

  void setDifficulty(int level) {
    if (!_isHardwareSupported || _stockfish == null) return;
    final skill = (level.clamp(1, 20) - 1);
    _stockfish!.stdin = 'setoption name Skill Level value $skill';
    // Limit depth for lower levels to speed up responses
    if (level < 5) {
      _stockfish!.stdin = 'setoption name Move Overhead value 50';
    }
  }

  /// Returns best move UCI string (e.g. "e2e4"), or null on failure.
  /// movetime is reduced to 800ms for snappy feel
  Future<String?> getBestMove(String fen, {int movetime = 800}) async {
    if (_stockfish == null || _thinking) return null;
    _thinking = true;

    // Wait up to 2s for ready
    if (!_isReady) {
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_isReady) break;
      }
    }
    if (!_isReady) {
      _thinking = false;
      return null;
    }

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
    _stockfish!.stdin = 'stop';
    _stockfish!.stdin = 'position fen $fen';
    _stockfish!.stdin = 'go movetime $movetime';

    final result = await completer.future;
    _thinking = false;
    return result;
  }

  void dispose() {
    _disposed = true;
    _thinking = false;
    try { _stockfish?.stdin = 'stop'; } catch (_) {}
    try { _stockfish?.stdin = 'quit'; } catch (_) {}
    _stockfish?.dispose();
    _outputController.close();
  }
}
