import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import '../../models/article_content.dart';
import 'base_article_extractor.dart';

class VajiramArticleExtractor implements BaseArticleExtractor {
  @override
  Future<ArticleContent> fetchAndParse(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36'
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch article: ${response.statusCode}');
    }

    final document = parser.parse(response.body);
    final mainNode = document.querySelector('div.padding-10');

    if (mainNode == null) {
      throw Exception('Could not find article content (div.padding-10)');
    }

    // 🔴 CLEANUP: Remove unwanted tags and inline styles
    mainNode.querySelectorAll('script, style').forEach((e) => e.remove());
    mainNode.querySelectorAll('*').forEach((e) {
      e.attributes.remove('style');
    });

    // 1. Title (Flexible formats)
    final title = mainNode.querySelector('h1.font-26')?.text.trim() ??
        mainNode.querySelector('h1')?.text.trim() ??
        mainNode.querySelector('.font-26')?.text.trim() ??
        'Untitled';

    // 2. Date (Flexible formats)
    String? date =
        mainNode.querySelector('div.mb-3.d-flex.align-items-center')?.text.trim() ??
            mainNode.querySelector('.font-14')?.text.trim() ??
            document.querySelector('.box-header small')?.text.trim() ??
            mainNode.querySelector('small i.fa-clock-o')?.parent?.text.trim() ??
            document.querySelector('small i.fa-clock-o')?.parent?.text.trim();

    if (date != null) {
      date = date.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    print('DEBUG: [Vajiram Extractor] Parsed Date: $date');

    // 3. Subtitle (Flexible formats)
    final subtitle = mainNode.querySelector('h2.font-20')?.text.trim() ??
        mainNode.querySelector('h2')?.text.trim();

    // 4. Image
    final imageUrl = mainNode.querySelector('img')?.attributes['src'];

    // 5. Content
    final contentBlocks = <ContentBlock>[];
    final detailsNode = mainNode.querySelector('div.article_details');

    if (detailsNode != null) {
      for (var node in detailsNode.nodes) {
        _parseNode(node, contentBlocks);
      }
    } else {
      // Fallback: search for content directly in mainNode if article_details is missing
      for (var node in mainNode.nodes) {
        // Skip common header/metadata blocks to avoid duplicates
        if (node is dom.Element) {
          if (node.classes.contains('margin-b-20') || node.localName == 'h1' || node.localName == 'h2' || node.localName == 'img') {
            continue;
          }
          if (node.classes.contains('text-gray-888') && node.querySelector('span') != null) {
            continue; // Skip source block
          }
        }
        _parseNode(node, contentBlocks);
      }
    }

    // 6. Source (Flexible formats)
    final sourceNode = mainNode.querySelector('div.text-gray-888 span a') ??
        mainNode.querySelector('a.btn-outline-primary') ??
        mainNode.querySelector('a');
    SourceInfo? source;
    if (sourceNode != null) {
      source = SourceInfo(
        text: sourceNode.text.trim(),
        url: sourceNode.attributes['href'] ?? '',
      );
    }

    return ArticleContent(
      title: title,
      date: date,
      subtitle: subtitle?.isNotEmpty == true ? subtitle : null,
      imageUrl: imageUrl,
      content: contentBlocks,
      source: source,
    );
  }

  void _parseNode(dom.Node node, List<ContentBlock> blocks) {
    if (node is! dom.Element) {
      // Handle text nodes or other non-element nodes if they have significant text
      final text = node.text?.trim() ?? '';
      if (text.isNotEmpty && text.length > 5) {
         blocks.add(ContentBlock(type: ContentBlockType.p, data: text));
      }
      return;
    }

    final element = node;
    if (element.localName == 'p') {
      final text = element.text.trim();
      if (text.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.p, data: text));
      }
    } else if (element.localName == 'ul' || element.localName == 'ol') {
      final listItems = _parseList(element);
      if (listItems.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.ul, data: listItems));
      }
    } else if (element.localName == 'h3' || element.localName == 'h4' || element.localName == 'h5' || element.localName == 'h6') {
      final text = element.text.trim();
      if (text.isNotEmpty) {
        blocks.add(ContentBlock(type: ContentBlockType.h3, data: text));
      }
    } else if (element.localName == 'div' || element.localName == 'section') {
      // Dig deeper for semantic elements
      for (var child in element.nodes) {
        _parseNode(child, blocks);
      }
    } else if (element.localName == 'strong' || element.localName == 'b' || element.localName == 'span' || element.localName == 'i') {
        // If these are directly inside the container (not wrapped in P), treat as text
        final text = element.text.trim();
        if (text.isNotEmpty) {
            blocks.add(ContentBlock(type: ContentBlockType.p, data: text));
        }
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
          text: liClone.text.trim(),
          children: children,
        ));
      }
    }
    return items;
  }
}
