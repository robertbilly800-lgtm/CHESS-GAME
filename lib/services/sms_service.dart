import 'package:flutter/foundation.dart';
import 'package:custom_advanced_sms/custom_advanced_sms.dart';

class SmsService {
  static SmsService? _instance;
  factory SmsService() => _instance ??= SmsService._();
  SmsService._();

  final Telephony _tel = Telephony.instance;
  static const String _prefix = 'CHESS:';
  bool _listening = false;

  Future<bool> isSupported() async {
    try {
      return await _tel.isSmsCapable ?? false;
    } catch (e) {
      debugPrint('[SMS] isSupported error: $e');
      return false;
    }
  }

  Future<void> sendMove({
    required String phoneNumber,
    required String sanMove,
    void Function(bool)? onResult,
  }) async {
    try {
      final clean = phoneNumber.trim();
      if (clean.isEmpty) { onResult?.call(false); return; }
      _tel.sendSms(
        to: clean,
        message: '$_prefix$sanMove',
        statusListener: (SendStatus status) {
          onResult?.call(status == SendStatus.SENT);
        },
      );
    } catch (e) {
      debugPrint('[SMS] sendMove error: $e');
      onResult?.call(false);
    }
  }

  void listenForMoves({required void Function(String) onMoveReceived}) {
    if (_listening) return;
    try {
      _tel.listenIncomingSms(
        onNewMessage: (SmsMessage msg) {
          final body = msg.body;
          if (body == null || !body.startsWith(_prefix)) return;
          final move = body.replaceFirst(_prefix, '').trim();
          if (move.isNotEmpty) onMoveReceived(move);
        },
        listenInBackground: false, // true crashes on some devices without background isolate
      );
      _listening = true;
      debugPrint('[SMS] listening');
    } catch (e) {
      debugPrint('[SMS] listenForMoves error: $e');
    }
  }

  void stopListening() => _listening = false;
}
