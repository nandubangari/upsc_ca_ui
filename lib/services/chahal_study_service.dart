import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import '../models/study_item_model.dart';
import '../models/dashboard_data.dart';
import '../core/utils/date_formatter.dart';

class ChahalStudyService {
  static const String _baseUrl = "https://chahalacademy.com/current-affairs-quiz/04-may-2026";
  
  // A known ID to start the search from. This should be updated periodically or detected.
  // For now, let's assume 2024 as per the user's provided logic snippet.
  static const int _defaultKnownId = 2024;

  Future<List<DailyStudyData>> fetch({
    required int year,
    required int month,
    DateTime? startDate,
    Function(String)? onStatusUpdate,
  }) async {
    final Map<String, List<QuizDetail>> groupedQuizzes = {};
    
    // We'll use the smart extraction logic provided by the user
    // However, the base fetch() in our system is month-based.
    // For Chahal (ID based), we'll crawl backwards and forwards from the known ID.
    
    int knownId = _defaultKnownId; 
    DateTime targetStartDate = startDate ?? DateTime(year, month, 1);
    
    onStatusUpdate?.call('Starting Chahal Academy extraction...');
    
    /// 🔽 STEP 1: BACKWARD SEARCH
    int id = knownId;
    while (true) {
      onStatusUpdate?.call('Checking Chahal ID $id (Backward)...');
      final data = await _fetchAndParse(id);
      if (data == null) break;

      DateTime quizDate = data['dateObj'] as DateTime;
      if (quizDate.isBefore(targetStartDate)) {
        debugPrint("DEBUG: [Chahal] Reached before target start date ($targetStartDate) -> STOP backward");
        break;
      }

      final String isoDate = DateFormatter.toIso(quizDate);
      // Only include if it matches the requested year/month
      if (quizDate.year == year && quizDate.month == month) {
        debugPrint("✅ [Chahal] Found Quiz: $isoDate | Title: ${data['title']} | Link: ${data['url']}");
        groupedQuizzes.putIfAbsent(isoDate, () => []).add(QuizDetail(
          source: 'Chahal Academy',
          title: data['title'],
          url: data['url'],
          isCompleted: false,
        ));
      }

      id--; 
    }

    /// 🔼 STEP 2: FORWARD SEARCH
    id = knownId + 1;
    while (true) {
      onStatusUpdate?.call('Checking Chahal ID $id (Forward)...');
      final urlStr = "$_baseUrl/$id";
      final response = await http.get(Uri.parse(urlStr));

      // Stop if redirected to homepage
      if (response.request?.url.toString() == "https://chahalacademy.com/") {
        debugPrint("DEBUG: [Chahal] Redirected to homepage -> STOP forward at ID $id");
        break;
      }

      final data = _parseHtml(response.body, id);
      if (data == null) break;

      DateTime quizDate = data['dateObj'] as DateTime;
      final String isoDate = DateFormatter.toIso(quizDate);
      
      if (quizDate.year == year && quizDate.month == month) {
        debugPrint("✅ [Chahal] Found Quiz (Forward): $isoDate | Title: ${data['title']} | Link: ${data['url']}");
        groupedQuizzes.putIfAbsent(isoDate, () => []).add(QuizDetail(
          source: 'Chahal Academy',
          title: data['title'],
          url: data['url'],
          isCompleted: false,
        ));
      }

      id++; 
    }

    return groupedQuizzes.entries.map((e) => DailyStudyData(
      date: e.key,
      items: [],
      quizzes: e.value,
    )).toList();
  }

  Future<Map<String, dynamic>?> _fetchAndParse(int id) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/$id"));
      if (response.statusCode != 200 || response.body.contains("Page not found")) {
        return null;
      }
      return _parseHtml(response.body, id);
    } catch (e) {
      debugPrint("DEBUG: [Chahal] Error fetching ID $id: $e");
      return null;
    }
  }

  Map<String, dynamic>? _parseHtml(String html, int id) {
    final document = parser.parse(html);
    final titleEl = document.querySelector('.page-title h1');
    if (titleEl == null) return null;

    final title = titleEl.text.trim();
    final dateStr = _extractDateFromTitle(title);
    if (dateStr == null) return null;

    final dateObj = _parseDate(dateStr);
    if (dateObj == null) return null;

    return {
      "id": id,
      "url": "$_baseUrl/$id",
      "title": title,
      "date": dateStr,
      "dateObj": dateObj,
    };
  }

  String? _extractDateFromTitle(String text) {
    // Look for date like 01-May-26 or 01-May-2026
    final match = RegExp(r'\d{2}-[A-Za-z]{3}-\d{2,4}').firstMatch(text);
    return match?.group(0);
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length < 3) return null;

      int day = int.parse(parts[0]);
      String monthStr = parts[1].toLowerCase().substring(0, 3);
      int yearPart = int.parse(parts[2]);
      int year = yearPart < 100 ? 2000 + yearPart : yearPart;

      const months = {
        "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
        "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12,
      };

      if (!months.containsKey(monthStr)) return null;
      return DateTime(year, months[monthStr]!, day);
    } catch (e) {
      return null;
    }
  }
}
