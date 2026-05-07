import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../models/profile_data.dart';
import '../services/dashboard_service.dart';
import '../services/synced_dashboard_service.dart';
import '../services/sync/vajiram_sync_service.dart';
import '../services/sync/vision_sync_service.dart';
import '../services/sync/next_ias_sync_service.dart';
import '../services/sync/insights_ias_sync_service.dart';
import '../services/sync/chahal_sync_service.dart';
import '../services/sync/drishti_sync_service.dart';
import '../services/sync/insights_quiz_sync_service.dart';
import '../services/profile_service.dart';
import '../services/sync/base_sync_service.dart';
import '../core/utils/date_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardProvider with ChangeNotifier {
  DashboardData? _data;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  String? _syncStatus;
  bool _needsVajiramLogin = false;
  DashboardService _service = SyncedDashboardService(EmptyDashboardService());
  final VajiramSyncService _vajiramSync = VajiramSyncService();
  final VisionSyncService _visionSync = VisionSyncService();
  final NextIASSyncService _nextIasSync = NextIASSyncService();
  final InsightsIASSyncService _insightsIasSync = InsightsIASSyncService();
  final ChahalSyncService _chahalSync = ChahalSyncService();
  final DrishtiSyncService _drishtiSync = DrishtiSyncService();
  final InsightsQuizSyncService _insightsQuizSync = InsightsQuizSyncService();

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String? get syncStatus => _syncStatus;
  bool get needsVajiramLogin => _needsVajiramLogin;
  DashboardService get service => _service;

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
      // 🟢 Sort articles within each task by completion status to match UI sorting
      // This is crucial for index-to-article stability
      final sortedArticles = List<ArticleDetail>.from(task.articles)
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

  /// Updates the service source and reloads data.
  void setService(DashboardService newService) {
    _service = newService;
    loadDashboardData();
  }

  /// Switches to Firestore service.
  void switchToFirestore() {
    setService(FirestoreDashboardService());
  }

  /// Switches to Local service (empty base, synced Vajiram data).
  void switchToLocal() {
    setService(SyncedDashboardService(EmptyDashboardService()));
  }

  void setNeedsVajiramLogin(bool value) {
    _needsVajiramLogin = value;
    notifyListeners();
  }

  /// Syncs all configured article sources.
  Future<void> syncAllArticles({bool forceRefresh = false, bool isRetryAfterLogin = false}) async {
    _isSyncing = true;
    _syncStatus = isRetryAfterLogin ? 'Retrying sync after login...' : (forceRefresh ? 'Force refreshing sources...' : 'Starting sync...');
    debugPrint('DEBUG: [DashboardProvider] syncAllArticles called (forceRefresh: $forceRefresh, isRetry: $isRetryAfterLogin)');
    notifyListeners();

    try {
      final profile = await ProfileService().getProfile();
      if (profile != null) {
        // Sync Vajiram
        try {
          await _vajiramSync.syncArticles(
            startDate: profile.startDate,
            forceRefresh: forceRefresh,
            onStatusUpdate: (status) {
              _syncStatus = "[Vajiram] $status";
              notifyListeners();
            },
          );
        } catch (e) {
          if (e.toString().contains("LOGIN_REQUIRED")) {
            _needsVajiramLogin = true;
            _syncStatus = "[Vajiram] Login Required";
            notifyListeners();
            // We don't rethrow here to allow other sources to sync if possible, 
            // but we stop the Vajiram specific sync and notify UI.
          } else {
            rethrow;
          }
        }

        // Sync VisionIAS
        await _visionSync.syncArticles(
          startDate: profile.startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) {
            _syncStatus = "[Vision] $status";
            notifyListeners();
          },
        );

        // Sync NextIAS
        await _nextIasSync.syncArticles(
          startDate: profile.startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) {
            _syncStatus = "[NextIAS] $status";
            notifyListeners();
          },
        );

        // Sync InsightsIAS
        await _insightsIasSync.syncArticles(
          startDate: profile.startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) {
            _syncStatus = "[InsightsIAS] $status";
            notifyListeners();
          },
        );

        // Sync Chahal Academy
        await _chahalSync.syncQuizzes(
          startDate: profile.startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) {
            _syncStatus = "[Chahal] $status";
            notifyListeners();
          },
        );

        // Sync Drishti IAS
        await _drishtiSync.syncRange(
          startDate: profile.startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) {
            _syncStatus = "[Drishti] $status";
            notifyListeners();
          },
        );

        // Sync InsightsIAS Quiz (includes QUED and CA)
        await _insightsQuizSync.syncRange(
          startDate: profile.startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) {
            _syncStatus = "[Insights Quiz] $status";
            notifyListeners();
          },
        );

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

  /// Fetches dashboard data using the current service.
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _service.fetchDashboardData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
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
      debugPrint("Error updating exam date: $e");
    }
  }

  /// Marks an article as completed locally and in Firestore.
  Future<void> markArticleAsCompleted(DashboardTask task, ArticleDetail article) async {
    if (article.isCompleted) return;

    final now = DateTime.now();
    final completedAt = now.toIso8601String();
    debugPrint('DEBUG: [DashboardProvider] Marking article completed: ${article.title} at $completedAt');

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

      // Find which section the task belongs to and update it
      List<DashboardTask> updateList(List<DashboardTask> section) {
        return section.map((t) => t.date == task.date ? updatedTask : t).toList();
      }

      _data = DashboardData(
        daysLeft: _data!.daysLeft,
        todayTasks: updateList(_data!.todayTasks),
        inProgressTasks: updateList(_data!.inProgressTasks),
        notStartedTasks: updateList(_data!.notStartedTasks),
        completedTasks: updateList(_data!.completedTasks),
      );

      // Re-categorize tasks if completion status changed enough to move sections
      _reorganizeTasks();
      
      notifyListeners();
    }

    // 2. Sync to Firestore in the background
    BaseSyncService? targetService;
    final sourceName = article.source;
    if (sourceName != null) {
      if (_service is SyncedDashboardService) {
        for (var s in (_service as SyncedDashboardService).syncServices) {
          if (s.sourceName == sourceName) {
            targetService = s;
            break;
          }
        }
      }
    }

    if (targetService != null) {
      final isoDate = DateFormatter.toIso(DateFormatter.parseAny(task.date));
      try {
        await targetService.updateArticleStatus(isoDate, article.url!, true, completedAt: completedAt);
      } catch (e) {
        debugPrint('ERROR: [DashboardProvider] Firestore sync failed for article: $e');
        // Note: In a production app, you might want to roll back local state here 
        // if the sync fails, but for now we prioritize UX speed.
      }
    }
  }

  /// Marks a quiz as completed locally and in Firestore.
  Future<void> markQuizAsCompleted(DashboardTask task, QuizDetail quiz) async {
    if (quiz.isCompleted) return;

    final now = DateTime.now();
    final completedAt = now.toIso8601String();
    debugPrint('DEBUG: [DashboardProvider] Marking quiz completed: ${quiz.title} at $completedAt');

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

      // Find which section the task belongs to and update it
      List<DashboardTask> updateList(List<DashboardTask> section) {
        return section.map((t) => t.date == task.date ? updatedTask : t).toList();
      }

      _data = DashboardData(
        daysLeft: _data!.daysLeft,
        todayTasks: updateList(_data!.todayTasks),
        inProgressTasks: updateList(_data!.inProgressTasks),
        notStartedTasks: updateList(_data!.notStartedTasks),
        completedTasks: updateList(_data!.completedTasks),
      );

      _reorganizeTasks();
      
      notifyListeners();
    }

    // 2. Sync to Firestore in the background
    BaseSyncService? targetService;
    final sourceName = quiz.source;
    if (_service is SyncedDashboardService) {
      for (var s in (_service as SyncedDashboardService).syncServices) {
        if (s.sourceName == sourceName) {
          targetService = s;
          break;
        }
      }
    }

    if (targetService != null) {
      final isoDate = DateFormatter.toIso(DateFormatter.parseAny(task.date));
      try {
        await targetService.updateQuizStatus(isoDate, quiz.title, true, completedAt: completedAt);
      } catch (e) {
        debugPrint('ERROR: [DashboardProvider] Firestore sync failed for quiz: $e');
      }
    }
  }

  /// Moves tasks between sections based on their new completion status
  void _reorganizeTasks() {
    if (_data == null) return;

    // 1. Gather all unique tasks
    final allTasks = _data!.allTasks;

    // 2. Prepare categorization
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // We need daysLeft for quota calculation
    final int daysLeft = _data!.daysLeft;

    final List<DashboardTask> todayTasks = [];
    final List<DashboardTask> inProgressTasks = [];
    final List<DashboardTask> notStartedTasks = [];
    final List<DashboardTask> completedTasks = [];

    // Sort all tasks by date ASC (Oldest first) to maintain consistency with service logic
    allTasks.sort((a, b) => a.isoDate.compareTo(b.isoDate));

    final List<DashboardTask> uncompleted = [];
    for (var task in allTasks) {
      if (task.isFullyCompleted) {
        completedTasks.add(task);
      } else {
        uncompleted.add(task);
      }
    }

    // Recalculate Quota (same logic as service)
    final int quota = daysLeft > 0 
        ? (uncompleted.length / daysLeft).ceil().clamp(3, uncompleted.length)
        : uncompleted.length;

    int assignedToToday = 0;
    for (var task in uncompleted) {
      final bool isStarted = (task.articlesDone + task.quizzesDone) > 0;
      
      if (assignedToToday < quota) {
        todayTasks.add(task);
        assignedToToday++;
      } else if (isStarted) {
        inProgressTasks.add(task);
      } else {
        notStartedTasks.add(task);
      }
    }

    // Sort history latest first
    completedTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));

    // 4. Update local state
    _data = DashboardData(
      daysLeft: daysLeft,
      todayTasks: todayTasks,
      inProgressTasks: inProgressTasks,
      notStartedTasks: notStartedTasks,
      completedTasks: completedTasks,
    );
  }
}
