import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/study_item_model.dart';

class NextIASStudyService {
  static const String baseUrl = "https://www.nextias.com";

  /// Fetches articles for a specific date (DD-MM-YYYY)
  Future<DailyStudyData?> fetchByDate(String dateStr, {Function(String)? onStatusUpdate}) async {
    // Expected format dd-mm-yyyy for URL
    final url = "$baseUrl/ca/current-affairs/$dateStr";

    try {
      print('DEBUG: [NextIAS] Requesting URL: $url');
      onStatusUpdate?.call('Fetching NextIAS for $dateStr...');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
        },
      );

      if (response.statusCode != 200) {
        print('DEBUG: [NextIAS] No content for $dateStr. Status: ${response.statusCode}');
        return null;
      }

      final document = parser.parse(response.body);
      final List<StudyItem> items = [];

      final articleNodes = document.querySelectorAll('article');

      for (var article in articleNodes) {
        // 1. Title + Link
        final anchor = article.querySelector('h2 a');
        final title = anchor?.text.trim() ?? "";
        String href = anchor?.attributes['href']?.trim() ?? "";

        if (title.isEmpty || href.isEmpty) continue;

        final fullUrl = href.startsWith('http') ? href : '$baseUrl$href';

        // 2. Extract Preview Points as Subtitle
        final List<String> previewPoints = [];
        final liTags = article.querySelectorAll('li');

        for (var li in liTags) {
          final text = li.text.replaceAll(RegExp(r'\s+'), ' ').trim();
          if (text.isNotEmpty) {
            previewPoints.add(text);
          }
        }

        items.add(StudyItem(
          title: title,
          url: fullUrl,
          date: dateStr,
          subtitle: previewPoints.isNotEmpty ? previewPoints.join(' • ') : 'NextIAS Daily Current Affairs',
        ));
      }

      print('DEBUG: [NextIAS] Found ${items.length} articles for $dateStr');
      
      if (items.isEmpty) return null;

      // Convert dateStr (DD-MM-YYYY) to ISO (YYYY-MM-DD) for consistency in the model
      final parts = dateStr.split('-');
      final isoDate = "${parts[2]}-${parts[1]}-${parts[0]}";

      return DailyStudyData(
        date: isoDate,
        items: items,
      );
    } catch (e) {
      print('DEBUG: [NextIAS] Error fetching $dateStr: $e');
      return null;
    }
  }
}
