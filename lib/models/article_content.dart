class ArticleContent {
  final String title;
  final String? date;
  final String? subtitle;
  final String? imageUrl;
  final List<ContentBlock> content;
  final SourceInfo? source;
  final List<String>? tags;
  final List<String>? summary;
  final List<String>? sources;

  ArticleContent({
    required this.title,
    this.date,
    this.subtitle,
    this.imageUrl,
    required this.content,
    this.source,
    this.tags,
    this.summary,
    this.sources,
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
  // - String for h2, h3
  // - List<ListItem> for ul
  // - List<List<String>> for table
  // - List<ContentBlock> for callout
  // - ImageData for image

  ContentBlock({required this.type, required this.data});
}

class ImageData {
  final String url;
  final double? width;
  final double? height;

  ImageData({required this.url, this.width, this.height});
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
