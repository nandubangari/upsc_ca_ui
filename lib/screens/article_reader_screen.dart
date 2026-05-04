import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/article_content.dart';
import '../services/article_parser_service.dart';
import '../theme/app_theme.dart';

class ArticleReaderScreen extends StatefulWidget {
  final String url;
  final String? initialTitle;

  const ArticleReaderScreen({super.key, required this.url, this.initialTitle});

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  final ArticleParserService _parserService = ArticleParserService();
  late Future<ArticleContent> _articleFuture;
  SelectedContent? _selectedContent;

  @override
  void initState() {
    super.initState();
    _articleFuture = _parserService.fetchAndParseArticle(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.backgroundDeep : Colors.white;
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenWidth = mediaQuery.size.width;
    // Lower threshold to ensure tablets and large phones trigger multi-column
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

          // Use initialTitle if available and the extracted title is generic
          final displayTitle = (article.title == 'VisionIAS Article' || article.title == 'Untitled') 
              ? (widget.initialTitle ?? article.title) 
              : (widget.initialTitle ?? article.title); // Prefer initialTitle if passed as it's often more refined from the dashboard
          
          return Scaffold(
            backgroundColor: backgroundColor,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Sticky Title at the very top
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

                // 2. Non-sticky Metadata (Subtitle and Date) below the sticky title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPadding, 4, hPadding, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Changed from center to start
                      children: [
                        if (article.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              article.subtitle!,
                              textAlign: TextAlign.left, // Changed from center to left
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
                            textAlign: TextAlign.left, // Changed from center to left
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

                // 3. Scrollable Content Area
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
                          // Image (Uncropped)
                          if (article.imageUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  article.imageUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          // Content Blocks
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
        Center(
          child: Container(
            width: 40,
            height: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        const SizedBox(height: 40),
        if (article.source != null)
          Center(
            child: InkWell(
              onTap: () => _launchUrl(article.source!.url),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'VIEW ORIGINAL SOURCE',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
          ),
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
        // Standardized Google Maps Search URL for better compatibility
        url = 'https://www.google.com/maps/search/?api=1&query=$encodedText';
        title = 'TERRAIN & GEOGRAPHY';
        break;
    }

    if (url.isNotEmpty) {
      _showResultBottomSheet(url, title);
    }
  }

  void _showResultBottomSheet(String url, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('intent://') ||
                request.url.startsWith('geo:') ||
                request.url.startsWith('maps:')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36")
      ..setBackgroundColor(isDark ? AppTheme.backgroundDeep : Colors.white);

    controller.loadRequest(Uri.parse(url));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.backgroundDeep : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new, size: 20),
                            onPressed: () => _launchUrl(url),
                            tooltip: 'Open in Browser',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: kIsWeb
                    ? const Center(child: Text('WebView not supported on Web'))
                    : WebViewWidget(
                        controller: controller,
                        gestureRecognizers: {
                          Factory<VerticalDragGestureRecognizer>(
                            () => VerticalDragGestureRecognizer()
                              ..onStart = (DragStartDetails details) {},
                          ),
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentBlock(BuildContext context, ContentBlock block, bool isTablet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (block.type) {
      case ContentBlockType.p:
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            block.data as String,
            style: TextStyle(
              color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF111111),
              fontSize: isTablet ? 19 : 17,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      case ContentBlockType.ul:
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: (block.data as List<ListItem>)
                .map((item) => _buildListItem(context, item, isTablet))
                .toList(),
          ),
        );
      case ContentBlockType.h3:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  (block.data as String).toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ],
          ),
        );
      case ContentBlockType.table:
        return _buildTableBlock(context, block.data as List<List<String>>, isTablet);
      case ContentBlockType.callout:
        return _buildCalloutBlock(context, block.data as List<ContentBlock>, isTablet);
      case ContentBlockType.image:
        return _buildInlineImage(context, block.data as String);
    }
    return const SizedBox.shrink();
  }

  Widget _buildInlineImage(BuildContext context, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildCalloutBlock(BuildContext context, List<ContentBlock> innerBlocks, bool isTablet) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Side Accent Bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: primaryColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12), // Bottom padding reduced since blocks have bottom padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: innerBlocks.map((b) => _buildContentBlock(context, b, isTablet)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableBlock(BuildContext context, List<List<String>> tableData, bool isTablet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 32, top: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: tableData.asMap().entries.map((entry) {
              final rowIndex = entry.key;
              final row = entry.value;
              final isHeader = rowIndex == 0;
              
              return Container(
                decoration: BoxDecoration(
                  color: isHeader 
                    ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))
                    : null,
                  border: Border(
                    bottom: rowIndex == tableData.length - 1 
                        ? BorderSide.none 
                        : BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                  ),
                ),
                child: Row(
                  children: row.map((cell) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    constraints: const BoxConstraints(minWidth: 100, maxWidth: 300),
                    child: Text(
                      cell,
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 13,
                        fontWeight: isHeader ? FontWeight.w800 : FontWeight.w400,
                        color: isHeader 
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.white70 : Colors.black87),
                        height: 1.4,
                      ),
                    ),
                  )).toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, ListItem item, bool isTablet, {int depth = 0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 12, left: depth * (isTablet ? 28.0 : 20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: isTablet ? 14 : 12, right: 16),
                child: Container(
                  width: 8,
                  height: 1, 
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: depth == 0 ? 0.8 : 0.4),
                ),
              ),
              Expanded(
                child: Text(
                  item.text,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF111111),
                    fontSize: isTablet ? 18 : 16,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          if (item.children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: item.children
                    .map((child) => _buildListItem(context, child, isTablet, depth: depth + 1))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch source URL')),
        );
      }
    }
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double opacity = (1 - (shrinkOffset / maxExtent)).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.98),
        boxShadow: [
          if (shrinkOffset > 10)
            BoxShadow(
              color: (isDark ? Colors.black : Colors.black12).withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(padding, topPadding + 10, padding, 10),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shrinkOffset < 20)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'UPSC CURRENT AFFAIRS',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: shrinkOffset > (maxExtent - minExtent - 20) ? 1 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: shrinkOffset > (maxExtent - minExtent - 20)
                  ? (isTablet ? 18 : 16) 
                  : (isTablet ? 26 : 22),
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => (isTablet ? 160 : 140) + topPadding;

  @override
  double get minExtent => (isTablet ? 80 : 70) + topPadding;

  @override
  bool shouldRebuild(covariant _StickyTitleDelegate oldDelegate) {
    return title != oldDelegate.title || 
           isDark != oldDelegate.isDark || 
           topPadding != oldDelegate.topPadding;
  }
}
