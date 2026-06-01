package com.nueng.mtd

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notifychannel = "com.nueng.mtd/notification"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notifychannel)
        val plugin = CustomNotificationPlugin(this)

        channel.setMethodCallHandler { call, result ->
            plugin.handleMethodCall(call, result)
        }
    }
}