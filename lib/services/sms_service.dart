import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';  // <-- ADDED for logging

class SmsService {
  final Telephony _telephony = Telephony.instance;
  Function(String)? _onMoveReceived;

  Future<bool> isSupported() async {
    final supported = await _telephony.isPhoneAvailable ?? false;
    await AppLogger().log('SMS isSupported: $supported');  // <-- ADDED
    return supported;
  }

  Future<void> listenForMoves({required Function(String) onMoveReceived}) async {
    _onMoveReceived = onMoveReceived;
    
    final granted = await _telephony.requestSmsPermissions;
    await AppLogger().log('SMS permissions granted: $granted');  // <-- ADDED
    
    if (granted != true) {
      debugPrint('SMS permissions not granted');
      return;
    }

    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        final body = message.body ?? '';
        await AppLogger().log('SMS received: $body');  // <-- ADDED
        if (body.length >= 4 && body.contains(RegExp(r'^[a-h][1-8][a-h][1-8]'))) {
          final move = body.substring(0, 4);
          _onMoveReceived?.call(move);
          AppLogger().log('Parsed move: $move');  // <-- ADDED
        } else {
          AppLogger().log('SMS body did not contain a valid move');  // <-- ADDED
        }
      },
      listenInBackground: false,
    );
  }

  Future<void> sendMove({
    required String phoneNumber,
    required String sanMove,
    Function(bool)? onResult,
  }) async {
    if (phoneNumber.trim().isEmpty) {
      await AppLogger().log('SMS send failed: empty phone number');  // <-- ADDED
      onResult?.call(false);
      return;
    }
    try {
      await _telephony.sendSms(
        to: phoneNumber,
        message: sanMove,
      );
      await AppLogger().log('SMS sent to $phoneNumber: $sanMove');  // <-- ADDED
      onResult?.call(true);
    } catch (e) {
      await AppLogger().log('SMS send error to $phoneNumber: $e');  // <-- ADDED
      debugPrint('SMS send error: $e');
      onResult?.call(false);
    }
  }
}
