import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multistockfish/multistockfish.dart';
import 'logger_service.dart';

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
    if (_disposed) return;
    try {
      // Create instance – engine starts automatically (no .start() method)
      _stockfish = Stockfish();

      _stockfish!.stdout.listen((line) {
        if (_disposed) return;
        if (line.trim() == 'readyok' || line.trim() == 'uciok') {
          _isReady = true;
        }
        _outputController.add(line);
      });

      // Wait for engine to become ready
      int waited = 0;
      while (_stockfish!.state.value != StockfishState.ready) {
        if (waited > 8000) throw Exception('Stockfish boot timeout');
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }

      // Send UCI commands
      _stockfish!.stdin = 'uci';
      _stockfish!.stdin = 'isready';
      await Future.delayed(const Duration(milliseconds: 500));
      _isReady = true;

      debugPrint('[AI] Engine initialized successfully');
      await AppLogger().log('AI initialized successfully');
    } catch (e) {
      _isHardwareSupported = false;
      _errorMsg = e.toString();
      debugPrint('[AI] Init error: $e');
      await AppLogger().log('AI init error: $e');
    }
  }

  void setDifficulty(int level) {
    if (!_isHardwareSupported || !_isReady || _stockfish == null) return;
    final skill = (level.clamp(1, 20) - 1);
    _stockfish!.stdin = 'setoption name Skill Level value $skill';
    if (level < 5) {
      _stockfish!.stdin = 'setoption name Move Overhead value 50';
    }
  }

  Future<String?> getBestMove(String fen, {int movetime = 800}) async {
    if (!_isReady || _thinking || _stockfish == null) return null;
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

    _stockfish!.stdin = 'stop';
    _stockfish!.stdin = 'position fen $fen';
    _stockfish!.stdin = 'go movetime $movetime';

    final result = await completer.future;
    _thinking = false;
    if (result == null) {
      await AppLogger().log('AI getBestMove returned null for fen: $fen');
    }
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
