import 'dart:async';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/article_content.dart';
import 'package:upsc_ca_ui/shared/widgets/article_content_widgets.dart';
import 'package:upsc_ca_ui/shared/widgets/article_summary.dart';
import 'package:upsc_ca_ui/shared/widgets/article_tag.dart';





import 'package:upsc_ca_ui/providers/dashboard_provider.dart';
import 'package:upsc_ca_ui/core/theme/app_theme.dart';
import 'package:upsc_ca_ui/data/parsers/article_parser.dart';

class ArticleReaderScreen extends StatefulWidget {
  final String? initialUrl;

  const ArticleReaderScreen({
    super.key, 
    this.initialUrl,
  });

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  late PageController _pageController;
  bool _isInitialized = false;
  DashboardProvider? _provider;
  List<Map<String, dynamic>> _stableFlattened = [];

  @override
  void initState() {
    super.initState();
    // Temporary controller, will be replaced once data is ready
    _pageController = PageController();
    
    // Notify provider that reader is open to pause background tasks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().setReaderOpen(true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 🟢 FIX: Cache provider reference to safely use it in dispose()
    _provider = Provider.of<DashboardProvider>(context, listen: false);
    
    // 🟢 AGGRESSIVE FIX: Initialize the stable list and controller here, NOT in build()
    // This prevents the PageView from rebuilding/jumping when articles are marked completed.
    if (!_isInitialized) {
      final provider = _provider!;
      
      // Always use the list that includes completed items for PageView index stability
      _stableFlattened = provider.allArticlesFlattenedWithCompleted;
      
      if (_stableFlattened.isNotEmpty) {
        int startIndex = 0;
        String? targetUrl = widget.initialUrl;
        
        // If no explicit URL was passed, try to resume from the last viewed one
        if (targetUrl == null && provider.lastViewedUrl != null) {
          targetUrl = provider.lastViewedUrl;
        }

        if (targetUrl != null) {
          startIndex = _stableFlattened.indexWhere((item) {
            final art = item['article'] as ArticleModel;
            return art.url == targetUrl;
          });
          
          if (startIndex == -1) {
            AppLogger.d('DEBUG: [ArticleReader] Target URL not found in flattened list: $targetUrl');
            // If the specific URL isn't found, try to find the FIRST UNREAD article
            startIndex = _stableFlattened.indexWhere((item) => !(item['article'] as ArticleModel).isCompleted);
            if (startIndex == -1) startIndex = 0;
          } else {
            AppLogger.d('DEBUG: [ArticleReader] Found Target URL at index $startIndex: $targetUrl');
          }
        } else {
          // If no URL at all, find the first unread
          startIndex = _stableFlattened.indexWhere((item) => !(item['article'] as ArticleModel).isCompleted);
          if (startIndex == -1) startIndex = 0;
        }
        
        // Dispose old and create new with correct page
        _pageController.dispose();
        _pageController = PageController(initialPage: startIndex);
        _isInitialized = true;

        // Record initial last viewed
        final article = _stableFlattened[startIndex]['article'] as ArticleModel;
        if (article.url != null) {
          unawaited(provider.setLastViewedUrl(article.url!));
        }
      }
    }
  }

  @override
  void dispose() {
    // 🟢 FIX: Wrap in post-frame callback to avoid "setState during build" errors
    // when the provider notifies listeners (like the Dashboard) during unmounting.
    final provider = _provider;
    if (provider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.setReaderOpen(false);
      });
    }
    _pageController.dispose();
    super.dispose();
  }

  void _markAsCompleted(DashboardTask task, ArticleModel article) {
    if (!article.isCompleted) {
      unawaited(context.read<DashboardProvider>().markArticleAsCompleted(task, article));
    }
  }

  void _goToNextPage(DashboardTask task, ArticleModel article, int currentIndex, int totalCount) {
    if (_pageController.hasClients) {
      _markAsCompleted(task, article);
      if (currentIndex < totalCount - 1) {
        unawaited(_pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        ));
      }
    }
  }

  void _goToPreviousPage() {
    if (_pageController.hasClients && _pageController.page! > 0) {
      unawaited(_pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.backgroundDeep : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (_stableFlattened.isEmpty) {
            // If data wasn't ready during didChangeDependencies, it might be empty.
            // But usually, the reader is opened AFTER data is ready on the dashboard.
            return const Center(child: Text('No articles available'));
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _stableFlattened.length,
            onPageChanged: (index) {
              final article = _stableFlattened[index]['article'] as ArticleModel;
              if (article.url != null) {
                unawaited(provider.setLastViewedUrl(article.url!));
              }
            },
            itemBuilder: (context, index) {
              final item = _stableFlattened[index];
              final task = item['task'] as DashboardTask;
              final article = item['article'] as ArticleModel;
              
              if (article.url == null) return const SizedBox.shrink();

              return ArticleContentView(
                key: ValueKey('view-${article.url}'), // AGGRESSIVE STABILITY: Unique key per URL
                url: article.url!,
                initialTitle: article.title,
                onNextArticle: () => _goToNextPage(task, article, index, _stableFlattened.length),
                onPreviousArticle: _goToPreviousPage,
              );
            },
          );
        },
      ),
    );
  }
}

