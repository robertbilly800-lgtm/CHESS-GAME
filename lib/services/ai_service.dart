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
  bool get isThinking => _isThinking;
  String _errorMsg = '';
  String get errorMsg => _errorMsg;

  Future<void> init() async {
    if (_disposed) return;

    try {
      debugPrint('[AI] Creating Stockfish...');
      _stockfish = Stockfish();

      _stockfish!.stdout.listen((line) {
        if (_disposed) return;
        debugPrint('[AI] STDOUT: $line');
        if (line.trim() == 'uciok') {
          _isReady = true;
          debugPrint('[AI] uciok received');
        }
        _outputController.add(line);
      });

      debugPrint('[AI] Waiting for engine ready state...');
      int waited = 0;
      while (_stockfish!.state.value != StockfishState.ready && waited < 10000) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }
      if (_stockfish!.state.value != StockfishState.ready) {
        throw Exception('Engine state not ready after ${waited}ms');
      }
      debugPrint('[AI] Engine state ready. Sending uci...');

      _stockfish!.stdin = 'uci';

      waited = 0;
      while (!_isReady && waited < 5000) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }
      if (!_isReady) throw Exception('No uciok after $waited ms');

      _stockfish!.stdin = 'isready';
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('[AI] AI initialization complete.');
    } catch (e) {
      _isHardwareSupported = false;
      _errorMsg = e.toString();
      debugPrint('[AI] Init error: $e');
    }
  }

  void setDifficulty(int level) {
    if (!_isReady || _stockfish == null) return;
    final skill = (level.clamp(1, 20) - 1);
    _stockfish!.stdin = 'setoption name Skill Level value $skill';
    debugPrint('[AI] Difficulty set to $skill');
  }

  Future<String?> getBestMove(String fen, {int movetime = 800}) async {
    if (!_isReady || _stockfish == null || _disposed) {
      debugPrint('[AI] getBestMove called but not ready');
      return null;
    }
    if (_thinking) {
      debugPrint('[AI] Already thinking, stopping previous search');
      _stockfish!.stdin = 'stop';
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _thinking = true;
    debugPrint('[AI] getBestMove for fen: $fen');

    final completer = Completer<String?>();
    StreamSubscription? sub;

    final timeout = Timer(Duration(milliseconds: movetime + 2000), () {
      if (!completer.isCompleted) {
        debugPrint('[AI] Timeout reached');
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
        debugPrint('[AI] Received bestmove: $move');
        if (!completer.isCompleted && move != null && move != '(none)') {
          completer.complete(move);
        } else if (!completer.isCompleted) {
          completer.complete(null);
        }
        timeout.cancel();
        sub?.cancel();
        _thinking = false;
      }
    });

    _stockfish!.stdin = 'stop';
    _stockfish!.stdin = 'ucinewgame';
    _stockfish!.stdin = 'position fen $fen';
    _stockfish!.stdin = 'go movetime $movetime';
    debugPrint('[AI] Sent position and go movetime $movetime');

    final result = await completer.future;
    debugPrint('[AI] Returning best move: $result');
    return result;
  }

  void dispose() {
    _disposed = true;
    _thinking = false;
    try {
      _stockfish?.stdin = 'quit';
    } catch (_) {}
    _stockfish?.dispose();
    _outputController.close();
  }
}
