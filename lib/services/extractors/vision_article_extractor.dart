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
    
    // Root container based on user input
    final container = document.querySelector('#article-content');

    if (container == null) {
      print('DEBUG: [Vision Extractor] #article-content not found, trying fallback');
      // Fallback to searching for specific classes if ID is missing
      return _parseGeneric(document, url);
    }

    // 🔴 CLEANUP
    container.querySelectorAll('script, style').forEach((e) => e.remove());

    // 1. Title
    // On article page, h1 or h2 is usually the title. 
    // If not found, we use a default or try to get it from meta tags.
    final title = container.querySelector('h1')?.text.trim() ?? 
                  document.querySelector('h1')?.text.trim() ??
                  document.querySelector('title')?.text.trim() ??
                  'VisionIAS Article';

    // 2. Content Blocks
    final contentBlocks = <ContentBlock>[];
    
    // We iterate through nodes to preserve order
    for (var node in container.nodes) {
      _parseNode(node, contentBlocks);
    }

    return ArticleContent(
      title: title,
      content: contentBlocks,
      source: SourceInfo(text: 'VisionIAS', url: url),
    );
  }

  void _parseNode(dom.Node node, List<ContentBlock> blocks) {
    if (node is! dom.Element) {
      final text = node.text?.trim() ?? '';
      if (text.isNotEmpty && text.length > 5) {
        blocks.add(ContentBlock(type: ContentBlockType.p, data: _cleanText(text)));
      }
      return;
    }

    final element = node;
    final tagName = element.localName;

    if (tagName == 'p') {
      final text = _cleanText(element.text);
      if (text.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.p, data: text));
      }
    } else if (tagName == 'ul' || tagName == 'ol') {
      final listItems = _parseList(element);
      if (listItems.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.ul, data: listItems));
      }
    } else if (tagName == 'h1' || tagName == 'h2' || tagName == 'h3' || tagName == 'h4') {
      final text = _cleanText(element.text);
      if (text.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.h3, data: text));
      }
    } else if (tagName == 'div' || tagName == 'section' || tagName == 'figure') {
      // Check for tables inside figure
      final table = element.querySelector('table');
      if (table != null) {
        _parseTable(table, blocks);
      } else {
        for (var child in element.nodes) {
          _parseNode(child, blocks);
        }
      }
    } else if (tagName == 'table') {
      _parseTable(element, blocks);
    }
  }

  void _parseTable(dom.Element table, List<ContentBlock> blocks) {
    final rows = table.querySelectorAll('tr');
    
    // Check if it's a single-cell layout table (common in VisionIAS for "Info Boxes")
    if (rows.length == 1) {
      final cells = rows[0].querySelectorAll('td, th');
      if (cells.length == 1) {
        print('DEBUG: [Vision Extractor] Detected layout table (single cell), wrapping in callout');
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
          text: _cleanText(liClone.text),
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
    // Fallback logic if #article-content is missing
    final title = document.querySelector('h1')?.text.trim() ?? 'Untitled';
    return ArticleContent(
      title: title,
      content: [ContentBlock(type: ContentBlockType.p, data: 'Content could not be parsed specifically.')],
      source: SourceInfo(text: 'VisionIAS', url: url),
    );
  }
}
