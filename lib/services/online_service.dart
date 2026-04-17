// Online multiplayer service
// NOTE: This version uses SharedPreferences-based simulation.
// For real online play, add Firebase (see SETUP_GUIDE.md).

import 'dart:async';
import 'package:flutter/foundation.dart';

class OnlineService {
  String? _myColor;
  String? _roomId;

  final _moveController = StreamController<String>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<String> get moveReceived => _moveController.stream;
  Stream<String> get statusStream => _statusController.stream;

  String? get myColor => _myColor;
  String? get roomId => _roomId;
  String? get myPlayerId => 'local_player';

  Future<String?> findMatch({required String username, required int elo}) async {
    _myColor = 'white';
    _roomId = 'DEMO_ROOM';
    _status('Demo mode — opponent simulation active');
    await Future.delayed(const Duration(seconds: 2));
    _status('You are White ♔ — make your move!');
    return _roomId;
  }

  Future<void> sendMove(String uciMove, String newFen) async {
    debugPrint('[Online] Move sent: $uciMove');
  }

  Future<void> resign() async {}
  Future<void> offerDraw() async {}
  Future<void> acceptDraw() async {}
  Future<void> sendChat(String message, String username) async {}

  Stream<List<Map<String, dynamic>>> chatStream() => Stream.value([]);

  void _status(String msg) {
    if (!_statusController.isClosed) _statusController.add(msg);
  }

  void dispose() {
    _moveController.close();
    _statusController.close();
  }
}
