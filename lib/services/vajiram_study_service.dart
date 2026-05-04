import 'dart:convert';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import '../models/study_item_model.dart';
import '../core/utils/date_formatter.dart';

class VajiramStudyService {
  static const String _baseUrl = "https://vajiramias.com";
  static const _headers = {
    'x-requested-with': 'XMLHttpRequest',
    'user-agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
  };

  Future<List<DailyStudyData>> fetch({
    required int year,
    required int month,
    int? maxPages, // Changed to optional
    Function(String)? onStatusUpdate,
  }) async {
    final Map<String, List<StudyItem>> grouped = {};
    final Set<String> seenIds = {};

    final fYear = year.toString();

    // Avoid duplicate fetches if padded and unpadded month are the same (e.g., month 10)
    final monthFormats = {
      month.toString().padLeft(2, '0'), // Padded: e.g., "04"
      month.toString(),                 // Unpadded: e.g., "4"
    }.toList();

    final endpoints = [
      'current-affairs-partial',
      'articles-partial',
    ];

    for (var endpoint in endpoints) {
      for (var fMonth in monthFormats) {
        int page = 1;
        while (true) {
          if (maxPages != null && page > maxPages) break;

          final url = Uri.parse(
            '$_baseUrl/$endpoint/$fYear/$fMonth/?page=$page',
          );

          try {
            print('DEBUG: [Vajiram] Requesting URL: $url');
            onStatusUpdate?.call('Fetching $endpoint ($fMonth) Page $page...');
            final res = await http.get(url, headers: _headers);
            
            if (res.statusCode != 200) {
              print('DEBUG: [Vajiram] Failed to fetch $url. Status: ${res.statusCode}');
              break;
            }

            String htmlContent;
            try {
              final Map<String, dynamic> jsonResponse = jsonDecode(res.body);
              htmlContent = jsonResponse['content'] ?? '';
            } catch (e) {
              htmlContent = res.body;
            }

            if (htmlContent.isEmpty || htmlContent.trim().isEmpty) {
              print('DEBUG: [Vajiram] Empty content for $url');
              break;
            }

            final parsed = _parse(htmlContent, seenIds, endpoint);
            print('DEBUG: [Vajiram] Found ${parsed.values.fold(0, (sum, list) => sum + list.length)} items across ${parsed.keys.length} dates on $url');
            
            if (parsed.isEmpty) {
              // We only break if we can't find ANY items on page 1. 
              // This handles cases where a middle page might be broken or empty.
              if (page == 1) {
                print('DEBUG: [Vajiram] No items on page 1 for $url. Stopping endpoint/month.');
                break;
              }
              // If we are past page 1 and find nothing, we assume we reached the end.
              break;
            }

            parsed.forEach((date, items) {
              grouped.putIfAbsent(date, () => []).addAll(items);
            });

            await Future.delayed(const Duration(milliseconds: 100));
            page++;
          } catch (e) {
            onStatusUpdate?.call('Error on $endpoint page $page: $e');
            break;
          }
        }
      }
    }

    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return keys.map((k) => DailyStudyData(
      date: k, // Store raw ISO date for syncing logic, will format in UI
      items: grouped[k]!,
    )).toList();
  }

