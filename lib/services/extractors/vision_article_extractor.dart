import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import '../../models/article_content.dart';
import 'base_article_extractor.dart';

/// 🔥 VISIONIAS EXTRACTOR - UPDATED TO RETURN ALL ARTICLES
class VisionArticleExtractor implements BaseArticleExtractor {
  @override
  Future<List<ArticleContent>> fetchAndParse(String url) async {
    debugPrint('DEBUG: [Vision Extractor] Starting fetch for: $url');
    
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

    // 1. Find Container
    final container = document.querySelector('#article-content');
    if (container == null) {
      debugPrint('DEBUG: [Vision Extractor] #article-content not found');
      return _parseGeneric(document, url);
    }

    // 2. Identify all articles (container.children with IDs)
    final articleElements = container.children.where((e) => e.id.isNotEmpty).toList();
    debugPrint('DEBUG: [Vision Extractor] Total small articles found: ${articleElements.length}');

    if (articleElements.isEmpty) {
       return [_extractSingleArticle(container, url)];
    }

    final List<ArticleContent> results = [];
    for (final element in articleElements) {
      final article = _extractSingleArticle(element, url);
      if (article.content.isNotEmpty) {
        results.add(article);
      }
    }

    debugPrint('DEBUG: [Vision Extractor] Successfully extracted ${results.length} articles');
    return results;
  }

  ArticleContent _extractSingleArticle(dom.Element card, String baseUrl) {
    // ✅ TITLE (Extract from h2 as per user instructions)
    final title = card.querySelector('h2')?.text.trim() ?? 'VisionIAS Article';

    // ✅ CONTENT ROOT (.ck-content)
    final contentRoot = _extractContentRoot(card);

    // ✅ PARSE BLOCKS
    final contentBlocks = VisionIASArticleExtractorContent().extract(contentRoot ?? card);

    // ✅ METADATA
    final tags = card
        .querySelectorAll('a[href*="search?query"]')
        .map((e) => e.text.trim())
        .toList();

    final sources = card
        .querySelectorAll('a[target="_blank"]')
        .map((e) => e.attributes['href'] ?? "")
        .where((e) => e.isNotEmpty && !e.contains('twitter.com') && !e.contains('facebook.com'))
        .toList();

    final summary = card
        .querySelectorAll('#article-summary-content')
        .expand((e) => e.querySelectorAll('li'))
        .map((li) => li.text.trim())
        .toList();

    final id = card.attributes['id'] ?? "";
    final fullUrl = id.isNotEmpty ? "${baseUrl.contains('#') ? baseUrl.split('#')[0] : baseUrl}#$id" : baseUrl;

    return ArticleContent(
      title: title,
      content: contentBlocks,
      tags: tags.isNotEmpty ? tags : null,
      summary: summary.isNotEmpty ? summary : null,
      sources: sources.isNotEmpty ? sources : null,
      source: SourceInfo(text: 'VisionIAS', url: fullUrl),
    );
  }

  dom.Element? _extractContentRoot(dom.Element article) {
    final all = article.querySelectorAll('.ck-content');
    for (final el in all) {
      if (el.text.trim().isNotEmpty) {
        return el;
      }
    }
    return null;
  }

  Future<List<ArticleContent>> _parseGeneric(dom.Document document, String url) async {
    final title = document.querySelector('h1')?.text.trim() ?? 'Untitled';
    return [ArticleContent(
      title: title,
      content: [
        ContentBlock(
          type: ContentBlockType.p, 
          data: [InlineSpanData('Content could not be parsed specifically.')]
        )
      ],
      source: SourceInfo(text: 'VisionIAS', url: url),
    )];
  }
}

/// 🧠 VISIONIAS CONTENT ANALYZER
class VisionIASArticleExtractorContent {
  List<ContentBlock> extract(dom.Element root) {
    final blocks = <ContentBlock>[];

    // IGNORE UI ELEMENTS
    // Note: We don't remove them from 'root' directly if root is shared, 
    // but here we clone or just filter during iteration.
    // Actually, in fetchAndParse we work on separate elements, so it's fine.
    root.querySelectorAll('script, style, button, .bookmark, .read, .highlights').forEach((e) => e.remove());

    for (final node in root.children) {
      final block = _parseNode(node);
      if (block != null) blocks.add(block);
    }

    return blocks;
  }

  ContentBlock? _parseNode(dom.Element element) {
    switch (element.localName) {
      case 'p':
        final spans = _parseInline(element);
        if (spans.isEmpty) return null;
        return ContentBlock(type: ContentBlockType.p, data: spans);

      case 'h2':
        // Small article titles are already handled by _extractSingleArticle, 
        // but internal h2s in body should be treated as headers.
        return ContentBlock(type: ContentBlockType.h2, data: element.text.trim());
      
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return ContentBlock(type: ContentBlockType.h3, data: element.text.trim());

      case 'ul':
      case 'ol':
        final listItems = _parseList(element);
        if (listItems.isEmpty) return null;
        return ContentBlock(type: ContentBlockType.ul, data: listItems);

      case 'figure':
        final img = element.querySelector('img');
        if (img != null) {
          return ContentBlock(
            type: ContentBlockType.image,
            data: ImageData(
              url: img.attributes['src'] ?? '',
              width: double.tryParse(img.attributes['width'] ?? ''),
              height: double.tryParse(img.attributes['height'] ?? ''),
            ),
          );
        }
        final table = element.querySelector('table');
        if (table != null) return _parseTable(table);
        return null;

      case 'img':
        return ContentBlock(
          type: ContentBlockType.image,
          data: ImageData(url: element.attributes['src'] ?? ''),
        );

      case 'table':
        return _parseTable(element);

      default:
        return null;
    }
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

    for (final child in node.nodes) {
      traverse(child);
    }

    return spans
        .map((s) => InlineSpanData(s.text.replaceAll(RegExp(r'\s+'), ' '), isBold: s.isBold, color: s.color))
        .where((s) => s.text.trim().isNotEmpty)
        .toList();
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

  ContentBlock? _parseTable(dom.Element table) {
    final rows = <List<String>>[];
    for (final tr in table.querySelectorAll('tr')) {
      final cells = tr.querySelectorAll('td, th').map((c) => c.text.trim()).toList();
      if (cells.isNotEmpty) rows.add(cells);
    }
    if (rows.isEmpty) return null;
    return ContentBlock(type: ContentBlockType.table, data: rows);
  }
}
