import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:upsc_ca_ui/shared/models/article_content.dart';
import 'package:upsc_ca_ui/data/parsers/base_article_extractor.dart';
import 'package:upsc_ca_ui/data/parsers/vajiram/vajiram_article_extractor.dart';
import 'package:upsc_ca_ui/data/parsers/visionias/vision_article_extractor.dart';
import 'package:upsc_ca_ui/data/parsers/nextias/next_ias_article_extractor.dart';
import 'package:upsc_ca_ui/data/parsers/insightsias/insights_ias_article_extractor.dart';
import 'package:upsc_ca_ui/data/parsers/generic/generic_article_extractor.dart';

class ArticleParser {
  /// Fetches and parses an article from the given URL.
  /// Uses a background isolate to prevent UI stutters during heavy HTML parsing.
  Future<List<ArticleContent>> fetchAndParseArticle(String url) async {
    try {
      return await compute(_extractInBackground, url);
    } catch (e, stack) {
      AppLogger.e('[Parser] Failed to extract article from $url', e, stack);
      rethrow;
    }
  }

  /// Entry point for the background isolate.
  static Future<List<ArticleContent>> _extractInBackground(String url) async {
    final BaseArticleExtractor extractor;
    
    // Determine which extractor to use based on the URL
    if (url.contains('vajiramias.com')) {
      extractor = VajiramArticleExtractor();
    } else if (url.contains('visionias.in')) {
      extractor = VisionArticleExtractor();
    } else if (url.contains('nextias.com')) {
      extractor = NextIASArticleExtractor();
    } else if (url.contains('insightsonindia.com')) {
      extractor = InsightsIASArticleExtractor();
    } else {
      extractor = GenericArticleExtractor();
    }
    
    return extractor.fetchAndParse(url);
  }
}


