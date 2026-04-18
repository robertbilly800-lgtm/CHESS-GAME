import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;
  Function(String)? _onMoveReceived;

  // The isPhoneAvailable getter does not exist in another_telephony.
  // We simply assume the device can send SMS; permissions will be requested.
  Future<bool> isSupported() async {
    await AppLogger().log('SMS service initialized');
    return true;
  }

  Future<void> listenForMoves({required Function(String) onMoveReceived}) async {
    _onMoveReceived = onMoveReceived;

    final granted = await _telephony.requestSmsPermissions;
    await AppLogger().log('SMS permissions granted: $granted');

    if (granted != true) {
      debugPrint('SMS permissions not granted');
      return;
    }

    // The callback MUST be marked 'async' to use 'await' inside.
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final body = message.body ?? '';
        await AppLogger().log('SMS received: $body');
        if (body.length >= 4 && body.contains(RegExp(r'^[a-h][1-8][a-h][1-8]'))) {
          final move = body.substring(0, 4);
          _onMoveReceived?.call(move);
          await AppLogger().log('Parsed move: $move');
        } else {
          await AppLogger().log('SMS body did not contain a valid move');
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
      await AppLogger().log('SMS send failed: empty phone number');
      onResult?.call(false);
      return;
    }
    try {
      await _telephony.sendSms(
        to: phoneNumber,
        message: sanMove,
      );
      await AppLogger().log('SMS sent to $phoneNumber: $sanMove');
      onResult?.call(true);
    } catch (e) {
      await AppLogger().log('SMS send error to $phoneNumber: $e');
      debugPrint('SMS send error: $e');
      onResult?.call(false);
    }
  }
}
