package com.nandu.upsc_ca_ui

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.webkit.CookieManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.nandu.upsc_ca_ui/cookies"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getCookies") {
                val url: String? = call.argument("url")
                if (url != null) {
                    val cookies = CookieManager.getInstance().getCookie(url)
                    result.success(cookies)
                } else {
                    result.error("INVALID_URL", "URL is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
