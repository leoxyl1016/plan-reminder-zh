package com.company.reminderapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "SmsReceiver"
        var channel: MethodChannel? = null
        const val CHANNEL_NAME = "com.company.reminderapp/sms"

        fun registerWithEngine(flutterEngine: FlutterEngine) {
            channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (sms in messages) {
                val body = sms.displayMessageBody ?: ""
                val sender = sms.displayOriginatingAddress ?: "Unknown"
                if (body.isNotBlank()) {
                    Log.d(TAG, "SMS from $sender: ${body.take(60)}...")
                    channel?.invokeMethod("onSmsReceived", mapOf(
                        "body" to body,
                        "sender" to sender,
                        "timestamp" to System.currentTimeMillis()
                    ))
                }
            }
        }
    }
}
