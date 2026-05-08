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
  
  final DashboardRepository _repository = DashboardRepository();

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String? get syncStatus => _syncStatus;
  bool get needsVajiramLogin => _needsVajiramLogin;

  Map<String, dynamic>? get nextUnreadTaskAndArticle {
    if (_data == null) return null;

    for (var task in _data!.allTasks) {
      if (task.articles.isEmpty) continue;
      for (var article in task.articles) {
        if (!article.isCompleted) {
          return {
            'task': task,
            'article': article,
          };
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get allArticlesFlattened {
    if (_data == null) return [];

    final flattened = <Map<String, dynamic>>[];
    for (var task in _data!.allTasks) {
      final sortedArticles = List<ArticleModel>.from(task.articles)
        ..sort((a, b) => a.isCompleted == b.isCompleted ? 0 : (a.isCompleted ? 1 : -1));

      for (var article in sortedArticles) {
        flattened.add({
          'task': task,
          'article': article,
        });
      }
    }
    return flattened;
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
