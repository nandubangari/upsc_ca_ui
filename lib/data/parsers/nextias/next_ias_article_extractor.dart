import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:upsc_ca_ui/shared/models/article_content.dart';
import 'package:upsc_ca_ui/data/parsers/base_article_extractor.dart';

class NextIASArticleExtractor implements BaseArticleExtractor {
  bool _stopParsing = false;

  @override
  Future<List<ArticleContent>> fetchAndParse(String url) async {
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
      AppLogger.d("[NextIAS Extractor] Main content container not found, using generic parser");
      return _parseGeneric(document, url);
    }

    // 🔴 CLEANUP
    container.querySelectorAll('script, style, .social-share, .related-posts').forEach((e) => e.remove());

    // Detect Multi-Article Mode
    final articleHeadings = container.querySelectorAll('h2.wp-block-heading.has-text-align-center');
    if (articleHeadings.length > 1) {
      AppLogger.d("[NextIAS Extractor] Detected multi-article page with ${articleHeadings.length} articles");
      return _parseMultiArticlePage(container, articleHeadings, url);
    }

    // 1. Title
    final title = document.querySelector('h1')?.text.trim() ?? 
                  document.querySelector('.page-title')?.text.trim() ??
                  'NextIAS Article';

    // 2. Content Blocks
    final contentBlocks = <ContentBlock>[];
    
    // Iterate through children to preserve order
    for (final node in container.nodes) {
      if (_stopParsing) break;
      _parseNode(node, contentBlocks);
    }

    return [ArticleContent(
      title: title,
      content: contentBlocks,
      source: SourceInfo(text: 'NextIAS', url: url),
    )];
  }

  Future<List<ArticleContent>> _parseMultiArticlePage(dom.Element container, List<dom.Element> headings, String url) async {
    final List<ArticleContent> results = [];
    
    for (int i = 0; i < headings.length; i++) {
      _stopParsing = false; // Reset state for each sub-article
      final heading = headings[i];
      final title = heading.text.trim();
      final contentBlocks = <ContentBlock>[];
      
      dom.Node? next = _getNextSibling(heading);
      while (next != null) {
        if (next is dom.Element) {
          // Stop if we hit the next article heading
          if (next.localName == 'h2' && next.classes.contains('has-text-align-center')) {
            break;
          }
          // Stop if we hit navigation/footer elements
          if (next.classes.contains('clearfix') || 
              next.classes.contains('post-navigation') ||
              next.classes.contains('related-posts')) {
            break;
          }
        }
        
        _parseNode(next, contentBlocks);
        next = _getNextSibling(next);
      }
      
      if (contentBlocks.isNotEmpty) {
        results.add(ArticleContent(
          title: title,
          content: contentBlocks,
          source: SourceInfo(text: 'NextIAS', url: url),
        ));
      }
    }
    
    return results;
  }

  dom.Node? _getNextSibling(dom.Node node) {
    final parent = node.parentNode;
    if (parent == null) return null;
    final siblings = parent.nodes;
    final index = siblings.indexOf(node);
    if (index == -1 || index >= siblings.length - 1) return null;
    return siblings[index + 1];
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
      
      final spans = _parseInline(element);
      if (spans.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.p, data: spans));
      }
    } 
    // Handle Images (wp-block-image style)
    else if (tagName == 'div' && element.classes.contains('wp-block-image')) {
      final img = element.querySelector('img');
      final src = img?.attributes['src'] ?? "";
      if (src.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.image, data: ImageData(url: src)));
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
           blocks.add(ContentBlock(type: ContentBlockType.image, data: ImageData(url: src)));
           return;
         }
      }

      final table = element.querySelector('table');
      if (table != null) {
        _parseTable(table, blocks);
      } else {
      for (final child in element.nodes) {
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
        blocks.add(ContentBlock(type: ContentBlockType.image, data: ImageData(url: src)));
      }
    }
  }

  void _parseTable(dom.Element table, List<ContentBlock> blocks) {
    final rows = table.querySelectorAll('tr');
    
    // Check if it's a single-cell layout table (common in VisionIAS for "Info Boxes")
    if (rows.length == 1) {
      final cells = rows[0].querySelectorAll('td, th');
      if (cells.length == 1) {
        AppLogger.d("[NextIAS Extractor] Detected layout table (single cell), wrapping in callout");
        // It's a layout container. Parse its children normally to extract headings, lists, etc.
        final innerBlocks = <ContentBlock>[];
        for (final node in cells[0].nodes) {
          _parseNode(node, innerBlocks);
        }
        if (innerBlocks.isNotEmpty) {
          blocks.add(ContentBlock(type: ContentBlockType.callout, data: innerBlocks));
        }
        return;
      }
    }

    final List<List<String>> tableData = [];

    for (final row in rows) {
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
    for (final li in listElement.children) {
      if (li.localName == 'li') {
        final nestedList = li.querySelector('ul') ?? li.querySelector('ol');
        final List<ListItem> children;
        if (nestedList != null) {
          children = _parseList(nestedList);
        } else {
          children = [];
        }

        items.add(ListItem(
          spans: _parseInline(li),
          children: children,
        ));
      }
    }
    return items;
  }

  List<InlineSpanData> _parseInline(dom.Element element) {
    final spans = <InlineSpanData>[];

    void traverse(dom.Node n, {bool isBold = false, String? color}) {
      if (n is dom.Text) {
        final text = n.text;
        if (text.isNotEmpty) {
          spans.add(InlineSpanData(text, isBold: isBold, color: color));
        }
      } else if (n is dom.Element) {
        if (n.localName == 'ul' || n.localName == 'ol' || n.localName == 'br') return;

        bool currentBold = isBold || n.localName == 'strong' || n.localName == 'b';
        
        String? currentColor = color;
        final style = n.attributes['style'];
        if (style != null && style.contains('color')) {
          final match = RegExp(r'color:\s*([^;]+)').firstMatch(style);
          if (match != null) currentColor = match.group(1);
        }

        for (final child in n.nodes) {
          traverse(child, isBold: currentBold, color: currentColor);
        }
      }
    }

    // Process nodes, but skip nested lists as they are handled by _parseList
    for (final child in element.nodes) {
      if (child is dom.Element && (child.localName == 'ul' || child.localName == 'ol')) continue;
      traverse(child);
    }

    return spans
        .map((s) => InlineSpanData(s.text.replaceAll(RegExp(r'\s+'), ' '), isBold: s.isBold, color: s.color))
        .where((s) => s.text.isNotEmpty)
        .toList();
  }

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<List<ArticleContent>> _parseGeneric(dom.Document document, String url) async {
    final title = document.querySelector('h1')?.text.trim() ?? 'Untitled';
    return [ArticleContent(
      title: title,
      content: [ContentBlock(type: ContentBlockType.p, data: [InlineSpanData('NextIAS article content extraction in progress...')])],
      source: SourceInfo(text: 'NextIAS', url: url),
    )];
  }
}








