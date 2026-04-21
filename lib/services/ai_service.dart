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

      _stockfish!.stdout.listen((line) {
        if (_disposed) return;

        debugPrint('[AI] OUT: $line');

        if (line.trim() == 'uciok' || line.trim() == 'readyok') {
          _isReady = true;
        }

        _outputController.add(line);
      });

      int waited = 0;
      while (_stockfish!.state.value != StockfishState.ready) {
        if (waited > 10000) {
          throw Exception('Stockfish failed to reach READY state');
        }
        await Future.delayed(const Duration(milliseconds: 200));
        waited += 200;
      }

      debugPrint('[AI] Sending UCI handshake...');
      _stockfish!.stdin = 'uci\n';
      _stockfish!.stdin = 'isready\n';

      await Future.delayed(const Duration(milliseconds: 800));

      if (!_isReady) {
        throw Exception('Stockfish did not respond to UCI handshake');
      }

      debugPrint('[AI] Stockfish ready.');
    } catch (e) {
      _isHardwareSupported = false;
      _errorMsg = e.toString();
      debugPrint('[AI] Init error: $e');
    }
  }

  void setDifficulty(int level) {
    if (!_isReady || _stockfish == null) return;

    final skill = (level.clamp(1, 20) - 1);
    _stockfish!.stdin = 'setoption name Skill Level value $skill\n';
  }

  Future<String?> getBestMove(String fen, {int movetime = 800}) async {
    if (!_isReady || _stockfish == null || _disposed) return null;

    debugPrint("[AI] Request move for FEN: $fen");

    if (_thinking) {
      debugPrint("[AI] Already thinking → forcing stop");
      _stockfish!.stdin = 'stop\n';
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _thinking = true;

    final completer = Completer<String?>();
    StreamSubscription? sub;

    final timeout = Timer(Duration(milliseconds: movetime + 1500), () {
      if (!completer.isCompleted) {
        debugPrint("[AI] Timeout → stopping engine");
        _stockfish!.stdin = 'stop\n';
        completer.complete(null);
      }
      sub?.cancel();
      _thinking = false;
    });

    sub = _outputController.stream.listen((line) {
      if (line.startsWith('bestmove')) {
        final parts = line.trim().split(RegExp(r'\s+'));
        final move = parts.length >= 2 ? parts[1] : null;

        debugPrint("[AI] BestMove: $move");

        if (!completer.isCompleted) {
          completer.complete(move == '(none)' ? null : move);
        }

        timeout.cancel();
        sub?.cancel();
        _thinking = false;
      }
    });

    _stockfish!.stdin = 'stop\n';
    _stockfish!.stdin = 'ucinewgame\n';
    _stockfish!.stdin = 'position fen $fen\n';
    _stockfish!.stdin = 'go movetime $movetime\n';

    return completer.future;
  }

  void dispose() {
    _disposed = true;
    _stockfish?.stdin = 'stop\n';
    _stockfish?.dispose();
    _outputController.close();
  }
}
