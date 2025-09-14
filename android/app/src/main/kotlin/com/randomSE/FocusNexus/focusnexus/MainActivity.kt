package com.randomSE.FocusNexus.focusnexus

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val CHANNEL = "flutter_native_timezone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocalTimezone" -> {
                    result.success(TimeZone.getDefault().id)
                }
                "openNotificationSettings" -> {
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                        putExtra(Settings.EXTRA_APP_PACKAGE, applicationContext.packageName)
                    }
                    startActivity(intent)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
