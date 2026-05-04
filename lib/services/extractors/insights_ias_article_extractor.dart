import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import '../../models/article_content.dart';
import 'base_article_extractor.dart';

class InsightsIASArticleExtractor implements BaseArticleExtractor {
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
      print('DEBUG: [InsightsIAS Extractor] Main content container not found, using generic parser');
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
    
    for (var node in container.children) {
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
          contentBlocks.add(ContentBlock(type: ContentBlockType.image, data: src));
          if (caption.isNotEmpty) {
            contentBlocks.add(ContentBlock(type: ContentBlockType.p, data: _cleanText(caption)));
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

        contentBlocks.add(ContentBlock(
          type: isHeading ? ContentBlockType.h3 : ContentBlockType.p,
          data: text,
        ));
      } else if (node.localName != null && ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(node.localName)) {
        final text = _cleanText(node.text);
        if (text.isNotEmpty) {
          contentBlocks.add(ContentBlock(type: ContentBlockType.h3, data: text));
        }
      }
    }

    return ArticleContent(
      title: title,
      subtitle: subject,
      content: contentBlocks,
      source: SourceInfo(text: sourceText, url: url),
    );
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
            final text = _cleanText(node.text);
            if (text.isNotEmpty) {
               innerBlocks.add(ContentBlock(type: ContentBlockType.p, data: text));
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
          text: _cleanText(liClone.text),
          children: children,
        ));
      }
    }
    return items;
  }

  String _cleanText(String text) {
    // 1. Basic whitespace cleanup
    String cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // 2. Remove emojis and common non-ASCII icons
    return cleaned.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}\u{1F191}-\u{1F251}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{3030}\u{2B50}\u{2B55}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{3297}\u{3299}\u{303D}\u{00A9}\u{00AE}\u{2122}\u{231A}-\u{231B}\u{2328}\u{23CF}\u{23E9}-\u{23F3}\u{23F8}-\u{23FA}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2604}\u{260E}\u{2611}\u{2614}-\u{2615}\u{2618}\u{261D}\u{2620}\u{2622}-\u{2623}\u{2626}\u{262A}\u{262E}-\u{262F}\u{2638}-\u{263A}\u{2640}\u{2642}\u{2648}-\u{2653}\u{265F}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267E}-\u{267F}\u{2692}-\u{2697}\u{2699}\u{269B}-\u{269C}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26B0}-\u{26B1}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26C8}\u{26CE}-\u{26CF}\u{26D1}\u{26D3}-\u{26D4}\u{26E9}-\u{26EA}\u{26F0}-\u{26F5}\u{26F7}-\u{26FA}\u{26FD}]', unicode: true), '').trim();
  }

  Future<ArticleContent> _parseGeneric(dom.Document document, String url) async {
    final title = document.querySelector('h1')?.text.trim() ?? 'Untitled';
    return ArticleContent(
      title: title,
      content: [ContentBlock(type: ContentBlockType.p, data: 'InsightsIAS article content extraction in progress...')],
      source: SourceInfo(text: 'InsightsIAS', url: url),
    );
  }
}
