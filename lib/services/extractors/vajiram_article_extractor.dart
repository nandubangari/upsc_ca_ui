import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import '../../models/article_content.dart';
import 'base_article_extractor.dart';

class VajiramArticleExtractor implements BaseArticleExtractor {
  @override
  Future<List<ArticleContent>> fetchAndParse(String url) async {
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

    // 🔴 CLEANUP: Remove unwanted tags
    mainNode.querySelectorAll('script, style').forEach((e) => e.remove());

    // 1. Title
    final title = mainNode.querySelector('h1.font-26')?.text.trim() ??
        mainNode.querySelector('h1')?.text.trim() ??
        mainNode.querySelector('.font-26')?.text.trim() ??
        'Untitled';

    // 2. Date
    String? date =
        mainNode.querySelector('div.mb-3.d-flex.align-items-center')?.text.trim() ??
            mainNode.querySelector('.font-14')?.text.trim() ??
            document.querySelector('.box-header small')?.text.trim() ??
            mainNode.querySelector('small i.fa-clock-o')?.parent?.text.trim() ??
            document.querySelector('small i.fa-clock-o')?.parent?.text.trim();

    if (date != null) {
      date = date.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    // 3. Subtitle
    final subtitle = mainNode.querySelector('h2.font-20')?.text.trim() ??
        mainNode.querySelector('h2')?.text.trim();

    // 4. Image
    final imageUrl = mainNode.querySelector('img')?.attributes['src'];

    // 5. Content (Consolidated Logic)
    final contentBlocks = <ContentBlock>[];
    final detailsNode = mainNode.querySelector('div.article_details');

    final container = detailsNode ?? mainNode;
    
    // Traverse nodes to preserve structure
    for (final node in container.nodes) {
      _parseRootNode(node, contentBlocks);
    }

    // 6. Source
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

    return [ArticleContent(
      title: title,
      date: date,
      subtitle: subtitle?.isNotEmpty == true ? subtitle : null,
      imageUrl: imageUrl,
      content: contentBlocks,
      source: source,
    )];
  }

  void _parseRootNode(dom.Node node, List<ContentBlock> blocks) {
    if (node is dom.Element) {
      switch (node.localName) {
        case 'p':
          final spans = _parseInline(node);
          if (spans.isNotEmpty) {
            blocks.add(ContentBlock(type: ContentBlockType.p, data: spans));
          }
          break;
        case 'ul':
        case 'ol':
          final listItems = _parseList(node);
          if (listItems.isNotEmpty) {
            blocks.add(ContentBlock(type: ContentBlockType.ul, data: listItems));
          }
          break;
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          blocks.add(ContentBlock(type: ContentBlockType.h3, data: node.text.trim()));
          break;
        case 'div':
        case 'section':
          // Avoid duplicate headers/metadata
          if (node.classes.contains('margin-b-20') || node.classes.contains('text-gray-888')) {
            return;
          }
          for (var child in node.nodes) {
            _parseRootNode(child, blocks);
          }
          break;
        case 'strong':
        case 'b':
        case 'span':
        case 'em':
        case 'i':
          // If we find inline elements at root level, treat them as a paragraph
          final spans = _parseInline(node.parent ?? node);
          
          // To avoid duplicates, we only do this if this is the first inline sibling
          // We check if there's any preceding non-empty node
          final nodes = node.parent?.nodes ?? [];
          final index = nodes.indexOf(node);
          dom.Node? prev;
          if (index > 0) {
            for (int i = index - 1; i >= 0; i--) {
              final n = nodes[i];
              if (n is dom.Element || (n.text?.trim().isNotEmpty ?? false)) {
                prev = n;
                break;
              }
            }
          }
          
          if (prev == null) {
             if (spans.isNotEmpty) {
               blocks.add(ContentBlock(type: ContentBlockType.p, data: spans));
             }
          }
          break;
      }
    } else if (node.nodeType == dom.Node.TEXT_NODE) {
      final text = node.text?.trim() ?? '';
      if (text.isNotEmpty && text.length > 2) {
        blocks.add(ContentBlock(type: ContentBlockType.p, data: [InlineSpanData(text)]));
      }
    }
  }

  List<InlineSpanData> _parseInline(dom.Element element) {
    final spans = <InlineSpanData>[];

    for (final node in element.nodes) {
      if (node is dom.Element) {
        // Skip nested lists in spans
        if (node.localName == 'ul' || node.localName == 'ol') continue;

        final isBold = node.localName == 'strong' || node.localName == 'b';
        
        // Extract color if present
        String? color;
        final style = node.attributes['style'];
        if (style != null && style.contains('color')) {
          final match = RegExp(r'color:\s*([^;]+)').firstMatch(style);
          color = match?.group(1);
        }

        final text = node.text.replaceAll(RegExp(r'\s+'), ' ');
        if (text.isNotEmpty && text != ' ') {
          spans.add(
            InlineSpanData(
              text,
              isBold: isBold,
              color: color,
            ),
          );
        }
      } else {
        final text = node.text?.replaceAll(RegExp(r'\s+'), ' ') ?? '';
        if (text.isNotEmpty) {
          spans.add(InlineSpanData(text));
        }
      }
    }

    return spans;
  }

  List<ListItem> _parseList(dom.Element listElement) {
    final items = <ListItem>[];
    for (var li in listElement.children.where((e) => e.localName == 'li')) {
      final spans = _parseInline(li);
      
      dom.Element? nested;
      for (final child in li.children) {
        if (child.localName == 'ul' || child.localName == 'ol') {
          nested = child;
          break;
        }
      }

      items.add(ListItem(
        spans: spans,
        children: nested != null ? _parseList(nested) : [],
      ));
    }
    return items;
  }
}
