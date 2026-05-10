import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_data.dart';
import 'package:upsc_ca_ui/shared/models/profile_data.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/data/repositories/dashboard_repository.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'package:upsc_ca_ui/core/utils/date_formatter.dart';

import 'package:upsc_ca_ui/core/utils/task_categorizer.dart';

class DashboardProvider with ChangeNotifier {
  DashboardData? _data;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  String? _syncStatus;
  bool _needsVajiramLogin = false;
  String? _lastViewedUrl;
  SharedPreferences? _prefs;
  
  // Pagination for completed tasks
  int _completedTasksPageSize = 10;
  int _completedTasksCurrentCount = 10;
  
  final DashboardRepository _repository = DashboardRepository();

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String? get syncStatus => _syncStatus;
  bool get needsVajiramLogin => _needsVajiramLogin;
  String? get lastViewedUrl => _lastViewedUrl;

  List<DashboardTask> get visibleCompletedTasks {
    if (_data == null) return [];
    return _data!.completedTasks.take(_completedTasksCurrentCount).toList();
  }

  bool get hasMoreCompletedTasks {
    if (_data == null) return false;
    return _data!.completedTasks.length > _completedTasksCurrentCount;
  }

  void loadMoreCompletedTasks() {
    if (hasMoreCompletedTasks) {
      _completedTasksCurrentCount += _completedTasksPageSize;
      notifyListeners();
    }
  }

  Map<String, dynamic>? get nextUnreadTaskAndArticle {
    final flattened = allArticlesFlattened;
    if (flattened.isEmpty) return null;

    // 1. Try to find the last viewed article if it's still uncompleted
    if (_lastViewedUrl != null) {
      try {
        return flattened.firstWhere((item) => (item['article'] as ArticleModel).url == _lastViewedUrl);
      } catch (_) {
        // Not found or already completed, fall through
      }
    }

    // 2. Otherwise, return the very first one in the sorted list (Latest unread)
    return flattened.first;
  }

  List<Map<String, dynamic>> get allArticlesFlattened {
    if (_data == null) return [];

    final result = <Map<String, dynamic>>[];
    
    // 1. Collect ALL uncompleted tasks across ALL categories
    final allUncompleted = _data!.allTasks.where((t) => !t.isFullyCompleted).toList();
    
    // 2. Sort tasks strictly by Date DESC (Latest First)
    allUncompleted.sort((a, b) => b.isoDate.compareTo(a.isoDate));
    
    for (var task in allUncompleted) {
      // 3. Filter only uncompleted articles
      final uncompletedArticles = task.articles.where((a) => !a.isCompleted).toList();
      if (uncompletedArticles.isEmpty) continue;

      // 4. Sort articles within the same task by source priority
      uncompletedArticles.sort((a, b) => _compareSources(a.source, b.source));

      for (var article in uncompletedArticles) {
        result.add({
          'task': task,
          'article': article,
        });
      }
    }
    return result;
  }

