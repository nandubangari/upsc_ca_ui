import '../../models/article_content.dart';

abstract class BaseArticleExtractor {
  Future<List<ArticleContent>> fetchAndParse(String url);
}
