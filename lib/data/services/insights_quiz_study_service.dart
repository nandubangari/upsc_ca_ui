import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:intl/intl.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';
import 'package:upsc_ca_ui/core/utils/date_formatter.dart';

class InsightsQuizItem {
  final String title;
  final String url;
  final DateTime? date;
  final String type; // "QUED", "CURRENT_AFFAIRS", "STATIC", or "INSTA_DART"
  final String? subject; // Optional subject for static quizzes

  InsightsQuizItem({
    required this.title,
    required this.url,
    required this.date,
    required this.type,
    this.subject,
  });

  @override
  String toString() => "$date -> $title ($type${subject != null ? ': $subject' : ''})";
}

class InsightsQuizStudyService {
  static const String quedUrl =
      "https://www.insightsonindia.com/qued-daily-editorial-questions/";

  static const String caQuizUrl =
      "https://www.insightsonindia.com/current-affairs-quiz/";

  static const String staticQuizUrl =
      "https://www.insightsonindia.com/upsc-daily-static-quiz/";

  static const String instaDartUrl =
      "https://www.insightsonindia.com/insta-dart/";

  /// Fetches all quizzes from QUED, CA, Static, and Insta-DART listing pages and filters them by the requested month.
  Future<List<DailyStudyData>> fetchForMonth(int year, int month, {DateTime? startDate}) async {
    final Map<String, List<QuizModel>> groupedQuizzes = {};
    
    try {
      final quedItems = await _fetch(quedUrl, "QUED");
      final caItems = await _fetch(caQuizUrl, "CURRENT_AFFAIRS");
      final staticItems = await _fetch(staticQuizUrl, "STATIC");
      final instaDartItems = await _fetch(instaDartUrl, "INSTA_DART");
      
      final allItems = [...quedItems, ...caItems, ...staticItems, ...instaDartItems];
      
      final now = DateTime.now();

      AppLogger.d("[InsightsQuiz] Total quizzes fetched: ${allItems.length} (QUED: ${quedItems.length}, CA: ${caItems.length}, STATIC: ${staticItems.length}, DART: ${instaDartItems.length})");
      int matchedMonthCount = 0;

      for (var item in allItems) {
        if (item.date == null) continue;

        // Skip future dates
        if (item.date!.isAfter(now)) continue;

        // Skip dates before start date if provided
        if (startDate != null && item.date!.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
          continue;
        }

        // Only include if it matches the requested year/month
        if (item.date!.year == year && item.date!.month == month) {
          matchedMonthCount++;
          final isoDate = DateFormatter.toIso(item.date!);
          
          String sourceName;
          switch (item.type) {
            case "QUED":
              sourceName = "InsightsIAS QUED";
              break;
            case "STATIC":
              sourceName = "InsightsIAS Static (${item.subject ?? 'General'})";
              break;
            case "INSTA_DART":
              sourceName = "InsightsIAS Insta-DART";
              break;
            case "CURRENT_AFFAIRS":
            default:
              sourceName = "InsightsIAS Quiz";
          }
          
          groupedQuizzes.putIfAbsent(isoDate, () => []).add(QuizModel(
            source: sourceName,
            title: item.title,
            url: item.url,
            isCompleted: false,
          ));
        }
      }
      AppLogger.d("[InsightsQuiz] Matched $matchedMonthCount items for month $year/$month");
    } catch (e) {
      AppLogger.d("[InsightsQuiz] Error fetching for month $year/$month: $e");
    }

    return groupedQuizzes.entries.map((e) => DailyStudyData(
      date: e.key,
      items: [],
      quizzes: e.value,
    )).toList();
  }

  Future<List<InsightsQuizItem>> _fetch(String url, String type) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html",
      },
    );

    if (response.statusCode != 200) {
      AppLogger.d("[InsightsQuiz] Failed to fetch $type listing. Status: ${response.statusCode}");
      return [];
    }

    return await compute(_parseListingStatic, {
      'html': response.body,
      'type': type,
    });
  }

  static List<InsightsQuizItem> _parseListingStatic(Map<String, dynamic> params) {
    final String html = params['html'];
    final String type = params['type'];
    
    final document = parser.parse(html);
    final List<InsightsQuizItem> results = [];

    /// ✅ Core selector (same for all pages)
    final links = document.querySelectorAll('ul.lcp_catlist li a');

    for (final link in links) {
      final title = link.text.trim();
      final href = link.attributes['href'];

      if (href == null || title.isEmpty) continue;

      // Skip compilation links
      if (title.toLowerCase().contains("compilation")) continue;

      final date = _extractDateStatic(title);
      final subject = type == "STATIC" ? _extractSubjectStatic(title) : null;

      results.add(
        InsightsQuizItem(
          title: title,
          url: href,
          date: date,
          type: type,
          subject: subject,
        ),
      );
    }

    return results;
  }

  /// 🧠 Extract subject
  /// Example: "Polity", "Environment"
  static String? _extractSubjectStatic(String title) {
    // Regex for: "UPSC Static Quiz – Polity : 5 May 2026"
    final regex = RegExp(r'Quiz\s+[–-]\s+(.*?)\s+:');
    final match = regex.firstMatch(title);

    return match?.group(1)?.trim();
  }

  static DateTime? _extractDateStatic(String title) {
    // Standard format for InsightsIAS
    // Works for: "UPSC Editorials Quiz : 5 May 2026", "Current Affairs Quiz, 18 February 2023", etc.
    final regex = RegExp(r'(\d{1,2})[,\s]+(\w+)[,\s]+(\d{4})');
    final match = regex.firstMatch(title);

    if (match == null) return null;

    final day = match.group(1);
    final month = match.group(2);
    final year = match.group(3);
    
    final cleaned = "$day $month $year";

    try {
      return DateFormat("d MMMM yyyy").parse(cleaned);
    } catch (_) {
      try {
         // Try with abbreviated month if full name fails
         return DateFormat("d MMM yyyy").parse(cleaned);
      } catch (__) {
         return null;
      }
    }
  }
}
