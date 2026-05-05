import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import '../../models/article_content.dart';
import 'base_article_extractor.dart';

class VisionArticleExtractor implements BaseArticleExtractor {
  @override
  Future<ArticleContent> fetchAndParse(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch article: ${response.statusCode}');
    }

    final document = parser.parse(response.body);
    
    final container = document.querySelector('#article-content');
    if (container == null) {
      print('DEBUG: [Vision Extractor] #article-content not found, using generic fallback');
      return _parseGeneric(document, url);
    }

    final title = document.querySelector('h1')?.text.trim() ?? 
                  document.querySelector('title')?.text.trim() ??
                  'VisionIAS Article';

    final List<ContentBlock> blocks = [];

    for (final node in container.children) {
      final block = _parseNode(node);
      if (block != null) blocks.add(block);
    }

    return ArticleContent(
      title: title,
      content: blocks,
      source: SourceInfo(text: 'VisionIAS', url: url),
    );
  }

  /// 🔥 NODE PARSER
  ContentBlock? _parseNode(dom.Element element) {
    switch (element.localName) {
      case 'p':
        return ContentBlock(type: ContentBlockType.p, data: _parseInline(element));

      case 'h2':
        return ContentBlock(type: ContentBlockType.h2, data: element.text.trim());
      
      case 'h3':
        return ContentBlock(type: ContentBlockType.h3, data: element.text.trim());

      case 'ul':
        return ContentBlock(type: ContentBlockType.ul, data: _parseList(element));

      case 'figure':
        return _parseTable(element);

      case 'table':
        return _parseTableDirect(element);

      default:
        return null;
    }
  }

  /// 🧠 INLINE PARSER (BOLD + COLOR)
  List<InlineSpanData> _parseInline(dom.Element element) {
    final spans = <InlineSpanData>[];

    for (final node in element.nodes) {
      if (node is dom.Element) {
        // Skip nested lists as they are handled separately in _parseListItem
        if (node.localName == 'ul' || node.localName == 'ol') continue;

        final isBold = node.localName == 'strong' || node.localName == 'b';

        /// Extract color if present
        String? color;
        final style = node.attributes['style'];
        if (style != null && style.contains('color')) {
          final match = RegExp(r'color:\s*([^;]+)').firstMatch(style);
          color = match?.group(1);
        }

        spans.add(
          InlineSpanData(
            node.text,
            isBold: isBold,
            color: color,
          ),
        );
      } else {
        final text = node.text?.trim() ?? '';
        if (text.isNotEmpty) {
          spans.add(InlineSpanData(text));
        }
      }
    }

    return spans;
  }

  /// 🔥 LIST PARSER
  List<ListItem> _parseList(dom.Element ul) {
    final items = <ListItem>[];

    for (final li in ul.children.where((e) => e.localName == 'li')) {
      items.add(_parseListItem(li));
    }

    return items;
  }

  ListItem _parseListItem(dom.Element li) {
    final spans = _parseInline(li);

    // Replace unsupported :scope selector with direct child traversal
    dom.Element? nested;
    for (final child in li.children) {
      if (child.localName == 'ul' || child.localName == 'ol') {
        nested = child;
        break;
      }
    }

    return ListItem(
      spans: spans,
      children: nested != null ? _parseList(nested) : [],
    );
  }

  /// 🔥 TABLE PARSER (from figure)
  ContentBlock? _parseTable(dom.Element figure) {
    final table = figure.querySelector('table');
    if (table == null) return null;
    return _parseTableDirect(table);
  }

  ContentBlock? _parseTableDirect(dom.Element table) {
    final rows = <List<String>>[];

    for (final tr in table.querySelectorAll('tr')) {
      final cells = tr.querySelectorAll('td, th')
          .map((c) => c.text.trim())
          .toList();

      if (cells.isNotEmpty) rows.add(cells);
    }

    if (rows.isEmpty) return null;
    return ContentBlock(type: ContentBlockType.table, data: rows);
  }

  Future<ArticleContent> _parseGeneric(dom.Document document, String url) async {
    final title = document.querySelector('h1')?.text.trim() ?? 'Untitled';
    return ArticleContent(
      title: title,
      content: [
        ContentBlock(
          type: ContentBlockType.p, 
          data: [InlineSpanData('Content could not be parsed specifically.')]
        )
      ],
      source: SourceInfo(text: 'VisionIAS', url: url),
    );
  }
}
