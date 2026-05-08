import 'package:upsc_ca_ui/shared/models/article_content.dart';

abstract class BaseArticleExtractor {
  Future<List<ArticleContent>> fetchAndParse(String url);
}





