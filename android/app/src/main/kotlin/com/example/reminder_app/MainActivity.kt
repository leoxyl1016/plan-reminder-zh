package com.company.reminderapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register MethodChannels for SMS and notification listener
        SmsReceiver.registerWithEngine(flutterEngine)
        ScheduleNotificationListener.registerWithEngine(flutterEngine)
    }
}
