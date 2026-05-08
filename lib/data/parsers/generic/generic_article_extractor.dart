import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:upsc_ca_ui/shared/models/article_content.dart';
import 'package:upsc_ca_ui/data/parsers/base_article_extractor.dart';

class GenericArticleExtractor implements BaseArticleExtractor {
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
      throw Exception('Failed to fetch article: ${response.statusCode}');
    }

    final document = parser.parse(response.body);

    // 1. Metadata Extraction (Meta/OG Tags)
    final title = _getMeta(document, 'og:title') ??
        document.querySelector('h1')?.text.trim() ??
        document.querySelector('title')?.text.trim() ??
        'Untitled';

    final imageUrl = _getMeta(document, 'og:image');
    
    // Try to find a date in meta
    final date = _getMeta(document, 'article:published_time') ??
                 _getMeta(document, 'publish-date') ??
                 _findDateInText(document);

    final description = _getMeta(document, 'og:description') ??
                        _getMeta(document, 'description');

    // 2. Heuristic Main Content Identification
    final mainNode = _findMainContent(document);
    
    final contentBlocks = <ContentBlock>[];
    if (mainNode != null) {
      // 🔴 CLEANUP: Remove common noise
      mainNode.querySelectorAll('script, style, nav, footer, header, aside, .ads, .social-share, .comments').forEach((e) => e.remove());
      mainNode.querySelectorAll('*').forEach((e) {
        e.attributes.remove('style');
      });

      _parseNodesRecursive(mainNode, contentBlocks);
    }

    // Fallback if no content found
    if (contentBlocks.isEmpty && description != null) {
      contentBlocks.add(ContentBlock(type: ContentBlockType.p, data: [InlineSpanData(description)]));
    }

    return [ArticleContent(
      title: title,
      date: date,
      subtitle: description != title ? description : null,
      imageUrl: imageUrl,
      content: contentBlocks,
      source: SourceInfo(text: "Original Source", url: url),
    )];
  }

  String? _getMeta(dom.Document doc, String property) {
    return doc.querySelector('meta[property="$property"]')?.attributes['content'] ??
           doc.querySelector('meta[name="$property"]')?.attributes['content'];
  }

  String? _findDateInText(dom.Document doc) {
    final dateMatch = RegExp(r'(\d{1,2}\s+[A-Z][a-z]+\s+\d{4})|([A-Z][a-z]+\s+\d{1,2},?\s+\d{4})').firstMatch(doc.body?.text ?? '');
    return dateMatch?.group(0);
  }

  dom.Element? _findMainContent(dom.Document doc) {
    // 1. Best case: semantic tags
    final semantic = doc.querySelector('article') ?? doc.querySelector('main');
    if (semantic != null) return semantic;

    // 2. ID/Class based heuristics
    final commonContainers = doc.querySelectorAll('div');
    dom.Element? bestMatch;
    int maxTextLength = 0;

    for (var div in commonContainers) {
      final id = (div.attributes['id'] ?? '').toLowerCase();
      final className = (div.attributes['class'] ?? '').toLowerCase();
      
      if (id.contains('content') || id.contains('article') || id.contains('post') ||
          className.contains('content') || className.contains('article') || className.contains('post')) {
        
        final textLength = div.text.trim().length;
        if (textLength > maxTextLength) {
          maxTextLength = textLength;
          bestMatch = div;
        }
      }
    }

    return bestMatch ?? doc.body;
  }

  void _parseNodesRecursive(dom.Element node, List<ContentBlock> blocks) {
    for (var child in node.children) {
      if (child.localName == 'p') {
        final text = child.text.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (text.length > 20) { // Avoid tiny snippets or UI noise
          blocks.add(ContentBlock(type: ContentBlockType.p, data: [InlineSpanData(text)]));
        }
      } else if (child.localName == 'ul' || child.localName == 'ol') {
        final listItems = _parseList(child);
        if (listItems.isNotEmpty) {
          blocks.add(ContentBlock(type: ContentBlockType.ul, data: listItems));
        }
      } else if (child.localName == 'h2' || child.localName == 'h3') {
        final text = child.text.trim();
        if (text.isNotEmpty) {
          blocks.add(ContentBlock(type: ContentBlockType.h3, data: text));
        }
      } else if (child.children.isNotEmpty) {
        // Dig deeper if it's a generic div/section
        _parseNodesRecursive(child, blocks);
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
          spans: [InlineSpanData(liClone.text.replaceAll(RegExp(r'\s+'), ' ').trim())],
          children: children,
        ));
      }
    }
    return items;
  }
}






