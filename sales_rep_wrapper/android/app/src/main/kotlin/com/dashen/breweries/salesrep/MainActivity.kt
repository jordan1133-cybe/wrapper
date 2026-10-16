package com.dashen.breweries.salesrep

import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.dashen.sales_rep/location_settings"
        ).setMethodCallHandler { call, result ->
            if (call.method != "openLocationSettings") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                result.success(true)
            } catch (_: ActivityNotFoundException) {
                result.success(false)
            } catch (_: Exception) {
                result.success(false)
            }
        }
    }
}
