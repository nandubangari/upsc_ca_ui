import '../models/article_content.dart';
import 'extractors/base_article_extractor.dart';
import 'extractors/vajiram_article_extractor.dart';
import 'extractors/vision_article_extractor.dart';
import 'extractors/next_ias_article_extractor.dart';
import 'extractors/insights_ias_article_extractor.dart';
import 'extractors/generic_article_extractor.dart';

class ArticleParserService {
  Future<ArticleContent> fetchAndParseArticle(String url) async {
    BaseArticleExtractor extractor;
    
    // Determine which extractor to use based on the URL
    if (url.contains('vajiramias.com')) {
      print('DEBUG: [Parser] Using VajiramArticleExtractor for: $url');
      extractor = VajiramArticleExtractor();
    } else if (url.contains('visionias.in')) {
      print('DEBUG: [Parser] Using VisionArticleExtractor for: $url');
      extractor = VisionArticleExtractor();
    } else if (url.contains('nextias.com')) {
      print('DEBUG: [Parser] Using NextIASArticleExtractor for: $url');
      extractor = NextIASArticleExtractor();
    } else if (url.contains('insightsonindia.com')) {
      print('DEBUG: [Parser] Using InsightsIASArticleExtractor for: $url');
      extractor = InsightsIASArticleExtractor();
    } else {
      print('DEBUG: [Parser] Using GenericArticleExtractor for: $url');
      extractor = GenericArticleExtractor();
    }
    
    try {
      return await extractor.fetchAndParse(url);
    } catch (e, stack) {
      print('ERROR: [Parser] Failed to extract article from $url');
      print('ERROR: $e');
      print('STACKTRACE: $stack');
      rethrow;
    }
  }
}
