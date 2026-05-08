import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:upsc_ca_ui/shared/models/article_content.dart';
import 'package:upsc_ca_ui/data/parsers/base_article_extractor.dart';

class InsightsIASArticleExtractor implements BaseArticleExtractor {
  @override
  Future<List<ArticleContent>> fetchAndParse(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch InsightsIAS article: ${response.statusCode}');
    }

    final document = parser.parse(response.body);
    
    // InsightsIAS articles often use .article-body-column for the specific article content
    final container = document.querySelector('.article-body-column') ?? 
                      document.querySelector('.pf-content') ?? 
                      document.querySelector('.entry-content') ?? 
                      document.querySelector('article') ??
                      document.querySelector('.post-content');

    if (container == null) {
      AppLogger.d("[InsightsIAS Extractor] Main content container not found, using generic parser");
      return _parseGeneric(document, url);
    }

    // 🔴 CLEANUP
    container.querySelectorAll('script, style, .social-share, .sharedaddy, .related-posts, .jp-relatedposts, .wp-block-buttons').forEach((e) => e.remove());

    // 1. Title
    final rawTitle = document.querySelector('h1.entry-title')?.text.trim() ?? 
                     document.querySelector('h1')?.text.trim() ??
                     'InsightsIAS Article';
    final title = _cleanText(rawTitle);

    // 2. Content Blocks
    final contentBlocks = <ContentBlock>[];
    String sourceText = 'InsightsIAS';
    String? subject;
    
    for (final node in container.children) {
      // -----------------------------------------
      // 1. METADATA (Source / Subject)
      // -----------------------------------------
      if (node.localName == 'p' && node.text.contains("Source:")) {
        sourceText = _cleanText(node.text.replaceAll("Source:", ""));
        continue;
      }

      if (node.localName == 'p' && node.text.contains("Subject:")) {
        subject = _cleanText(node.text.replaceAll("Subject:", ""));
        continue;
      }

      // -----------------------------------------
      // 2. IMAGE (figure)
      // -----------------------------------------
      if (node.localName == 'figure') {
        final img = node.querySelector('img');
        final caption = node.querySelector('figcaption')?.text ?? "";
        final src = img?.attributes['src'] ?? "";

        if (src.isNotEmpty) {
          contentBlocks.add(ContentBlock(type: ContentBlockType.image, data: ImageData(url: src)));
          if (caption.isNotEmpty) {
            contentBlocks.add(ContentBlock(type: ContentBlockType.p, data: [InlineSpanData(_cleanText(caption))]));
          }
        }
        continue;
      }

      // -----------------------------------------
      // 3. TABLE
      // -----------------------------------------
      final table = node.localName == 'table' ? node : node.querySelector('table');
      if (table != null) {
        _parseTable(table, contentBlocks);
        continue;
      }

      // -----------------------------------------
      // 4. LIST (ul / ol)
      // -----------------------------------------
      if (node.localName == 'ul' || node.localName == 'ol') {
        final listItems = _parseList(node);
        if (listItems.isNotEmpty) {
          contentBlocks.add(ContentBlock(type: ContentBlockType.ul, data: listItems));
        }
        continue;
      }

      // -----------------------------------------
      // 5. PARAGRAPH / HEADING
      // -----------------------------------------
      if (node.localName == 'p') {
        final text = _cleanText(node.text);
        if (text.isEmpty) continue;

        // Detect heading pattern: e.g. "Context:", "About:", "What it is?"
        final isHeading = text.endsWith(":") ||
            text.toLowerCase().contains("context") ||
            text.toLowerCase().contains("about");

        if (isHeading) {
          contentBlocks.add(ContentBlock(
            type: ContentBlockType.h3,
            data: text,
          ));
        } else {
          final spans = _parseInline(node);
          if (spans.isNotEmpty) {
            contentBlocks.add(ContentBlock(
              type: ContentBlockType.p,
              data: spans,
            ));
          }
        }
      } else if (node.localName != null && ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(node.localName)) {
        final text = _cleanText(node.text);
        if (text.isNotEmpty) {
          contentBlocks.add(ContentBlock(type: ContentBlockType.h3, data: text));
        }
      }
    }

    return [ArticleContent(
      title: title,
      subtitle: subject,
      content: contentBlocks,
      source: SourceInfo(text: sourceText, url: url),
    )];
  }

  void _parseTable(dom.Element table, List<ContentBlock> blocks) {
    final rows = table.querySelectorAll('tr');
    
    // Check if it's a single-cell layout table
    if (rows.length == 1) {
      final cells = rows[0].querySelectorAll('td, th');
      if (cells.length == 1) {
        final innerBlocks = <ContentBlock>[];
        for (var node in cells[0].children) {
          // Simple recursive extraction for layout table
          if (node.localName == 'p') {
            final spans = _parseInline(node);
            if (spans.isNotEmpty) {
               innerBlocks.add(ContentBlock(type: ContentBlockType.p, data: spans));
            }
          } else if (node.localName == 'ul' || node.localName == 'ol') {
            innerBlocks.add(ContentBlock(type: ContentBlockType.ul, data: _parseList(node)));
          }
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

  List<InlineSpanData> _parseInline(dom.Node node) {
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

    // If node is an Element, we process its nodes. If it's just a Node, we traverse it.
    final nodes = node is dom.Element ? node.nodes : [node];
    for (final child in nodes) {
      if (child is dom.Element && (child.localName == 'ul' || child.localName == 'ol')) continue;
      traverse(child);
    }

    return spans
        .map((s) => InlineSpanData(s.text.replaceAll(RegExp(r'\s+'), ' '), isBold: s.isBold, color: s.color))
        .where((s) => s.text.isNotEmpty)
        .toList();
  }

  String _cleanText(String text) {
    // Basic whitespace cleanup and removal of problematic characters that break regex
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<List<ArticleContent>> _parseGeneric(dom.Document document, String url) async {
    final title = document.querySelector('h1')?.text.trim() ?? 'Untitled';
    return [ArticleContent(
      title: title,
      content: [ContentBlock(type: ContentBlockType.p, data: [InlineSpanData('InsightsIAS article content extraction in progress...')])],
      source: SourceInfo(text: 'InsightsIAS', url: url),
    )];
  }
}








