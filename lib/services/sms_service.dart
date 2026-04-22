import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;
  Function(String)? _onMoveReceived;

  Future<bool> isSupported() async => true;

  Future<void> listenForMoves({required Function(String) onMoveReceived}) async {
    _onMoveReceived = onMoveReceived;
    final granted = await _telephony.requestSmsPermissions;
    if (granted != true) return;
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final body = message.body ?? '';
        if (body.length >= 4 && RegExp(r'^[a-h][1-8][a-h][1-8]').hasMatch(body.substring(0, 4))) {
          _onMoveReceived?.call(body.substring(0, 4));
        }
      },
      listenInBackground: false,
    );
  }

  Future<void> sendMove({
    required String phoneNumber,
    required String sanMove,   // <-- this matches chess_screen.dart
    Function(bool)? onResult,
  }) async {
    if (phoneNumber.trim().isEmpty) {
      onResult?.call(false);
      return;
    }
    final granted = await _telephony.requestSmsPermissions;
    if (granted != true) {
      onResult?.call(false);
      return;
    }
    try {
      await _telephony.sendSms(to: phoneNumber, message: sanMove);
      onResult?.call(true);
    } catch (e) {
      debugPrint('SMS error: $e');
      onResult?.call(false);
    }
  }
}
