import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
void backgrounMessageHandler(SmsMessage message) async {
  debugPrint('[SMS] Background message received: ${message.body}');
  // Infrastructure for future notification integration
}

class SmsService {
  final Telephony _telephony = Telephony.instance;
  Function(String)? _onMoveReceived;

  Future<bool> isSupported() async => true;

  Future<void> listenForMoves({required Function(String) onMoveReceived}) async {
    _onMoveReceived = onMoveReceived;
    final granted = await _telephony.requestSmsPermissions;
    if (granted != true) {
      debugPrint('[SMS] Permissions not granted');
      return;
    }
    
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final body = message.body ?? '';
        debugPrint('[SMS] Received: $body');
        
        // Robust UCI move detection
        final uciRegex = RegExp(r'([a-h][1-8][a-h][1-8])');
        final match = uciRegex.firstMatch(body.toLowerCase());
        
        if (match != null) {
          final uci = match.group(1);
          if (uci != null) {
            debugPrint('[SMS] Valid UCI found: $uci');
            _onMoveReceived?.call(uci);
          }
        } else {
          debugPrint('[SMS] No valid UCI move found in message');
        }
      },
      onBackgroundMessage: backgrounMessageHandler,
      listenInBackground: true,
    );
  }

  Future<void> sendMove({
    required String phoneNumber,
    required String uciMove,
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
      debugPrint('[SMS] Sending move $uciMove to $phoneNumber');
      await _telephony.sendSms(
        to: phoneNumber, 
        message: uciMove,
        statusListener: (status) {
          final ok = status == SendStatus.SENT;
          debugPrint('[SMS] Send status: $status');
          onResult?.call(ok);
        }
      );
    } catch (e) {
      debugPrint('[SMS] Error: $e');
      onResult?.call(false);
    }
  }
}
