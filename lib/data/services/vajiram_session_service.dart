import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VajiramSessionService {
  static const String _cookieKey = 'vajiram_cookies';
  static const MethodChannel _channel = MethodChannel('com.nandu.upsc_ca_ui/cookies');

  /// Fetches cookies directly from the native Android/iOS system.
  /// This captures HttpOnly cookies that JavaScript cannot see.
  Future<String?> getNativeCookies(String url) async {
    try {
      final String? cookies = await _channel.invokeMethod('getCookies', {'url': url});
      AppLogger.d("[VajiramSessionService] Native cookies retrieved (length: ${cookies?.length ?? 0})");
      return cookies;
    } catch (e) {
      AppLogger.d("[VajiramSessionService] Native cookie error: $e");
      return null;
    }
  }

  /// Saves the captured cookies to shared preferences.
  Future<void> saveCookies(String cookies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookieKey, cookies);
    AppLogger.d("[VajiramSessionService] Saved cookies to SharedPreferences (length: ${cookies.length})");
  }

  /// Retrieves the saved cookies.
  Future<String?> getCookies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieKey);
  }

}








