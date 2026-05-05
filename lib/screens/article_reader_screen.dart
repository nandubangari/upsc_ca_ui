import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../models/article_content.dart';
import '../models/dashboard_data.dart';
import '../services/article_parser_service.dart';
import '../theme/app_theme.dart';

class ArticleReaderScreen extends StatefulWidget {
  final List<ArticleDetail> articles;
  final int initialIndex;

  const ArticleReaderScreen({
    super.key, 
    required this.articles, 
    required this.initialIndex,
  });

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.articles.length,
      itemBuilder: (context, index) {
        final articleDetail = widget.articles[index];
        return ArticleContentView(
          url: articleDetail.url!,
          initialTitle: articleDetail.title,
        );
      },
    );
  }
}

class ArticleContentView extends StatefulWidget {
  final String url;
  final String? initialTitle;

  const ArticleContentView({super.key, required this.url, this.initialTitle});

  @override
  State<ArticleContentView> createState() => _ArticleContentViewState();
}

class _ArticleContentViewState extends State<ArticleContentView> with AutomaticKeepAliveClientMixin {
  final ArticleParserService _parserService = ArticleParserService();
  late Future<ArticleContent> _articleFuture;
  SelectedContent? _selectedContent;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _articleFuture = _parserService.fetchAndParseArticle(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.backgroundDeep : Colors.white;
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 500;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<ArticleContent>(
        future: _articleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 1,
                ),
              ),
            );
          } else if (snapshot.hasError) {
            print('ERROR: [ArticleReader] Snapshot error: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'UNABLE TO LOAD CONTENT',
                      style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('DISMISS',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final article = snapshot.data!;
          final isPortrait = mediaQuery.orientation == Orientation.portrait;
          final double hPadding = isPortrait ? 16.0 : 24.0;
          final topPadding = isLandscape ? 12.0 : 20.0;

          final displayTitle = (article.title == 'VisionIAS Article' || article.title == 'Untitled') 
              ? (widget.initialTitle ?? article.title) 
              : (widget.initialTitle ?? article.title);
          
          return Scaffold(
            backgroundColor: backgroundColor,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTitleDelegate(
                    title: displayTitle,
                    isDark: isDark,
                    isTablet: isTablet,
                    backgroundColor: backgroundColor,
                    padding: hPadding,
                    topPadding: mediaQuery.padding.top,
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPadding, 4, hPadding, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              article.subtitle!,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                                fontSize: isTablet ? 19 : 17,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ),
                        if (article.date != null)
                          Text(
                            article.date!.toUpperCase(),
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: isTablet ? 11 : 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPadding, topPadding, hPadding, 80),
                  sliver: SliverToBoxAdapter(
                    child: SelectionArea(
                      onSelectionChanged: (content) => setState(() => _selectedContent = content),
                      contextMenuBuilder: (context, selectableRegionState) => 
                          _buildContextMenu(context, selectableRegionState),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (article.imageUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  article.imageUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ...article.content.map((block) => _buildContentBlock(context, block, isTablet)),
                          const SizedBox(height: 60),
                          _buildFooter(context, article, isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContextMenu(BuildContext context, SelectableRegionState selectableRegionState) {
    final List<ContextMenuButtonItem> buttonItems = selectableRegionState.contextMenuButtonItems;
    final String? selectedText = _selectedContent?.plainText;

    if (selectedText != null && selectedText.trim().isNotEmpty) {
      buttonItems.add(
        ContextMenuButtonItem(
          label: 'Ask Google',
          onPressed: () {
            ContextMenuController.removeAny();
            _handleSelectionAction('google', selectedText);
          },
        ),
      );
      buttonItems.add(
        ContextMenuButtonItem(
          label: 'Translate',
          onPressed: () {
            ContextMenuController.removeAny();
            _handleSelectionAction('translate', selectedText);
          },
        ),
      );
      buttonItems.add(
        ContextMenuButtonItem(
          label: 'Maps',
          onPressed: () {
            ContextMenuController.removeAny();
            _handleSelectionAction('maps', selectedText);
          },
        ),
      );
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: selectableRegionState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  Widget _buildFooter(BuildContext context, ArticleContent article, bool isDark) {
    return Column(
      children: [
        if (article.source != null)
          Center(
            child: InkWell(
              onTap: () => _launchUrl(article.source!.url),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'VIEW ORIGINAL SOURCE',
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 40,
            height: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  void _handleSelectionAction(String type, String text) {
    String url = '';
    String title = '';
    final cleanedText = text.trim().replaceAll(RegExp(r'\.+$'), '');
    final encodedText = Uri.encodeComponent(cleanedText);

    switch (type) {
      case 'google':
        url = 'https://www.google.com/search?q=$encodedText';
        title = 'GOOGLE SEARCH';
        break;
      case 'translate':
        url = 'https://translate.google.com/?sl=auto&tl=en&text=$encodedText&op=translate';
        title = 'TRANSLATE';
        break;
      case 'maps':
        url = 'https://www.google.com/maps/search/?api=1&query=$encodedText';
        title = 'TERRAIN & GEOGRAPHY';
        break;
    }

    if (url.isNotEmpty) {
      _showResultBottomSheet(url, title);
    }
  }

  void _showResultBottomSheet(String url, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: WebViewWidget(
                  controller: WebViewController()
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..loadRequest(Uri.parse(url)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  Widget _buildContentBlock(BuildContext context, ContentBlock block, bool isTablet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (block.type) {
      case ContentBlockType.h2:
      case ContentBlockType.h3:
        final text = block.data as String;
        return Padding(
          padding: const EdgeInsets.only(top: 32, bottom: 16),
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: isTablet ? 14 : 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        );
      case ContentBlockType.p:
        final data = block.data;
        if (data is List<InlineSpanData>) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildRichText(context, data, isTablet, isDark, 17),
          );
        } else if (data is String) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: HtmlWidget(
              data,
              textStyle: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.8),
                fontSize: isTablet ? 19 : 17,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }
        return const SizedBox.shrink();

      case ContentBlockType.ul:
        final items = block.data as List<ListItem>;
        return Column(
          children: items.map((item) => _buildListItem(context, item, isTablet, isDark)).toList(),
        );

      case ContentBlockType.table:
        final rows = block.data as List<List<String>>;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: _buildTable(context, rows, isDark),
        );

      case ContentBlockType.image:
        final imageUrl = block.data as String;
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        );
      case ContentBlockType.callout:
        final innerBlocks = block.data as List<ContentBlock>;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: innerBlocks.map((b) => _buildContentBlock(context, b, isTablet)).toList(),
          ),
        );
    }
  }

  Widget _buildListItem(BuildContext context, ListItem item, bool isTablet, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 12),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: _buildRichText(context, item.spans, isTablet, isDark, 16),
              ),
            ],
          ),
        ),
        if (item.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: item.children.map((child) => _buildListItem(context, child, isTablet, isDark)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRichText(BuildContext context, List<InlineSpanData> spans, bool isTablet, bool isDark, double fontSize) {
    return RichText(
      text: TextSpan(
        children: spans.map((s) {
          final color = _parseColor(s.color);
          return TextSpan(
            text: s.text,
            style: TextStyle(
              color: color ?? (isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.8)),
              fontSize: isTablet ? fontSize + 2 : fontSize,
              fontWeight: s.isBold ? FontWeight.bold : FontWeight.normal,
              height: 1.6,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<List<String>> rows, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Table(
        border: TableBorder.symmetric(inside: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
        children: rows.map((row) {
          return TableRow(
            children: row.map((cell) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  cell,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Color? _parseColor(String? cssColor) {
    if (cssColor == null) return null;
    final cleanColor = cssColor.trim().toLowerCase();
    
    if (cleanColor == "red") return Colors.red;
    if (cleanColor == "blue") return Colors.blue;
    if (cleanColor == "green") return Colors.green;
    
    if (cleanColor.startsWith("#")) {
      try {
        final hex = cleanColor.replaceFirst("#", "");
        if (hex.length == 6) {
          return Color(int.parse("FF$hex", radix: 16));
        } else if (hex.length == 3) {
          final fullHex = hex.split('').map((e) => '$e$e').join();
          return Color(int.parse("FF$fullHex", radix: 16));
        }
      } catch (_) {}
    }
    return null;
  }
}

class _StickyTitleDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final bool isDark;
  final bool isTablet;
  final Color backgroundColor;
  final double padding;
  final double topPadding;

  _StickyTitleDelegate({
    required this.title,
    required this.isDark,
    required this.isTablet,
    required this.backgroundColor,
    required this.padding,
    required this.topPadding,
  });

  @override
  double get minExtent => topPadding + (isTablet ? 70 : 60);
  @override
  double get maxExtent => topPadding + (isTablet ? 120 : 100);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / maxExtent;
    final titleSize = Tween<double>(begin: isTablet ? 26 : 22, end: isTablet ? 18 : 16).transform(progress.clamp(0, 1));
    
    return Container(
      color: backgroundColor.withValues(alpha: progress.clamp(0.0, 0.95)),
      padding: EdgeInsets.fromLTRB(padding, topPadding + 10, padding, 10),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        maxLines: progress > 0.5 ? 1 : 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: titleSize,
          fontWeight: FontWeight.w900,
          height: 1.15,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTitleDelegate oldDelegate) {
    return oldDelegate.title != title || oldDelegate.isDark != isDark;
  }
}
