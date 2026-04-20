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
      debugPrint('[AI] Starting Stockfish engine...');
      _stockfish = Stockfish();

      _stockfish!.stdout.listen((line) {
        if (_disposed) return;
        debugPrint('[AI] OUT: $line');
        if (line.trim() == 'readyok' || line.trim() == 'uciok') {
          _isReady = true;
        }
        _outputController.add(line);
      });

      int waited = 0;
      while (_stockfish!.state.value != StockfishState.ready) {
        if (waited > 10000) throw Exception('Stockfish boot timeout - Engine failed to reach READY state');
        await Future.delayed(const Duration(milliseconds: 200));
        waited += 200;
        if (waited % 2000 == 0) debugPrint('[AI] Still waiting for engine ready... (${waited}ms)');
      }

      debugPrint('[AI] Sending UCI handshake...');
      _stockfish!.stdin = 'uci';
      _stockfish!.stdin = 'isready';
      
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (!_isReady) {
        debugPrint('[AI] Warning: engine did not acknowledge UCI/ISREADY within 1s. Forcing ready state.');
        _isReady = true;
      }

      debugPrint('[AI] Engine fully initialized and ready.');
    } catch (e) {
      _isHardwareSupported = false;
      _errorMsg = e.toString();
      debugPrint('[AI] FATAL Init error: $e');
    }
  }

  void setDifficulty(int level) {
    if (!_isHardwareSupported || !_isReady || _stockfish == null) return;
    final skill = (level.clamp(1, 20) - 1);
    _stockfish!.stdin = 'setoption name Skill Level value $skill';
  }

  Future<String?> getBestMove(String fen, {int movetime = 800}) async {
    if (!_isReady || _thinking || _stockfish == null) return null;
    _thinking = true;

    final completer = Completer<String?>();
    StreamSubscription? sub;
    final timeout = Timer(Duration(milliseconds: movetime + 2000), () {
      if (!completer.isCompleted) completer.complete(null);
      sub?.cancel();
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
    return result;
  }

  void dispose() {
    _disposed = true;
    _stockfish?.dispose();
    _outputController.close();
  }
}
