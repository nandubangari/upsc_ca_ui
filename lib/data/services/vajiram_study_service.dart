import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';

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
      AppLogger.d("[Vajiram] verifySession() pinging: $url");
      
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
      AppLogger.d("[Vajiram] verifySession() status: ${response.statusCode}");
      // Log headers to see if session is being set/recognized
      AppLogger.d("[Vajiram] verifySession() headers: ${response.headers}");
      
      bool isSuccess = response.statusCode == 200 && !response.body.contains("accounts/login");
      
      if (!isSuccess) {
        AppLogger.d("[Vajiram] verifySession() initial check failed. Body snippet: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}");
      }

      // Retry once if we get a 200 but it still shows login (might be a race condition with cookie propagation)
      if (!isSuccess && response.statusCode == 200 && response.body.contains("accounts/login")) {
        AppLogger.d("[Vajiram] verifySession() found login redirect. Retrying in 1500ms...");
        await Future.delayed(const Duration(milliseconds: 1500));
        response = await performRequest();
        isSuccess = response.statusCode == 200 && !response.body.contains("accounts/login");
        AppLogger.d("[Vajiram] verifySession() retry status: ${response.statusCode}, isSuccess: $isSuccess");
      }

      if (!isSuccess) {
        AppLogger.d("[Vajiram] verifySession() failed. Body length: ${response.body.length}");
      }
      return isSuccess;
    } catch (e) {
      AppLogger.d("[Vajiram] verifySession() error: $e");
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
    AppLogger.d("[Vajiram] fetch() called with cookies: ${cookies != null ? "YES (length: ${cookies.length})" : "NO"}");
    final Map<String, List<ArticleModel>> groupedArticles = {};
    final groupedQuizzes = <String, List<QuizModel>>{};
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
            AppLogger.d("[Vajiram] Requesting URL: $url");
            onStatusUpdate?.call('Fetching $endpoint ($fm) Page $page...');
            final res = await http.get(url, headers: {
              ..._headers,
              'x-requested-with': 'XMLHttpRequest',
              if (cookies != null) ...{'Cookie': cookies},
            });
            
            if (res.statusCode != 200) {
              AppLogger.d("[Vajiram] Failed to fetch $url. Status: ${res.statusCode}");
              break;
            }

            // Offload BOTH jsonDecode and parsing to background isolate
            final parsed = await compute(_decodeAndParseStatic, {
              'jsonBody': res.body,
              'seenIds': seenIds.toList(),
            });
            
            if (parsed.isEmpty && page == 1) break;
            if (parsed.isEmpty) break;

            AppLogger.d("[Vajiram] Page $page of $endpoint returned ${parsed.length} daily groups");

            parsed.forEach((date, items) {
              groupedArticles.putIfAbsent(date, () => []).addAll(items);
              for (var item in items) {
                seenIds.add(item.url!);
              }
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
      AppLogger.d("[Vajiram] Starting quiz fetch for $year/$month...");
      final quizData = await fetchQuizzes(year: year, month: month, cookies: cookies);
      AppLogger.d("[Vajiram] Quiz data received: ${quizData.length} daily entries");
      for (var daily in quizData) {
        AppLogger.d("[Vajiram] Daily entry for ${daily.date}: ${daily.quizzes.length} quizzes");
        groupedQuizzes[daily.date] = daily.quizzes;
      }
    } catch (e) {
      AppLogger.d("[Vajiram] Error fetching quizzes: $e");
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
    AppLogger.d("[Vajiram] Fetching quizzes from: $url");
    AppLogger.d("[Vajiram] Using cookies: ${cookies != null ? "YES (length: ${cookies.length})" : "NO"}");

    final response = await http.get(
      url,
      headers: {
        ..._headers,
        if (cookies != null && cookies.isNotEmpty) 'Cookie': cookies,
      },
    );

    AppLogger.d("[Vajiram] Quiz response status: ${response.statusCode}");
    if (cookies != null && cookies.isNotEmpty) {
      AppLogger.d("[Vajiram] Sent cookies: ${cookies.substring(0, cookies.length > 30 ? 30 : cookies.length)}...");
    }
    // Log a small part of body for structural verification if it's not a 200
    if (response.statusCode != 200) {
      AppLogger.d("[Vajiram] Non-200 Body snippet: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}");
    }

    if (response.statusCode == 500 || response.body.contains("accounts/login")) {
      AppLogger.d("[Vajiram] Login required detected in response body or status code");
      throw Exception("LOGIN_REQUIRED");
    }

    return await compute(parseQuizzesFromHtmlStatic, response.body);
  }

  static List<DailyStudyData> parseQuizzesFromHtmlStatic(String html) {
    final document = parser.parse(html);

    var cards = document.querySelectorAll('.mcq_card');
    if (cards.isEmpty) {
      cards = document.querySelectorAll('a[href*="/daily-mcq/"][href*="test"]');
    }
    
    final Map<String, List<QuizModel>> results = {};

    for (var card in cards) {
      final titleEl = card.querySelector('.mcq_card_title') ?? card;

      final title = titleEl.text.trim();
      final relativeLink = card.attributes['href'] ?? '';
      final fullLink = relativeLink.startsWith('http') ? relativeLink : "https://vajiramias.com$relativeLink";

      // Extract date from title e.g. "04 May 2026 MCQs Test"
      final dateMatch = RegExp(r'(\d{1,2}\s+[A-Z][a-z]+\s+\d{4})').firstMatch(title);
      if (dateMatch != null) {
        final dateStr = dateMatch.group(0)!;
        final isoDate = _parseVajiramDateStatic(dateStr);
        if (isoDate != null) {
          results.putIfAbsent(isoDate, () => []).add(QuizModel(
            source: 'Vajiram',
            title: title,
            url: fullLink,
            isCompleted: false,
          ));
        }
      }
    }

    return results.entries.map((e) => DailyStudyData(date: e.key, items: [], quizzes: e.value)).toList();
  }

  static Map<String, List<ArticleModel>> _decodeAndParseStatic(Map<String, dynamic> params) {
    final String jsonBody = params['jsonBody'];
    final List<String> seenIdsList = params['seenIds'];
    
    String html;
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(jsonBody);
      html = jsonResponse['content'] ?? '';
    } catch (e) {
      html = jsonBody;
    }

    if (html.isEmpty) return {};

    return _parseStatic({
      'html': html,
      'seenIds': seenIdsList,
    });
  }

  static Map<String, List<ArticleModel>> _parseStatic(Map<String, dynamic> params) {
    final String html = params['html'];
    final List<String> seenIdsList = params['seenIds'];
    final Set<String> seenIds = Set.from(seenIdsList);

    final Map<String, List<ArticleModel>> results = {};
    final document = parser.parse(html);
    
    final containers = document.querySelectorAll('.feed_item_box');
    
    for (var container in containers) {
      final link = container.querySelector(
          'a[href^="/current-affairs/"], '
              'a[href^="/article/"], '
              'a[href^="https://vajiramias.com/current-affairs/"], '
              'a[href^="https://vajiramias.com/article/"]'
      );
      if (link == null) continue;

      final title = container.querySelector('.feed_item_title')?.text.trim() ??
                    container.querySelector('.article_listing_title')?.text.trim() ??
                    link.querySelector('h2')?.text.trim() ??
                    link.text.trim();
      
      String? subtitle = container.querySelector('.feed_item_subtitle')?.text.trim() ??
                      container.querySelector('.article_listing_subtitle')?.text.trim() ??
                      container.querySelector('.subtitle')?.text.trim();
      
      if (subtitle?.toLowerCase() == "null" || subtitle?.isEmpty == true) {
        subtitle = null;
      }
      
      final urlString = link.attributes['href'];
      if (title.isEmpty || urlString == null) continue;

      final fullUrl = urlString.startsWith('http') ? urlString : 'https://vajiramias.com$urlString';
      
      if (seenIds.contains(fullUrl)) continue;

      String? dateStr;
      final dateElement = container.querySelector('.feed_item_date, .article_listing_date, .date, small');
      if (dateElement != null) {
        dateStr = dateElement.text.trim();
      } 
      
      if (dateStr == null || !dateStr.contains(RegExp(r'\d{4}'))) {
        final dateMatch = RegExp(r'(\d{1,2}\s+[A-Z][a-z]+\s+\d{4})|([A-Z][a-z]+\s+\d{1,2},?\s+\d{4})').firstMatch(container.text);
        if (dateMatch != null) {
          dateStr = dateMatch.group(0);
        }
      }

      if (dateStr != null) {
        final date = _parseVajiramDateStatic(dateStr);
        if (date != null) {
          seenIds.add(fullUrl);
          results.putIfAbsent(date, () => []).add(ArticleModel(
            title: title,
            subtitle: subtitle,
            url: fullUrl,
            date: date,
            source: 'Vajiram & Ravi',
          ));
        }
      }
    }
    return results;
  }

  static String? _parseVajiramDateStatic(String dateStr) {
    try {
      final cleanStr = dateStr.replaceAll(',', '').replaceAll(RegExp(r'\s+'), ' ').trim();
      final parts = cleanStr.split(' ');
      if (parts.length < 3) return null;
      
      final monthMap = {
        'January': 1, 'Jan': 1, 'February': 2, 'Feb': 2, 'March': 3, 'Mar': 3,
        'April': 4, 'Apr': 4, 'May': 5, 'June': 6, 'Jun': 6, 'July': 7, 'Jul': 7,
        'August': 8, 'Aug': 8, 'September': 9, 'Sep': 9, 'October': 10, 'Oct': 10,
        'November': 11, 'Nov': 11, 'December': 12, 'Dec': 12
      };
      
      int? day, month, year;

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
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return null;
    }
  }
}


