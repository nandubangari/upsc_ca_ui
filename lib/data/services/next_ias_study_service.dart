import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';

class NextIASStudyService {
  /// Returns the static NextIAS quiz URL and articles for a specific date
  Future<DailyStudyData?> fetchByDate(String isoDate, {Function(String)? onStatusUpdate}) async {
    try {
      onStatusUpdate?.call('Fetching NextIAS articles for $isoDate...');
      final articles = await fetchArticlesByDate(isoDate);
      
      onStatusUpdate?.call('Fetching NextIAS quizzes for $isoDate...');
      final quizzes = await fetchQuizzesByDate(isoDate);
      
      return DailyStudyData(
        date: isoDate,
        items: articles,
        quizzes: quizzes,
      );
    } catch (e) {
      AppLogger.d("[NextIAS] Error fetching $isoDate: $e");
      return null;
    }
  }

  Future<List<ArticleModel>> fetchArticlesByDate(String isoDate) async {
    final dt = DateTime.parse(isoDate);
    final formattedDate = DateFormat('dd-MM-yyyy').format(dt);
    final url = "https://www.nextias.com/ca/current-affairs/$formattedDate";

    final html = await _getHtml(url);
    if (html == null) return [];

    return _parseArticles(html, isoDate);
  }

  Future<String?> _getHtml(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
          "Accept": "text/html",
        },
      );
      if (response.statusCode != 200) return null;
      return response.body;
    } catch (e) {
      return null;
    }
  }

  List<ArticleModel> _parseArticles(String html, String isoDate) {
    final document = parser.parse(html);
    final List<ArticleModel> results = [];

    /// 🧠 Extract page date
    final header = document.querySelector('h1');
    final pageDate = header?.text.trim() ?? "";

    /// 🔍 Core selector for articles
    final articles = document.querySelectorAll('article');

    for (final article in articles) {
      final linkElement = article.querySelector('h2 a');

      if (linkElement == null) continue;

      final title = linkElement.text.trim();
      final href = linkElement.attributes['href'];

      if (href == null || title.isEmpty) continue;

      results.add(
        ArticleModel(
          title: title,
          url: href.trim(),
          date: isoDate,
          source: 'nextias',
          subtitle: pageDate,
        ),
      );
    }

    return results;
  }

  Future<List<QuizModel>> fetchQuizzesByDate(String isoDate) async {
    final dt = DateTime.parse(isoDate);
    final formattedTitleDate = DateFormat('dd MMM yyyy').format(dt);

    return [
      QuizModel(
        source: 'nextias',
        title: 'Daily CA MCQs ($formattedTitleDate)',
        url: 'https://www.nextias.com/daily-mcq/daily-ca-mcqs',
        isCompleted: false,
      )
    ];
  }

  void dispose() {}
}


