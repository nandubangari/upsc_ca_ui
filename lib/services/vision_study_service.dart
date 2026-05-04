import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/study_item_model.dart';

class VisionStudyService {
  static const String _baseUrl = "https://visionias.in";

  /// Fetches articles for a specific date (YYYY-MM-DD)
  Future<DailyStudyData?> fetchByDate(String isoDate, {Function(String)? onStatusUpdate}) async {
    final url = Uri.parse("$_baseUrl/current-affairs/news-today/$isoDate");

    try {
      print('DEBUG: [Vision] Requesting URL: $url');
      onStatusUpdate?.call('Fetching VisionIAS for $isoDate...');
      
      final response = await http.get(
        url,
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
        },
      );

      if (response.statusCode != 200) {
        print('DEBUG: [Vision] No content for $isoDate. Status: ${response.statusCode}');
        return null;
      }

      final document = parser.parse(response.body);
      final List<StudyItem> items = [];

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

        print('DEBUG: [Vision] Extracted title: "$title" for URL: $href');

        final fullUrl = href.startsWith('http') ? href : '$_baseUrl$href';

        items.add(StudyItem(
          title: title,
          url: fullUrl,
          date: isoDate,
          subtitle: 'VisionIAS Daily Summary',
        ));
      }

      print('DEBUG: [Vision] Found ${items.length} articles for $isoDate');
      
      if (items.isEmpty) return null;

      return DailyStudyData(
        date: isoDate,
        items: items,
      );
    } catch (e) {
      print('DEBUG: [Vision] Error fetching $isoDate: $e');
      return null;
    }
  }
}
