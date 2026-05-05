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

enum ContentBlockType { p, ul, h2, h3, table, callout, image }

class InlineSpanData {
  final String text;
  final bool isBold;
  final String? color;

  InlineSpanData(this.text, {this.isBold = false, this.color});
}

class ContentBlock {
  final ContentBlockType type;
  final dynamic data; 
  // data:
  // - List<InlineSpanData> for p
  // - String for h2, h3, image
  // - List<ListItem> for ul
  // - List<List<String>> for table
  // - List<ContentBlock> for callout

  ContentBlock({required this.type, required this.data});
}

class ListItem {
  final List<InlineSpanData> spans;
  final List<ListItem> children;

  ListItem({required this.spans, this.children = const []});
}

class SourceInfo {
  final String text;
  final String url;

  SourceInfo({required this.text, required this.url});
}
