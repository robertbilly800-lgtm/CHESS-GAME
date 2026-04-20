package com.chessmate.pro.game

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (sms in messages) {
                val body = sms.displayMessageBody
                val from = sms.displayOriginatingAddress
                Log.d("SmsReceiver", "Received move from $from: $body")
                
                // Note: The logic to push this to Flutter depends on the 
                // plugin architecture being used (e.g. EventChannel or method channel).
                // hardened logic will be in the SmsService.dart layer.
            }
        }
    }
}
