import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/features/reader/screens/article_reader_screen.dart';
import 'package:upsc_ca_ui/features/web_view/screens/web_view_screen.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';

import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/providers/dashboard_provider.dart';

enum ReadingPreference {
  reader,
  internalBrowser;

  static ReadingPreference fromString(String value) {
    switch (value) {
      case 'reader':
        return ReadingPreference.reader;
      case 'internal_browser':
      default:
        return ReadingPreference.internalBrowser;
    }
  }

  String toValue() {
    switch (this) {
      case ReadingPreference.internalBrowser:
        return 'internal_browser';
      case ReadingPreference.reader:
        return 'reader';
    }
  }

  String get displayName {
    switch (this) {
      case ReadingPreference.internalBrowser:
        return 'In-App Browser';
      case ReadingPreference.reader:
        return 'Reader Mode';
    }
  }
}

class LinkLauncherUtils {
  static Future<void> launchArticle({
    required BuildContext context,
    required ArticleModel article,
    required String preference,
    DashboardTask? task,
  }) async {
    final url = article.url;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No URL available for this article')),
      );
      return;
    }

    // Custom articles or quizzes always open in Internal Browser if they are custom tasks
    if (article.isCustom && task != null) {
      unawaited(Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: url,
            title: article.title,
            task: task,
            article: article,
          ),
        ),
      ));
      return;
    }

    final mode = ReadingPreference.fromString(preference);

    switch (mode) {
      case ReadingPreference.reader:
        unawaited(Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleReaderScreen(
              initialUrl: url,
            ),
          ),
        ));
        break;
      case ReadingPreference.internalBrowser:
        unawaited(Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(
              url: url,
              title: article.title,
              task: task,
              article: article,
            ),
          ),
        ));
        break;
    }
  }

  static Future<void> launchQuiz({
    required BuildContext context,
    required QuizModel quiz,
    required String preference,
    required DashboardTask task,
  }) async {
    final url = quiz.url;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No URL available for this quiz')),
      );
      return;
    }

    final mode = ReadingPreference.fromString(preference);

    // Quizzes always open in the in-app browser (WebViewScreen)
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: url,
          title: quiz.title,
          task: task,
          quiz: quiz,
        ),
      ),
    ));
  }

  static Future<void> _launchCustomTabs(BuildContext context, String url) async {
    final theme = Theme.of(context);
    try {
      await custom_tabs.launchUrl(
        Uri.parse(url),
        customTabsOptions: custom_tabs.CustomTabsOptions(
          colorSchemes: custom_tabs.CustomTabsColorSchemes.defaults(
            toolbarColor: theme.colorScheme.surface,
          ),
          shareState: custom_tabs.CustomTabsShareState.on,
          urlBarHidingEnabled: true,
          showTitle: true,
          closeButton: custom_tabs.CustomTabsCloseButton(
            icon: custom_tabs.CustomTabsCloseButtonIcons.back,
          ),
        ),
        safariVCOptions: custom_tabs.SafariViewControllerOptions(
          preferredBarTintColor: theme.colorScheme.surface,
          preferredControlTintColor: theme.colorScheme.primary,
          barCollapsingEnabled: true,
          dismissButtonStyle: custom_tabs.SafariViewControllerDismissButtonStyle.close,
        ),
      );
    } catch (e) {
      AppLogger.e('Could not launch Custom Tabs', e);
      // Fallback to external browser if custom tabs fail
      final Uri uri = Uri.parse(url);
      if (!await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch browser')),
          );
        }
      }
    }
  }
}
