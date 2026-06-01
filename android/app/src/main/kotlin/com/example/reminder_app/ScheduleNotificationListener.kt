package com.company.reminderapp

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class ScheduleNotificationListener : NotificationListenerService() {

    companion object {
        const val TAG = "NotifListener"
        var channel: MethodChannel? = null
        const val CHANNEL_NAME = "com.company.reminderapp/notifications"

        // Package names to monitor (can be extended)
        val MONITORED_PACKAGES = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",       // WhatsApp Business
            "com.google.android.gm",   // Gmail
            "com.google.android.apps.messaging", // Google Messages
            "com.android.mms",         // AOSP SMS
            "com.tencent.mm",          // WeChat (微信)
            "com.tencent.wework",      // WeCom (企业微信)
            "com.alibaba.android.rimet", // DingTalk (钉钉)
            "com.eg.android.AlipayGphone", // Alipay (支付宝通知)
        )

        fun registerWithEngine(flutterEngine: FlutterEngine) {
            channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Notification listener service created")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(TAG, "Notification listener service destroyed")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        if (packageName !in MONITORED_PACKAGES) return

        val extras = sbn.notification.extras
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val subText = extras.getString(Notification.EXTRA_SUB_TEXT) ?: ""

        val fullContent = listOf(title, text, bigText, subText)
            .filter { it.isNotBlank() }
            .joinToString(" ")

        if (fullContent.isBlank()) return

        val sourceName = when (packageName) {
            "com.whatsapp", "com.whatsapp.w4b" -> "WhatsApp"
            "com.google.android.gm" -> "Gmail"
            "com.google.android.apps.messaging" -> "短信"
            "com.android.mms" -> "短信"
            "com.tencent.mm" -> "微信"
            "com.tencent.wework" -> "企业微信"
            "com.alibaba.android.rimet" -> "钉钉"
            "com.eg.android.AlipayGphone" -> "支付宝"
            else -> packageName.substringAfterLast(".")
        }

        Log.d(TAG, "Notification from $sourceName: ${fullContent.take(80)}...")

        channel?.invokeMethod("onNotificationReceived", mapOf(
            "body" to fullContent,
            "source" to sourceName,
            "packageName" to packageName,
            "timestamp" to System.currentTimeMillis()
        ))
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // Not needed for our use case
    }
}