class ArticleContentView extends StatefulWidget {
  final String url;
  final String? initialTitle;
  final VoidCallback? onNextArticle;
  final VoidCallback? onPreviousArticle;

  const ArticleContentView({
    super.key, 
    required this.url, 
    this.initialTitle,
    this.onNextArticle,
    this.onPreviousArticle,
  });

  @override
  State<ArticleContentView> createState() => _ArticleContentViewState();
}

class _ArticleContentViewState extends State<ArticleContentView> {
  final ArticleParser _parser = ArticleParser();
  late Future<List<ArticleContent>> _articleFuture;
  SelectedContent? _selectedContent;
  bool _isTransitioning = false;

  // Caching for flattened items to avoid expensive re-calculation on every rebuild
  List<ArticleContent>? _cacheArticles;
  String? _cacheInitialTitle;
  List<dynamic>? _cacheFlattenedItems;
  String? _cacheMainTitle;

  @override
  void initState() {
    super.initState();
    _articleFuture = _parser.fetchAndParseArticle(widget.url);
  }

  void _updateCache(List<ArticleContent> articles) {
    if (_cacheArticles == articles && _cacheInitialTitle == widget.initialTitle) {
      return;
    }

    _cacheArticles = articles;
    _cacheInitialTitle = widget.initialTitle;

    final mainDisplayTitle = _getBestTitle(widget.initialTitle, articles.first.title, articles.length > 1);
    _cacheMainTitle = mainDisplayTitle;
    
    String? overrideSubtitle;
    if (articles.length == 1) {
      if (widget.initialTitle != null && widget.initialTitle != mainDisplayTitle) {
        overrideSubtitle = widget.initialTitle;
      } else if (articles.first.title != mainDisplayTitle) {
        overrideSubtitle = articles.first.title;
      }
    } else {
      if (widget.initialTitle != null && widget.initialTitle != mainDisplayTitle) {
        overrideSubtitle = widget.initialTitle;
      }
    }

    // Flatten articles and their blocks for virtualized rendering
    final List<dynamic> flattenedItems = [];
    
    // Header items
    flattenedItems.add({'type': 'subtitle', 'data': overrideSubtitle ?? articles.first.subtitle});
    if (articles.first.date != null) {
      flattenedItems.add({'type': 'date', 'data': articles.first.date});
    }
    
    // Note: topPadding is orientation-dependent, so we'll handle the spacer separately or just include a type
    flattenedItems.add({'type': 'top_padding'});

    for (var article in articles) {
      if (article.title.isNotEmpty && article.title != mainDisplayTitle) {
        flattenedItems.add({'type': 'section_title', 'data': article.title});
      }
      if (article.tags != null && article.tags!.isNotEmpty) {
        flattenedItems.add({'type': 'tags', 'data': article.tags});
      }
      if (article.imageUrl != null) {
        flattenedItems.add({'type': 'main_image', 'data': article.imageUrl});
      }
      if (article.summary != null && article.summary!.isNotEmpty) {
        flattenedItems.add({'type': 'summary', 'data': article.summary});
      }
      
      for (var block in article.content) {
        flattenedItems.add({'type': 'block', 'data': block});
      }
      
      flattenedItems.add({'type': 'separator'});
    }

    // Footer items
    if (articles.last.source != null) {
      flattenedItems.add({'type': 'footer_source', 'data': articles.last.source});
    }
    if (articles.last.sources != null && articles.last.sources!.isNotEmpty) {
      for (var src in articles.last.sources!) {
        flattenedItems.add({'type': 'footer_extra_source', 'data': src});
      }
    }
    flattenedItems.add({'type': 'footer_swipe_hint'});
    flattenedItems.add({'type': 'footer_end_line'});
    flattenedItems.add({'type': 'bottom_spacer'});

    _cacheFlattenedItems = flattenedItems;
  }

