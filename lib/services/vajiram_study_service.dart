import 'dart:convert';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import '../models/study_item_model.dart';
import '../models/dashboard_data.dart';
import '../core/utils/date_formatter.dart';

class VajiramStudyService {
  static const String _baseUrl = "https://vajiramias.com";
  static const _headers = {
    'user-agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  };

  /// Verifies if the current session cookies are valid by attempting to fetch the MCQ page.
  Future<bool> verifySession(String cookies) async {
    try {
      // Use a more general URL that might be more resilient
      final url = Uri.parse("$_baseUrl/daily-mcq/");
      print('DEBUG: [Vajiram] verifySession() pinging: $url');
      
      Future<http.Response> performRequest() => http.get(
        url,
        headers: {
          'user-agent': _headers['user-agent']!,
          'Cookie': cookies,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Upgrade-Insecure-Requests': '1',
        },
      );

      var response = await performRequest();
      print('DEBUG: [Vajiram] verifySession() status: ${response.statusCode}');
      // Log headers to see if session is being set/recognized
      print('DEBUG: [Vajiram] verifySession() headers: ${response.headers}');
      
      bool isSuccess = response.statusCode == 200 && !response.body.contains("accounts/login");
      
      if (!isSuccess) {
        print('DEBUG: [Vajiram] verifySession() initial check failed. Body snippet: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
      }

      // Retry once if we get a 200 but it still shows login (might be a race condition with cookie propagation)
      if (!isSuccess && response.statusCode == 200 && response.body.contains("accounts/login")) {
        print('DEBUG: [Vajiram] verifySession() found login redirect. Retrying in 1500ms...');
        await Future.delayed(const Duration(milliseconds: 1500));
        response = await performRequest();
        isSuccess = response.statusCode == 200 && !response.body.contains("accounts/login");
        print('DEBUG: [Vajiram] verifySession() retry status: ${response.statusCode}, isSuccess: $isSuccess');
      }

      if (!isSuccess) {
        print('DEBUG: [Vajiram] verifySession() failed. Body length: ${response.body.length}');
      }
      return isSuccess;
    } catch (e) {
      print('DEBUG: [Vajiram] verifySession() error: $e');
      return false;
    }
  }

  Future<List<DailyStudyData>> fetch({
    required int year,
    required int month,
    int? maxPages, 
    String? cookies, // Added cookies
    Function(String)? onStatusUpdate,
  }) async {
    print('DEBUG: [Vajiram] fetch() called with cookies: ${cookies != null ? "YES (length: ${cookies.length})" : "NO"}');
    final Map<String, List<StudyItem>> groupedArticles = {};
    final groupedQuizzes = <String, List<QuizDetail>>{};
    final Set<String> seenIds = {};

    final fYear = year.toString();

    // 1. Fetch Articles
    final monthFormats = {
      month.toString().padLeft(2, '0'),
      month.toString(),
    }.toList();

    final endpoints = [
      'current-affairs-partial',
      'articles-partial',
    ];

    for (var endpoint in endpoints) {
      for (var fm in monthFormats) {
        int page = 1;
        while (true) {
          if (maxPages != null && page > maxPages) break;
          final url = Uri.parse('$_baseUrl/$endpoint/$fYear/$fm/?page=$page');

          try {
            print('DEBUG: [Vajiram] Requesting URL: $url');
            onStatusUpdate?.call('Fetching $endpoint ($fm) Page $page...');
            final res = await http.get(url, headers: {
              ..._headers,
              'x-requested-with': 'XMLHttpRequest',
              if (cookies != null) 'Cookie': cookies,
            });
            
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

            if (htmlContent.isEmpty) break;

            final parsed = _parse(htmlContent, seenIds, endpoint);
            if (parsed.isEmpty && page == 1) break;
            if (parsed.isEmpty) break;

            parsed.forEach((date, items) {
              groupedArticles.putIfAbsent(date, () => []).addAll(items);
            });

            await Future.delayed(const Duration(milliseconds: 100));
            page++;
          } catch (e) {
            break;
          }
        }
      }
    }

    // 2. Fetch Quizzes
    try {
      print('DEBUG: [Vajiram] Starting quiz fetch for $year/$month...');
      final quizData = await fetchQuizzes(year: year, month: month, cookies: cookies);
      print('DEBUG: [Vajiram] Quiz data received: ${quizData.length} daily entries');
      for (var daily in quizData) {
        print('DEBUG: [Vajiram] Daily entry for ${daily.date}: ${daily.quizzes.length} quizzes');
        groupedQuizzes[daily.date] = daily.quizzes;
      }
    } catch (e) {
      print('DEBUG: [Vajiram] Error fetching quizzes: $e');
      if (e.toString().contains("LOGIN_REQUIRED")) {
        rethrow; // Pass up to sync service/provider
      }
    }

    final allDates = {...groupedArticles.keys, ...groupedQuizzes.keys}.toList()..sort((a, b) => b.compareTo(a));

    return allDates.map((d) => DailyStudyData(
      date: d,
      items: groupedArticles[d] ?? [],
      quizzes: groupedQuizzes[d] ?? [],
    )).toList();
  }

  Future<List<DailyStudyData>> fetchQuizzes({
    required int year,
    required int month,
    String? cookies,
  }) async {
    final url = Uri.parse("$_baseUrl/daily-mcq/$year/$month/");
    print('DEBUG: [Vajiram] Fetching quizzes from: $url');
    print('DEBUG: [Vajiram] Using cookies: ${cookies != null ? "YES (length: ${cookies.length})" : "NO"}');

    final response = await http.get(
      url,
      headers: {
        ..._headers,
        if (cookies != null && cookies.isNotEmpty) 'Cookie': cookies,
      },
    );

    print('DEBUG: [Vajiram] Quiz response status: ${response.statusCode}');
    if (cookies != null && cookies.isNotEmpty) {
      print('DEBUG: [Vajiram] Sent cookies: ${cookies.substring(0, cookies.length > 30 ? 30 : cookies.length)}...');
    }
    // Log a small part of body for structural verification if it's not a 200
    if (response.statusCode != 200) {
      print('DEBUG: [Vajiram] Non-200 Body snippet: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
    }

    if (response.statusCode == 500 || response.body.contains("accounts/login")) {
      print('DEBUG: [Vajiram] Login required detected in response body or status code');
      throw Exception("LOGIN_REQUIRED");
    }

    return parseQuizzesFromHtml(response.body);
  }

  List<DailyStudyData> parseQuizzesFromHtml(String html) {
    final document = parser.parse(html);

    var cards = document.querySelectorAll('.mcq_card');
    if (cards.isEmpty) {
      print('DEBUG: [Vajiram] .mcq_card not found, trying fallback selectors...');
      cards = document.querySelectorAll('a[href*="/daily-mcq/"][href*="test"]');
    }
    
    print('DEBUG: [Vajiram] Found ${cards.length} potential quiz elements for parsing');
    final Map<String, List<QuizDetail>> results = {};

    for (var card in cards) {
      final titleEl = card.querySelector('.mcq_card_title') ?? card;

      final title = titleEl.text.trim();
      final relativeLink = card.attributes['href'] ?? '';
      final fullLink = relativeLink.startsWith('http') ? relativeLink : "$_baseUrl$relativeLink";

      // Extract date from title e.g. "04 May 2026 MCQs Test"
      final dateMatch = RegExp(r'(\d{1,2}\s+[A-Z][a-z]+\s+\d{4})').firstMatch(title);
      if (dateMatch != null) {
        final dateStr = dateMatch.group(0)!;
        final isoDate = _parseVajiramDate(dateStr);
        if (isoDate != null) {
          print("✅ [Vajiram] Found Quiz: $isoDate | Title: $title | Link: $fullLink");
          results.putIfAbsent(isoDate, () => []).add(QuizDetail(
            source: 'Vajiram',
            title: title,
            url: fullLink,
            isCompleted: false,
          ));
        }
      }
    }

    print('DEBUG: [Vajiram] Final quiz parsing results: ${results.length} dates processed');
    return results.entries.map((e) => DailyStudyData(date: e.key, items: [], quizzes: e.value)).toList();
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
