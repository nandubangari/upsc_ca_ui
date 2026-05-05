import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/study_item_model.dart';
import '../core/utils/insights_ias_url_builder.dart';

class InsightsIASStudyService {
  /// Fetches articles for a specific date
  Future<DailyStudyData?> fetchByDate(DateTime date, {Function(String)? onStatusUpdate}) async {
    final primaryUrl = InsightsIASUrlBuilder.buildUrl(date);
    final dateStr = "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";

    // Alternative URL pattern often used for DCA
    final monthName = _monthName(date.month).toLowerCase();
    final dayStr = date.day.toString();
    final altUrl = "https://www.insightsonindia.com/${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/insights-daily-current-affairs-pib-summary-$dayStr-$monthName-${date.year}/";

    final urlsToTry = [primaryUrl, altUrl];

    for (var url in urlsToTry) {
      try {
        print('DEBUG: [InsightsIAS] Requesting URL: $url');
        onStatusUpdate?.call('Fetching InsightsIAS for $dateStr...');
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            "User-Agent": "Mozilla/5.0",
          },
        );

        if (response.statusCode != 200) {
          print('DEBUG: [InsightsIAS] Failed to fetch $url. Status: ${response.statusCode}');
          continue; // Try next URL
        }

        final document = parser.parse(response.body);
        final List<StudyItem> items = [];

        // Try multiple selectors for blocks
        final blocks = document.querySelectorAll('.ca-topic-block').isNotEmpty 
            ? document.querySelectorAll('.ca-topic-block')
            : document.querySelectorAll('.entry-content h3'); // Fallback to h3 headings

        if (blocks.isEmpty) {
          print('DEBUG: [InsightsIAS] No blocks found with .ca-topic-block or h3 in $url');
          continue;
        }

        for (var block in blocks) {
          String? title;
          String? link;
          String subtitle = "";

          if (block.classes.contains('ca-topic-block')) {
            final anchor = block.querySelector('.topic-title a') ?? block.querySelector('a');
            
            // Remove the arrow icon span if it exists within the anchor
            anchor?.querySelector('.ca-topic-title-arrow')?.remove();
            
            title = _clean(anchor?.text ?? "");
            link = anchor?.attributes['href'] ?? "";

            final firstP = block.querySelector('.article-body-column p') ?? block.querySelector('p');
            if (firstP != null) subtitle = _clean(firstP.text);
          } else if (block.localName == 'h3') {
            // It's an h3 from entry-content fallback
            final anchor = block.querySelector('a') ?? block;
            
            // Remove the arrow icon span if it exists
            anchor.querySelector('.ca-topic-title-arrow')?.remove();

            title = _clean(anchor.text);
            link = anchor.attributes['href'] ?? "";
            
            // Try to find subtitle in next sibling p
            var next = block.nextElementSibling;
            while (next != null && next.localName != 'p' && next.localName != 'h3') {
              next = next.nextElementSibling;
            }
            if (next != null && next.localName == 'p') {
              subtitle = _clean(next.text);
            }
          }

          if (title == null || title.isEmpty || link == null || link.isEmpty) continue;

          items.add(StudyItem(
            title: title,
            url: link,
            date: dateStr,
            subtitle: subtitle.isNotEmpty ? subtitle : 'InsightsIAS Daily Current Affairs',
          ));
        }

        if (items.isNotEmpty) {
          print('DEBUG: [InsightsIAS] Found ${items.length} articles for $dateStr at $url');
          final isoDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

          return DailyStudyData(
            date: isoDate,
            items: items,
          );
        }
      } catch (e) {
        print('DEBUG: [InsightsIAS] Error fetching $url: $e');
      }
    }

    return null;
  }

  static String _monthName(int month) {
    const months = [
      "january", "february", "march", "april",
      "may", "june", "july", "august",
      "september", "october", "november", "december"
    ];
    return months[month - 1];
  }

  static String _clean(String text) {
    // 1. Basic whitespace cleanup
    String cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('\n', ' ')
        .trim();
        
    // 2. Remove emojis and common non-ASCII icons at the end/anywhere in titles
    // This regex covers common emoji ranges and specific characters often used as icons
    return cleaned.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}\u{1F191}-\u{1F251}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{3030}\u{2B50}\u{2B55}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{3297}\u{3299}\u{303D}\u{00A9}\u{00AE}\u{2122}\u{231A}-\u{231B}\u{2328}\u{23CF}\u{23E9}-\u{23F3}\u{23F8}-\u{23FA}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2604}\u{260E}\u{2611}\u{2614}-\u{2615}\u{2618}\u{261D}\u{2620}\u{2622}-\u{2623}\u{2626}\u{262A}\u{262E}-\u{262F}\u{2638}-\u{263A}\u{2640}\u{2642}\u{2648}-\u{2653}\u{265F}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267E}-\u{267F}\u{2692}-\u{2697}\u{2699}\u{269B}-\u{269C}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26B0}-\u{26B1}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26C8}\u{26CE}-\u{26CF}\u{26D1}\u{26D3}-\u{26D4}\u{26E9}-\u{26EA}\u{26F0}-\u{26F5}\u{26F7}-\u{26FA}\u{26FD}]', unicode: true), '').trim();
  }
}
