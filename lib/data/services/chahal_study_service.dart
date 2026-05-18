import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';
import 'package:upsc_ca_ui/core/utils/date_formatter.dart';

class ChahalStudyService {
  static const String _baseUrl = "https://chahalacademy.com/daily-current-affairs-quiz";
  
  Future<List<DailyStudyData>> fetch({
    required int year,
    required int month,
    DateTime? startDate,
    Function(String)? onStatusUpdate,
  }) async {
    final Map<String, List<QuizModel>> groupedQuizzes = {};
    
    onStatusUpdate?.call('Fetching Chahal Academy quiz list...');
    
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        },
      );

      if (response.statusCode != 200) {
        AppLogger.e("[Chahal] Failed to fetch quiz list. Status: ${response.statusCode}");
        return [];
      }

      final document = parser.parse(response.body);
      final links = document.querySelectorAll('a');
      
      int foundCount = 0;

      for (var link in links) {
        final title = link.text.trim();
        final href = link.attributes['href'];

        if (href == null || title.isEmpty) continue;
        if (!title.toLowerCase().contains("daily current affairs quiz with answers")) continue;

        final dateObj = _parseDateFromTitle(title);
        if (dateObj == null) continue;

        // Filter by requested year and month
        if (dateObj.year != year || dateObj.month != month) continue;

        // Optional: Filter by startDate
        if (startDate != null && dateObj.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
          continue;
        }

        final String isoDate = DateFormatter.toIso(dateObj);
        final fullUrl = href.startsWith('http') ? href : "https://chahalacademy.com${href.startsWith('/') ? '' : '/'}$href";

        groupedQuizzes.putIfAbsent(isoDate, () => []).add(QuizModel(
          source: 'Chahal Academy',
          title: title,
          url: fullUrl,
          isCompleted: false,
        ));
        foundCount++;
      }

      AppLogger.d("✅ [Chahal] Found $foundCount quizzes for $year-$month");

    } catch (e) {
      AppLogger.e("[Chahal] Error fetching quizzes", e);
    }

    return groupedQuizzes.entries.map((e) => DailyStudyData(
      date: e.key,
      items: [],
      quizzes: e.value,
    )).toList();
  }

  DateTime? _parseDateFromTitle(String text) {
    // Look for date like "18 May 2026" or "18-May-2026"
    final match = RegExp(r'(\d{1,2})[-\s]([A-Za-z]{3,})[-\s](\d{4})').firstMatch(text);
    if (match == null) return null;

    try {
      final day = int.parse(match.group(1)!);
      final monthStr = match.group(2)!.toLowerCase().substring(0, 3);
      final year = int.parse(match.group(3)!);

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