  List<Map<String, dynamic>> get allArticlesFlattenedWithCompleted {
    if (_data == null) return [];

    final result = <Map<String, dynamic>>[];
    
    // 1. Collect ALL tasks
    final allTasks = _data!.allTasks.toList();
    
    // 2. Sort tasks strictly by Date DESC (Latest First)
    allTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));
    
    for (var task in allTasks) {
      final articles = List<ArticleModel>.from(task.articles);
      if (articles.isEmpty) continue;

      // 3. Sort articles within the same task by source priority
      articles.sort((a, b) => _compareSources(a.source, b.source));

      for (var article in articles) {
        result.add({
          'task': task,
          'article': article,
        });
      }
    }
    return result;
  }

  Future<void> setLastViewedUrl(String url) async {
    if (_lastViewedUrl == url) return;
    _lastViewedUrl = url;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString('last_viewed_url', url);
    notifyListeners();
  }

  Future<void> _loadLastViewedUrl() async {
    _prefs ??= await SharedPreferences.getInstance();
    _lastViewedUrl = _prefs?.getString('last_viewed_url');
    notifyListeners();
  }

  int _compareSources(String? s1, String? s2) {
    const order = ['vajiram', 'vision ias', 'next ias', 'insights ias'];
    final source1 = s1?.toLowerCase() ?? '';
    final source2 = s2?.toLowerCase() ?? '';
    
    final i1 = order.indexOf(source1);
    final i2 = order.indexOf(source2);
    
    // If both not in list, sort alphabetically
    if (i1 == -1 && i2 == -1) return source1.compareTo(source2);
    
    // If only one not in list, it goes last
    if (i1 == -1) return 1;
    if (i2 == -1) return -1;
    
    return i1.compareTo(i2);
  }

  void setNeedsVajiramLogin(bool value) {
    _needsVajiramLogin = value;
    notifyListeners();
  }

  /// Syncs all configured article sources.
  Future<void> syncAllArticles({bool forceRefresh = false, bool isRetryAfterLogin = false}) async {
    _isSyncing = true;
    _syncStatus = isRetryAfterLogin ? 'Retrying sync after login...' : (forceRefresh ? 'Force refreshing sources...' : 'Starting sync...');
    notifyListeners();

    try {
      final profile = await ProfileService().getProfile();
      if (profile != null) {
        try {
          await _repository.syncAll(
            profile.startDate,
            forceRefresh: forceRefresh,
            onStatusUpdate: (status) {
              _syncStatus = status;
              notifyListeners();
            },
          );
        } catch (e) {
          if (e.toString().contains("LOGIN_REQUIRED")) {
            _needsVajiramLogin = true;
            _syncStatus = "[Vajiram] Login Required";
            notifyListeners();
          } else {
            rethrow;
          }
        }

        // Reload data after sync
        await loadDashboardData();
      } else {
        _error = "Profile not found. Please setup profile first.";
      }
    } catch (e) {
      _error = "Sync failed: $e";
    } finally {
      _isSyncing = false;
      _syncStatus = null;
      notifyListeners();
    }
  }

  /// Fetches dashboard data using the repository.
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadLastViewedUrl();
      _data = await _repository.getDashboardData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a custom task and reloads
  Future<void> addCustomTask(String date, String source, String title, String? url) async {
    final parsedDate = DateFormatter.parseAny(date);
    final isoDate = DateFormatter.toIso(parsedDate);

    final item = ArticleModel(
      title: title,
      source: source,
      url: url ?? "custom_${DateTime.now().millisecondsSinceEpoch}",
      date: isoDate,
      isCustom: true,
    );

    try {
      await _repository.addCustomTask(isoDate, item);
      await loadDashboardData();
    } catch (e) {
      _error = "Failed to add task: $e";
      notifyListeners();
    }
  }

  /// Updates the target exam date.
  Future<void> updateExamDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final profile = await ProfileService().getProfile();
      if (profile != null) {
        final updatedProfile = ProfileData(
          name: profile.name,
          startDate: profile.startDate,
          articleSources: profile.articleSources,
          quizSources: profile.quizSources,
          repetitionDays: profile.repetitionDays,
          availableDays: profile.availableDays,
          themeColorValue: profile.themeColorValue,
          examDate: date,
        );
        
        await ProfileService().saveProfileToCloud(user.uid, updatedProfile);
        await loadDashboardData();
      }
    } catch (e) {
      AppLogger.e("Error updating exam date", e);
    }
  }

  /// Marks an article as completed locally and in Firestore.
  Future<void> markArticleAsCompleted(DashboardTask task, ArticleModel article) async {
    if (article.isCompleted) return;

    final now = DateTime.now();
    final completedAt = now.toIso8601String();

    // 1. Update Local State IMMEDIATELY (Optimistic Update)
    if (_data != null) {
      final updatedArticles = task.articles.map((a) {
        if (a.url == article.url) {
          return a.copyWith(isCompleted: true, completedAt: completedAt);
        }
        return a;
      }).toList();

      final articlesDone = updatedArticles.where((a) => a.isCompleted).length;
      final updatedTask = task.copyWith(
        articles: updatedArticles,
        articlesDone: articlesDone,
      );

      // Final categorization logic unified
      final allTasks = _data!.allTasks.map((t) => t.date == task.date ? updatedTask : t).toList();
      _data = TaskCategorizer.categorize(allTasks: allTasks, daysLeft: _data!.daysLeft);
      
      notifyListeners();
    }

    // 2. Sync to Firestore in the background
    final targetService = _repository.getSyncServiceForSource(article.source, isCustom: article.isCustom);

    if (targetService != null) {
      final isoDate = DateFormatter.toIso(DateFormatter.parseAny(task.date));
      try {
        await targetService.updateArticleStatus(isoDate, article.url!, true, completedAt: completedAt);
      } catch (e) {
        AppLogger.e('[DashboardProvider] Firestore sync failed', e);
      }
    }
  }

  /// Marks a quiz as completed locally and in Firestore.
  Future<void> markQuizAsCompleted(DashboardTask task, QuizModel quiz) async {
    if (quiz.isCompleted) return;

    final now = DateTime.now();
    final completedAt = now.toIso8601String();

    // 1. Update Local State IMMEDIATELY (Optimistic Update)
    if (_data != null) {
      final updatedQuizzes = task.quizzes.map((q) {
        if (q.title == quiz.title && q.source == quiz.source) {
          return q.copyWith(isCompleted: true, completedAt: completedAt);
        }
        return q;
      }).toList();

      final quizzesDone = updatedQuizzes.where((q) => q.isCompleted).length;
      final updatedTask = task.copyWith(
        quizzes: updatedQuizzes,
        quizzesDone: quizzesDone,
      );

      final allTasks = _data!.allTasks.map((t) => t.date == task.date ? updatedTask : t).toList();
      _data = TaskCategorizer.categorize(allTasks: allTasks, daysLeft: _data!.daysLeft);
      
      notifyListeners();
    }

    // 2. Sync to Firestore in the background
    final targetService = _repository.getSyncServiceForSource(quiz.source);

    if (targetService != null) {
      final isoDate = DateFormatter.toIso(DateFormatter.parseAny(task.date));
      try {
        await targetService.updateQuizStatus(isoDate, quiz.title, true, completedAt: completedAt);
      } catch (e) {
        AppLogger.e('[DashboardProvider] Firestore sync failed for quiz', e);
      }
    }
  }
}
