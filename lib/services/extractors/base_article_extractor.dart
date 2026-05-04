import '../../models/article_content.dart';

abstract class BaseArticleExtractor {
  Future<ArticleContent> fetchAndParse(String url);
}
