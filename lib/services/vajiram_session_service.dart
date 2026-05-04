import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_item_model.dart';

class VajiramSessionService {
  static const String _cookieKey = 'vajiram_cookies';
  static const String _scrapedQuizzesKey = 'vajiram_scraped_quizzes';
  static const MethodChannel _channel = MethodChannel('com.nandu.upsc_ca_ui/cookies');

  /// Fetches cookies directly from the native Android/iOS system.
  /// This captures HttpOnly cookies that JavaScript cannot see.
  Future<String?> getNativeCookies(String url) async {
    try {
      final String? cookies = await _channel.invokeMethod('getCookies', {'url': url});
      print('DEBUG: [VajiramSessionService] Native cookies retrieved (length: ${cookies?.length ?? 0})');
      return cookies;
    } catch (e) {
      print('DEBUG: [VajiramSessionService] Native cookie error: $e');
      return null;
    }
  }

  /// Saves the captured cookies to shared preferences.
  Future<void> saveCookies(String cookies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookieKey, cookies);
    print('DEBUG: [VajiramSessionService] Saved cookies to SharedPreferences (length: ${cookies.length})');
  }

  /// Retrieves the saved cookies.
  Future<String?> getCookies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieKey);
  }

  /// Clears the saved cookies.
  Future<void> clearCookies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
  }

  /// Checks if cookies are present.
  Future<bool> hasSession() async {
    final cookies = await getCookies();
    return cookies != null && cookies.isNotEmpty;
  }

  /// Saves scraped quiz data.
  Future<void> saveScrapedQuizzes(List<DailyStudyData> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = data.map((e) => e.toJson()).toList();
    await prefs.setString(_scrapedQuizzesKey, jsonEncode(jsonList));
    print('DEBUG: [VajiramSessionService] Saved ${data.length} scraped quiz entries');
  }

  /// Retrieves scraped quiz data.
  Future<List<DailyStudyData>> getScrapedQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_scrapedQuizzesKey);
    if (jsonStr == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => DailyStudyData.fromJson(e)).toList();
    } catch (e) {
      print('DEBUG: [VajiramSessionService] Error decoding scraped quizzes: $e');
      return [];
    }
  }
}
