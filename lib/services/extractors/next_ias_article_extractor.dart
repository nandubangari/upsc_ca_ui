import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import '../../models/article_content.dart';
import 'base_article_extractor.dart';

class NextIASArticleExtractor implements BaseArticleExtractor {
  bool _stopParsing = false;

  @override
  Future<ArticleContent> fetchAndParse(String url) async {
    _stopParsing = false;
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
    
    // Target common NextIAS article containers - .entry-content is high priority for NextIAS
    final container = document.querySelector('.entry-content') ?? 
                      document.querySelector('div.article-content') ?? 
                      document.querySelector('div.post-content') ??
                      document.querySelector('article');

    if (container == null) {
      print('DEBUG: [NextIAS Extractor] Main content container not found, using generic parser');
      return _parseGeneric(document, url);
    }

    // 🔴 CLEANUP
    container.querySelectorAll('script, style, .social-share, .related-posts').forEach((e) => e.remove());

    // 1. Title
    final title = document.querySelector('h1')?.text.trim() ?? 
                  document.querySelector('.page-title')?.text.trim() ??
                  'NextIAS Article';

    // 2. Content Blocks
    final contentBlocks = <ContentBlock>[];
    
    // Iterate through children to preserve order
    for (var node in container.nodes) {
      if (_stopParsing) break;
      _parseNode(node, contentBlocks);
    }

    return ArticleContent(
      title: title,
      content: contentBlocks,
      source: SourceInfo(text: 'NextIAS', url: url),
    );
  }

  void _parseNode(dom.Node node, List<ContentBlock> blocks) {
    if (_stopParsing) return;

    if (node is! dom.Element) {
      final text = node.text?.trim() ?? '';
      if (text.isNotEmpty && text.length > 5) {
        if (text.toLowerCase().startsWith('source')) {
          _stopParsing = true;
          return;
        }
        blocks.add(ContentBlock(type: ContentBlockType.p, data: [InlineSpanData(_cleanText(text))]));
      }
      return;
    }

    final element = node;
    final tagName = element.localName;

    // Handle Paragraphs and Source
    if (tagName == 'p') {
      final text = _cleanText(element.text);
      if (text.toLowerCase().startsWith('source')) {
        _stopParsing = true;
        return;
      }
      if (text.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.p, data: [InlineSpanData(text)]));
      }
    } 
    // Handle Images (wp-block-image style)
    else if (tagName == 'div' && element.classes.contains('wp-block-image')) {
      final img = element.querySelector('img');
      final src = img?.attributes['src'] ?? "";
      if (src.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.image, data: src));
      }
    }
    // Handle Lists
    else if (tagName == 'ul' || tagName == 'ol') {
      final listItems = _parseList(element);
      if (listItems.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.ul, data: listItems));
      }
    } 
    // Handle Headings
    else if (tagName == 'h1' || tagName == 'h2' || tagName == 'h3' || tagName == 'h4') {
      final text = _cleanText(element.text);
      if (text.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.h3, data: text));
      }
    } 
    // Handle Layout / Containers
    else if (tagName == 'div' || tagName == 'section' || tagName == 'figure') {
      // Check if it's a simple image figure
      if (tagName == 'figure' && element.querySelector('img') != null) {
         final src = element.querySelector('img')?.attributes['src'] ?? "";
         if (src.isNotEmpty) {
           blocks.add(ContentBlock(type: ContentBlockType.image, data: src));
           return;
         }
      }

      final table = element.querySelector('table');
      if (table != null) {
        _parseTable(table, blocks);
      } else {
        for (var child in element.nodes) {
          if (_stopParsing) break;
          _parseNode(child, blocks);
        }
      }
    } 
    else if (tagName == 'table') {
      _parseTable(element, blocks);
    }
    else if (tagName == 'img') {
      final src = element.attributes['src'] ?? "";
      if (src.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.image, data: src));
      }
    }
  }

  void _parseTable(dom.Element table, List<ContentBlock> blocks) {
    final rows = table.querySelectorAll('tr');
    
    // Check if it's a single-cell layout table (common in VisionIAS for "Info Boxes")
    if (rows.length == 1) {
      final cells = rows[0].querySelectorAll('td, th');
      if (cells.length == 1) {
        print('DEBUG: [NextIAS Extractor] Detected layout table (single cell), wrapping in callout');
        // It's a layout container. Parse its children normally to extract headings, lists, etc.
        final innerBlocks = <ContentBlock>[];
        for (var node in cells[0].nodes) {
          _parseNode(node, innerBlocks);
        }
        if (innerBlocks.isNotEmpty) {
          blocks.add(ContentBlock(type: ContentBlockType.callout, data: innerBlocks));
        }
        return;
      }
    }

    final List<List<String>> tableData = [];

    for (var row in rows) {
      final cells = row.querySelectorAll('td, th');
      final rowData = cells.map((c) => _cleanText(c.text)).toList();
      if (rowData.isNotEmpty && rowData.any((s) => s.isNotEmpty)) {
        tableData.add(rowData);
      }
    }
    
    if (tableData.isNotEmpty) {
      blocks.add(ContentBlock(type: ContentBlockType.table, data: tableData));
    }
  }

  List<ListItem> _parseList(dom.Element listElement) {
    final items = <ListItem>[];
    for (var li in listElement.children) {
      if (li.localName == 'li') {
        final nestedList = li.querySelector('ul') ?? li.querySelector('ol');
        List<ListItem> children = [];
        if (nestedList != null) {
          children = _parseList(nestedList);
        }

        final liClone = li.clone(true);
        liClone.querySelector('ul')?.remove();
        liClone.querySelector('ol')?.remove();

        items.add(ListItem(
          spans: [InlineSpanData(_cleanText(liClone.text))],
          children: children,
        ));
      }
    }
    return items;
  }

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<ArticleContent> _parseGeneric(dom.Document document, String url) async {
    final title = document.querySelector('h1')?.text.trim() ?? 'Untitled';
    return ArticleContent(
      title: title,
      content: [ContentBlock(type: ContentBlockType.p, data: [InlineSpanData('NextIAS article content extraction in progress...')])],
      source: SourceInfo(text: 'NextIAS', url: url),
    );
  }
}
