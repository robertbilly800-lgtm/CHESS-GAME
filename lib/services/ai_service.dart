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
    if (_disposed) return;

    try {
      debugPrint('[AI] Initializing Stockfish...');
      _stockfish = Stockfish();

      // Listen to engine output
      _stockfish!.stdout.listen((line) {
        if (_disposed) return;
        debugPrint('[AI] OUT: $line');
        if (line.trim() == 'uciok') {
          _isReady = true;
          debugPrint('[AI] Engine is ready (uciok received)');
        }
        _outputController.add(line);
      });

      // Wait for the engine to reach the 'ready' state (internal)
      int waited = 0;
      while (_stockfish!.state.value != StockfishState.ready && waited < 10000) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }

      if (_stockfish!.state.value != StockfishState.ready) {
        throw Exception('Engine did not reach ready state');
      }

      // Send UCI command and wait for uciok
      _stockfish!.stdin = 'uci';
      debugPrint('[AI] Sent uci, waiting for uciok...');

      // Wait up to 5 seconds for uciok
      waited = 0;
      while (!_isReady && waited < 5000) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }

      if (!_isReady) {
        throw Exception('Engine did not respond with uciok');
      }

      // Optional: set some default options (e.g., threads)
      _stockfish!.stdin = 'setoption name Threads value 2';
      _stockfish!.stdin = 'isready';
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint('[AI] Stockfish ready and responding.');
    } catch (e) {
      _isHardwareSupported = false;
      _errorMsg = e.toString();
      debugPrint('[AI] Init error: $e');
    }
  }

  void setDifficulty(int level) {
    if (!_isReady || _stockfish == null) return;
    // Skill level from 0 (weak) to 20 (strong)
    final skill = (level.clamp(1, 20) - 1);
    _stockfish!.stdin = 'setoption name Skill Level value $skill';
    debugPrint('[AI] Set skill level to $skill');
  }

  Future<String?> getBestMove(String fen, {int movetime = 800}) async {
    if (!_isReady || _stockfish == null || _disposed) return null;
    if (_thinking) {
      debugPrint('[AI] Already thinking, stopping previous search');
      _stockfish!.stdin = 'stop';
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _thinking = true;
    debugPrint('[AI] Request move for fen: $fen');

    final completer = Completer<String?>();
    StreamSubscription? sub;

    final timeout = Timer(Duration(milliseconds: movetime + 1500), () {
      if (!completer.isCompleted) {
        debugPrint('[AI] Timeout, stopping engine');
        _stockfish!.stdin = 'stop';
        completer.complete(null);
      }
      sub?.cancel();
      _thinking = false;
    });

    sub = _outputController.stream.listen((line) {
      if (line.startsWith('bestmove')) {
        final parts = line.trim().split(' ');
        final move = parts.length >= 2 ? parts[1] : null;
        if (move != null && move != '(none)') {
          debugPrint('[AI] Best move: $move');
          if (!completer.isCompleted) {
            completer.complete(move);
          }
        } else {
          if (!completer.isCompleted) completer.complete(null);
        }
        timeout.cancel();
        sub?.cancel();
        _thinking = false;
      }
    });

    // Send commands (no newline characters)
    _stockfish!.stdin = 'stop';
    _stockfish!.stdin = 'ucinewgame';
    _stockfish!.stdin = 'position fen $fen';
    _stockfish!.stdin = 'go movetime $movetime';

    return completer.future;
  }

  void dispose() {
    _disposed = true;
    _thinking = false;
    try {
      _stockfish?.stdin = 'stop';
      _stockfish?.stdin = 'quit';
    } catch (_) {}
    _stockfish?.dispose();
    _outputController.close();
  }
}
