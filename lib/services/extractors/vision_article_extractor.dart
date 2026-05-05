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

    // 0. Extract Main Title (Specific selector provided by user)
    // Using a robust selector that targets the specific h1 class structure provided
    final h1_v1 = document.querySelector('h1.text-3xl.text-center.text-pretty');
    final h1_v2 = document.querySelector('h1.text-3xl');
    final h1_v3 = document.querySelector('h1');
    
    // Log the whole document's h1s to see if there are multiples
    final allH1s = document.querySelectorAll('h1').map((e) => e.text.trim()).toList();
    debugPrint('DEBUG: [Vision Extractor] All H1s in doc: $allH1s');
    debugPrint('DEBUG: [Vision Extractor] H1 Selectors: v1=${h1_v1?.text.trim()}, v2=${h1_v2?.text.trim()}, v3=${h1_v3?.text.trim()}');

    final mainTitle = h1_v1?.text.trim() ?? 
                     h1_v2?.text.trim() ??
                     h1_v3?.text.trim() ??
                     'VisionIAS Article';

    debugPrint('DEBUG: [Vision Extractor] Final mainTitle chosen: $mainTitle');

    // 1. Find Container
    final container = document.querySelector('#article-content');
    if (container == null) {
      debugPrint('DEBUG: [Vision Extractor] #article-content not found');
      return _parseGeneric(document, url, mainTitle);
    }

    // 2. Identify all articles (container.children with IDs)
    final articleElements = container.children.where((e) => e.id.isNotEmpty).toList();
    debugPrint('DEBUG: [Vision Extractor] Total small articles found: ${articleElements.length}');

    if (articleElements.isEmpty) {
       // If it's a single article page, we force the use of mainTitle (H1)
       return [_extractSingleArticle(container, url, mainTitle, forceFallback: true)];
    }

    final List<ArticleContent> results = [];
    for (int i = 0; i < articleElements.length; i++) {
      final element = articleElements[i];
      // For the first article, we want to ensure the mainTitle (h1) is used as the primary title
      final article = _extractSingleArticle(element, url, mainTitle, forceFallback: i == 0);
      if (article.content.isNotEmpty) {
        results.add(article);
      }
    }

    debugPrint('DEBUG: [Vision Extractor] Successfully extracted ${results.length} articles');
    return results;
  }

  ArticleContent _extractSingleArticle(dom.Element card, String baseUrl, String fallbackTitle, {bool forceFallback = false}) {
    // ✅ TITLE (Extract from h2, fallback to the provided title if missing, generic, or if forced)
    String? h2Title = card.querySelector('h2')?.text.trim();
    String title;
    
    // Check if the extracted h2 is actually just the same as fallback or something generic
    bool isH2Generic = h2Title == null || 
                       h2Title.isEmpty || 
                       h2Title.toLowerCase().contains('visionias') || 
                       h2Title.toLowerCase() == 'article';

    if (forceFallback || isH2Generic) {
      title = fallbackTitle;
    } else {
      title = h2Title;
    }

    // ✅ CONTENT ROOT (.ck-content)
    final contentRoot = _extractContentRoot(card);

    // ✅ PARSE BLOCKS
    final contentBlocks = VisionIASArticleExtractorContent().extract(contentRoot ?? card);
    
    // 🔴 DEDUPLICATION: Remove the first block if it's an H2 matching our title
    if (contentBlocks.isNotEmpty && 
        contentBlocks.first.type == ContentBlockType.h2 && 
        contentBlocks.first.data.toString().trim() == title) {
      contentBlocks.removeAt(0);
    }

    // If we forced the fallback title (H1) and there was an H2 title, 
    // AND it's not the same as our title, we could insert it. 
    // But per user feedback, we want to avoid duplicates.
    // If the H2 is "Emerging domains..." and Title is "Defence Minister...", 
    // we keep the H2 as a sub-heading in the body.
    if (forceFallback && !isH2Generic && h2Title != null && h2Title != title) {
      bool alreadyPresent = contentBlocks.any((b) => b.type == ContentBlockType.h2 && b.data == h2Title);
      if (!alreadyPresent) {
        contentBlocks.insert(0, ContentBlock(type: ContentBlockType.h2, data: h2Title));
      }
    }

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

  Future<List<ArticleContent>> _parseGeneric(dom.Document document, String url, String fallbackTitle) async {
    // We strictly prefer the fallbackTitle (which is the H1 we extracted earlier)
    // as it's the most reliable main headline.
    final title = (fallbackTitle.isNotEmpty && fallbackTitle != 'VisionIAS Article') 
        ? fallbackTitle 
        : (document.querySelector('h1.text-3xl.text-center.text-pretty')?.text.trim() ??
           document.querySelector('h1.text-3xl')?.text.trim() ??
           document.querySelector('h1')?.text.trim() ??
           fallbackTitle);

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
        // If this h2 matches the main title we've already set in the reader header, 
        // we skip it to avoid duplication in the body.
        final text = element.text.trim();
        // We'll leave the actual filtering to the 'extract' loop where we have context or 
        // just return the block and filter later. For now, we return null if it's likely the title.
        // Actually, in fetchAndParse we already use H1 or H2 as the ArticleContent.title.
        // The reader shows ArticleContent.title.
        // If this h2 is inside the card, it's often the same as the title.
        return ContentBlock(type: ContentBlockType.h2, data: text);
      
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
        
        // Handle InfoBox: <figure class="table"> with h2/h3 and ul
        if (element.classes.contains('table')) {
          final infoBox = _parseInfoBox(element);
          if (infoBox != null) {
            return ContentBlock(type: ContentBlockType.infobox, data: infoBox);
          }
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

  InfoBoxData? _parseInfoBox(dom.Element figure) {
    final headingElement = figure.querySelector('h2, h3');
    final ul = figure.querySelector('ul');

    if (headingElement == null || ul == null) return null;

    final heading = headingElement.text.trim();
    final items = <InfoItem>[];

    void parseList(dom.Element ul, int level) {
      for (final li in ul.children.where((e) => e.localName == 'li')) {
        final spans = _parseInline(li);
        if (spans.isNotEmpty) {
          items.add(InfoItem(spans: spans, level: level));
        }

        // Look for nested ul within this li
        dom.Element? nested;
        for (final child in li.children) {
          if (child.localName == 'ul' || child.localName == 'ol') {
            nested = child;
            break;
          }
        }
        if (nested != null) {
          parseList(nested, level + 1);
        }
      }
    }

    parseList(ul, 0);

    if (items.isEmpty) return null;
    return InfoBoxData(heading: heading, items: items);
  }
}
