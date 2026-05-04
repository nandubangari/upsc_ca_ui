class ArticleContent {
  final String title;
  final String? date;
  final String? subtitle;
  final String? imageUrl;
  final List<ContentBlock> content;
  final SourceInfo? source;

  ArticleContent({
    required this.title,
    this.date,
    this.subtitle,
    this.imageUrl,
    required this.content,
    this.source,
  });
}

enum ContentBlockType { p, ul, h3, table, callout, image }

class ContentBlock {
  final ContentBlockType type;
  final dynamic data; // String for p/h3/image, List<ListItem> for ul, List<List<String>> for table, List<ContentBlock> for callout

  ContentBlock({required this.type, required this.data});
}

class ListItem {
  final String text;
  final List<ListItem> children;

  ListItem({required this.text, this.children = const []});
}

class SourceInfo {
  final String text;
  final String url;

  SourceInfo({required this.text, required this.url});
}