  void _handleNext() {
    if (_isTransitioning) return;
    _isTransitioning = true;
    AppLogger.d('DEBUG: [ArticleReader] Triggering NEXT');
    widget.onNextArticle?.call();
    unawaited(Future.delayed(const Duration(milliseconds: 1000), () => _isTransitioning = false));
  }

  void _handlePrevious() {
    if (_isTransitioning) return;
    _isTransitioning = true;
    AppLogger.d('DEBUG: [ArticleReader] Triggering PREVIOUS');
    widget.onPreviousArticle?.call();
    unawaited(Future.delayed(const Duration(milliseconds: 1000), () => _isTransitioning = false));
  }

  @override
  void didUpdateWidget(ArticleContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _articleFuture = _parser.fetchAndParseArticle(widget.url);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.backgroundDeep : Colors.white;
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 500;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<List<ArticleContent>>(
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
            AppLogger.d('ERROR: [ArticleReader] Snapshot error: ${snapshot.error}');
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
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          final articles = snapshot.data!;
          _updateCache(articles);

          final isPortrait = mediaQuery.orientation == Orientation.portrait;
          final double hPadding = isPortrait ? 16.0 : 24.0;
          final topPadding = isLandscape ? 12.0 : 20.0;

          final mainDisplayTitle = _cacheMainTitle!;
          final flattenedItems = _cacheFlattenedItems!;

          return Scaffold(
            backgroundColor: backgroundColor,
            body: SelectionArea(
              onSelectionChanged: (content) {
                // 🟢 FIX: Avoid setState during build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _selectedContent = content);
                });
              },
              contextMenuBuilder: (context, selectableRegionState) => 
                  _buildContextMenu(context, selectableRegionState),
              child: VisibilityDetector(
                key: Key('article-${widget.url}-${flattenedItems.length}'), // 🟢 FIX: More unique key to avoid duplicates
                onVisibilityChanged: (info) {
                  if (info.visibleFraction <= 0) {
                    // Page is offscreen, clear the heavy flattened cache to save RAM
                    // It will be re-calculated automatically if the user scrolls back
                    _cacheFlattenedItems = null;
                    _cacheArticles = null;
                  }
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      final metrics = notification.metrics;
                      final overscrollBottom = metrics.pixels - metrics.maxScrollExtent;
                      final overscrollTop = -metrics.pixels;

                      if (overscrollBottom > 80) {
                        _handleNext();
                      } else if (overscrollTop > 80) {
                        _handlePrevious();
                      }
                    } else if (notification is ScrollEndNotification) {
                      final metrics = notification.metrics;
                      if (metrics.atEdge) {
                        final velocity = notification.dragDetails?.primaryVelocity ?? 0;
                        if (metrics.pixels >= metrics.maxScrollExtent && velocity < -500) {
                          _handleNext();
                        } else if (metrics.pixels <= 0 && velocity > 500) {
                          _handlePrevious();
                        }
                      }
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      // 🟢 AGGRESSIVE FIX: Use SliverAppBar instead of custom delegate for 100% SliverGeometry stability
                      SliverAppBar(
                        pinned: true,
                        automaticallyImplyLeading: false,
                        backgroundColor: backgroundColor,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        toolbarHeight: isTablet ? 110 : 90,
                        titleSpacing: 0,
                        title: Container(
                          padding: EdgeInsets.fromLTRB(hPadding, mediaQuery.padding.top, hPadding, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  mainDisplayTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: isTablet ? 20 : 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => unawaited(_launchUrl(widget.url)),
                                icon: Icon(
                                  Icons.open_in_new_rounded,
                                  size: isTablet ? 20 : 18,
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                                ),
                                tooltip: 'Open in Browser',
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: hPadding),
                        sliver: SliverList.builder(
                          itemCount: flattenedItems.length,
                          itemBuilder: (context, index) {
                            final item = flattenedItems[index];
                            if (item['type'] == 'top_padding') return SizedBox(height: topPadding);
                            if (item['type'] == 'bottom_spacer') return const SizedBox(height: 40.0);
                            return RepaintBoundary(
                              child: _buildFlattenedItem(context, item, isDark, isTablet),
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlattenedItem(BuildContext context, Map<String, dynamic> item, bool isDark, bool isTablet) {
    switch (item['type']) {
      case 'subtitle':
        final text = item['data'] as String?;
        if (text == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            text,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
              fontSize: isTablet ? 19 : 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        );
      case 'date':
        final text = item['data'] as String;
        return Text(
          text.toUpperCase(),
          textAlign: TextAlign.left,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: isTablet ? 11 : 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        );
      case 'spacer':
        return SizedBox(height: item['height']);
      case 'section_title':
        return Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          child: Text(
            item['data'],
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      case 'tags':
        final tags = item['data'] as List<String>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map<Widget>((tag) => ArticleTag(tag: tag)).toList(),
          ),
        );
      case 'main_image':
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ZoomableArticleImage(
            imageUrl: item['data'],
            isTablet: isTablet,
            fit: BoxFit.cover,
            displayHeight: 200,
          ),
        );
      case 'summary':
        return ArticleSummary(summary: item['data'], isTablet: isTablet);
      case 'block':
        return _buildContentBlock(context, item['data'], isTablet);
      case 'separator':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Container(
              width: 80,
              height: 1,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
        );
      case 'footer_source':
        final source = item['data'];
        return Center(
          child: InkWell(
            onTap: () => unawaited(_launchUrl(source.url)),
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
        );
      case 'footer_extra_source':
        final url = item['data'] as String;
        return Center(
          child: InkWell(
            onTap: () => unawaited(_launchUrl(url)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                url.length > 40 ? '${url.substring(0, 40)}...' : url,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        );
      case 'footer_swipe_hint':
        return Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 40),
          child: Column(
            children: [
              Icon(Icons.keyboard_double_arrow_up_rounded, 
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), 
                size: 20
              ),
              const SizedBox(height: 8),
              Text(
                'SWIPE UP FOR NEXT',
                style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        );
      case 'footer_end_line':
        return Center(
          child: Container(
            width: 40,
            height: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
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
    unawaited(showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => _BottomSheetWebView(url: url, title: title),
      ),
    ));
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
            child: ArticleRichText(spans: data, isTablet: isTablet, fontSize: 17),
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
          children: items.map((item) => ArticleListItemWidget(item: item, isTablet: isTablet)).toList(),
        );

      case ContentBlockType.table:
        final rows = block.data as List<List<String>>;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ArticleTable(rows: rows),
        );

      case ContentBlockType.image:
        final data = block.data;
        final ImageData imageData;
        if (data is String) {
          imageData = ImageData(url: data);
        } else if (data is ImageData) {
          imageData = data;
        } else {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ZoomableArticleImage(
            imageUrl: imageData.url,
            width: imageData.width,
            height: imageData.height,
            isTablet: isTablet,
            fit: BoxFit.contain,
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
      case ContentBlockType.infobox:
        final data = block.data as InfoBoxData;
        return ArticleInfoBox(data: data, isTablet: isTablet);
    }
  }

  String _getBestTitle(String? initial, String parsed, bool hasMultipleArticles) {
    if (hasMultipleArticles && initial != null && initial.isNotEmpty) {
      return initial;
    }

    final genericPlaceholders = [
      'visionias article',
      'vajiram ias article',
      'nextias article',
      'insightsias article',
      'article',
      'untitled',
    ];

    final parsedLower = parsed.toLowerCase().trim();

    if (parsedLower.isNotEmpty && !genericPlaceholders.contains(parsedLower)) {
      return parsed;
    }

    return initial ?? parsed;
  }
}

class _BottomSheetWebView extends StatelessWidget {
  final String url;
  final String title;

  const _BottomSheetWebView({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: SelectionWebView(url: url),
          ),
        ],
      ),
    );
  }
}

class SelectionWebView extends StatefulWidget {
  final String url;
  const SelectionWebView({super.key, required this.url});

  @override
  State<SelectionWebView> createState() => _SelectionWebViewState();
}

class _SelectionWebViewState extends State<SelectionWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void dispose() {
    // Aggressively clear resources to release native memory
    unawaited(_controller.loadRequest(Uri.parse('about:blank')));
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith('intent://') ||
                url.startsWith('geo:') ||
                url.startsWith('maps:') ||
                url.contains('market://') ||
                url.startsWith('tel:') ||
                url.startsWith('mailto:')) {
              AppLogger.d('DEBUG: [SelectionWebView] Blocking external redirect: $url');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _controller.setBackgroundColor(isDark ? AppTheme.backgroundDeep : Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}


