  Map<String, List<StudyItem>> _parse(String html, Set<String> seenIds, String endpoint) {
    final Map<String, List<StudyItem>> results = {};
    final document = parser.parse(html);
    
    // Support multiple container classes found across different endpoints
    final containers = document.querySelectorAll('.feed_item_box');
    
    if (containers.isEmpty) {
      print('DEBUG: [Vajiram] No containers found for $endpoint using standard selectors.');
    }

    for (var container in containers) {
      print('DEBUG: [Vajiram] Container HTML: ${container.innerHtml}');
      // Look for links that match either current affairs or general articles
      final link = container.querySelector(
          'a[href^="/current-affairs/"], '
              'a[href^="/article/"], '
              'a[href^="https://vajiramias.com/current-affairs/"], '
              'a[href^="https://vajiramias.com/article/"]'
      );
      if (link == null) {
        // Log skip for debugging if we find a container but no relevant link
        final allLinks = container.querySelectorAll('a').map((e) => e.attributes['href']).toList();
        print('DEBUG: [Vajiram] Skipping container in $endpoint. No matching link found. Available links: $allLinks');
        continue;
      }

      // 1. Find Title
      final title = container.querySelector('.feed_item_title')?.text.trim() ??
                    container.querySelector('.article_listing_title')?.text.trim() ??
                    link.querySelector('h2')?.text.trim() ??
                    link.text.trim();
      
      // 2. Find Subtitle
      String? subtitle = container.querySelector('.feed_item_subtitle')?.text.trim() ??
                      container.querySelector('.article_listing_subtitle')?.text.trim() ??
                      container.querySelector('.subtitle')?.text.trim();
      
      if (subtitle?.toLowerCase() == "null" || subtitle?.isEmpty == true) {
        subtitle = null;
      }
      
      final url = link.attributes['href'];
      if (title.isEmpty || url == null) continue;

      final fullUrl = url.startsWith('http') ? url : '$_baseUrl$url';
      
      if (seenIds.contains(fullUrl)) {
        // Already processed this URL in another endpoint/page
        continue;
      }

      // 3. Find Date
      String? dateStr;
      // Search specifically in date-labeled containers first, then general text
      final dateElement = container.querySelector('.feed_item_date, .article_listing_date, .date, small');
      if (dateElement != null) {
        dateStr = dateElement.text.trim();
      } 
      
      // If direct element check failed or returned something non-date-like, try regex
      if (dateStr == null || !dateStr.contains(RegExp(r'\d{4}'))) {
        // Support "May 31, 2024" OR "31 May 2024" OR "25 Apr 2026"
        final dateMatch = RegExp(r'(\d{1,2}\s+[A-Z][a-z]+\s+\d{4})|([A-Z][a-z]+\s+\d{1,2},?\s+\d{4})').firstMatch(container.text);
        if (dateMatch != null) {
          dateStr = dateMatch.group(0);
        }
      }

      if (dateStr != null) {
        final date = _parseVajiramDate(dateStr);
        if (date != null) {
          seenIds.add(fullUrl);
          results.putIfAbsent(date, () => []).add(StudyItem(
            title: title,
            subtitle: subtitle,
            url: fullUrl,
            date: date,
          ));
          print('DEBUG: [Vajiram] Parsed from $endpoint - Title: "$title", Date: "$date", Link: "$fullUrl"');
        } else {
          print('DEBUG: [Vajiram] Failed to parse date string: "$dateStr" in $endpoint');
        }
      } else {
        print('DEBUG: [Vajiram] No date found for article: "$title" in $endpoint');
      }
    }
    return results;
  }

  String? _parseVajiramDate(String dateStr) {
    try {
      // Clean up: "May 31, 2024" or "31 May 2024"
      final cleanStr = dateStr.replaceAll(',', '').replaceAll(RegExp(r'\s+'), ' ').trim();
      final parts = cleanStr.split(' ');
      if (parts.length < 3) return null;
      
      final monthMap = {
        'January': 1, 'Jan': 1,
        'February': 2, 'Feb': 2,
        'March': 3, 'Mar': 3,
        'April': 4, 'Apr': 4,
        'May': 5,
        'June': 6, 'Jun': 6,
        'July': 7, 'Jul': 7,
        'August': 8, 'Aug': 8,
        'September': 9, 'Sep': 9,
        'October': 10, 'Oct': 10,
        'November': 11, 'Nov': 11,
        'December': 12, 'Dec': 12
      };
      
      int? day;
      int? month;
      int? year;

      // Try to identify which part is which
      for (var part in parts) {
        if (monthMap.containsKey(part)) {
          month = monthMap[part];
        } else if (RegExp(r'^\d{4}$').hasMatch(part)) {
          year = int.tryParse(part);
        } else if (RegExp(r'^\d{1,2}$').hasMatch(part)) {
          day = int.tryParse(part);
        }
      }
      
      if (month == null || day == null || year == null) return null;
      
      final dt = DateTime(year, month, day);
      return DateFormatter.toIso(dt);
    } catch (e) {
      return null;
    }
  }


}
