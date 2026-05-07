import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import '../models/dashboard_data.dart';
import '../providers/dashboard_provider.dart';

class CommonWebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final DashboardTask? task;
  final QuizDetail? quiz;

  const CommonWebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.task,
    this.quiz,
  });

  @override
  State<CommonWebViewScreen> createState() => _CommonWebViewScreenState();
}

class _CommonWebViewScreenState extends State<CommonWebViewScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
          },
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
          "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36");

    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _controller.setBackgroundColor(isDark ? AppTheme.backgroundDeep : Colors.white);
  }

  Future<void> _launchExternal() async {
    final uri = Uri.parse(widget.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch browser')),
        );
      }
    }
  }

  QuizDetail? _findLatestQuiz(DashboardProvider provider, String date, QuizDetail originalQuiz) {
    if (provider.data == null) return null;
    try {
      final task = provider.data!.allTasks.firstWhere((t) => t.date == date);
      return task.quizzes.firstWhere((q) => q.title == originalQuiz.title && q.source == originalQuiz.source);
    } catch (_) {
      return null;
    }
  }

  Future<void> _markAsDone(BuildContext context, DashboardProvider provider) async {
    if (widget.task != null && widget.quiz != null) {
      await provider.markQuizAsCompleted(widget.task!, widget.quiz!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz marked as completed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDeep : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.backgroundDeep : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.url,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.white24 : Colors.black26,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (widget.quiz != null && widget.task != null)
            Consumer<DashboardProvider>(
              builder: (context, provider, _) {
                final currentQuiz = _findLatestQuiz(provider, widget.task!.date, widget.quiz!);
                final isDone = currentQuiz?.isCompleted ?? widget.quiz!.isCompleted;

                if (isDone) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  );
                }

                return TextButton(
                  onPressed: () => _markAsDone(context, provider),
                  child: Text(
                    'MARK AS DONE',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black87),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: Icon(Icons.open_in_new_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black87),
            onPressed: _launchExternal,
            tooltip: 'Open in Browser',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _isLoading
              ? LinearProgressIndicator(
                  value: _loadingProgress / 100.0,
                  backgroundColor: Colors.transparent,
                  color: primaryColor,
                  minHeight: 2,
                )
              : const SizedBox(height: 2),
        ),
      ),
      body: kIsWeb
          ? const Center(child: Text('WebView not supported on Web'))
          : WebViewWidget(
              controller: _controller,
              gestureRecognizers: {
                Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer()..onStart = (DragStartDetails details) {},
                ),
              },
            ),
    );
  }
}
