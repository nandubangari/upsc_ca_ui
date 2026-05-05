import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:intl/intl.dart';
import '../models/study_item_model.dart';
import '../models/dashboard_data.dart';

class VisionStudyService {
  static const String _baseUrl = "https://visionias.in";

  /// Fetches articles and quizzes for a specific date (YYYY-MM-DD)
  Future<DailyStudyData?> fetchByDate(String isoDate, {Function(String)? onStatusUpdate}) async {
    try {
      onStatusUpdate?.call('Fetching VisionIAS for $isoDate...');
      
      final articles = await _fetchArticles(isoDate);
      final quizzes = await fetchQuizzesByDate(isoDate);

      if (articles.isEmpty && quizzes.isEmpty) {
        print('DEBUG: [Vision] No content (articles or quizzes) for $isoDate');
        return null;
      }

      print('DEBUG: [Vision] Found ${articles.length} articles and ${quizzes.length} quizzes for $isoDate');

      return DailyStudyData(
        date: isoDate,
        items: articles,
        quizzes: quizzes,
      );
    } catch (e) {
      print('DEBUG: [Vision] Error fetching $isoDate: $e');
      return null;
    }
  }

  Future<List<StudyItem>> _fetchArticles(String isoDate) async {
    final url = Uri.parse("$_baseUrl/current-affairs/news-today/$isoDate");
    final List<StudyItem> items = [];

    try {
      print('DEBUG: [Vision] Requesting Articles URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
        },
      );

      if (response.statusCode != 200) {
        print('DEBUG: [Vision] Articles not found for $isoDate. Status: ${response.statusCode}');
        return [];
      }

      final document = parser.parse(response.body);

      // Based on provided structure: #table-of-content a[href]
      final elements = document.querySelectorAll('#table-of-content a[href]');

      for (var element in elements) {
        // Target the specific span provided by the user: <span class="flex-1 leading-snug">
        final titleSpan = element.querySelector('span.flex-1.leading-snug') ?? 
                           element.querySelector('span');
        
        String title = titleSpan?.text.trim() ?? element.text.trim();
        
        // Clean up title (remove leading numbers/bullets if any)
        title = title.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        
        final href = element.attributes['href']?.trim() ?? '';

        if (title.isEmpty || href.isEmpty) continue;

        print('DEBUG: [Vision] Extracted article title: "$title" for URL: $href');

        final fullUrl = href.startsWith('http') ? href : '$_baseUrl$href';

        items.add(StudyItem(
          title: title,
          url: fullUrl,
          date: isoDate,
          subtitle: 'VisionIAS Daily Summary',
        ));
      }
    } catch (e) {
      print('DEBUG: [Vision] Error fetching articles for $isoDate: $e');
    }
    return items;
  }

  Future<List<QuizDetail>> fetchQuizzesByDate(String isoDate) async {
    final dt = DateTime.parse(isoDate);
    final formattedTitleDate = DateFormat('MMMM dd, yyyy').format(dt);

    final url = "https://visionias.in/current-affairs/upsc-daily-current-affairs-quiz?date=$isoDate&filter=daily&status=all";
    
    return [
      QuizDetail(
        source: 'VisionIAS',
        title: 'Daily Prelim Quiz ($formattedTitleDate)',
        url: url,
        isCompleted: false,
      )
    ];
  }
}
