import 'dart:async';
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
import 'package:upsc_ca_ui/shared/models/repetition_task.dart';
import 'package:upsc_ca_ui/data/sync/repetition_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/sync_manager.dart';
import 'package:upsc_ca_ui/data/local/isar_service.dart';
import 'package:upsc_ca_ui/data/local/models/local_content.dart';
import 'package:upsc_ca_ui/core/config/app_constants.dart';

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
  bool _isDashboardVisible = true;
  bool _isReaderOpen = false;
  bool _isLoadingMore = false;
  DateTime? _lastLoadMoreTime;
  List<RepetitionTask> _repetitionTasks = [];
  String? _lastFetchDate; // To track daily morning fetch
  
  // Pagination for completed tasks
  final int _completedTasksPageSize = 10;
  int _completedTasksCurrentCount = 10;
  
  // Optimization: Pre-calculated data to avoid work in build()
  List<Map<String, dynamic>> _cachedFlattenedUnread = [];
  List<Map<String, dynamic>> _cachedFlattenedAll = [];
  Map<String, dynamic>? _nextUnread;
  Map<String, DashboardTask> _taskMap = {};
  
  // Category date lists for UI stability
  List<String> _todayDateList = [];
  List<String> _repetitionDateList = [];
  List<String> _inProgressDateList = [];
  List<String> _notStartedDateList = [];
  List<String> _completedDateList = [];
  
  final DashboardRepository _repository = DashboardRepository();
  final RepetitionSyncService _repetitionSync = RepetitionSyncService();

  DashboardProvider() {
    _listenToSyncEvents();
  }

  void _listenToSyncEvents() {
    SyncManager().events.listen((event) {
      if (event.type == SyncEventType.initialSyncComplete) {
        AppLogger.d("DEBUG: Initial sync complete event received in DashboardProvider. Reloading data...");
        unawaited(loadDashboardData());
      }
    });
  }

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String? get syncStatus => _syncStatus;
  bool get needsVajiramLogin => _needsVajiramLogin;
  String? get lastViewedUrl => _lastViewedUrl;
  bool get isDashboardVisible => _isDashboardVisible;
  bool get isReaderOpen => _isReaderOpen;
  bool get isLoadingMore => _isLoadingMore;

  List<String> get todayDateList => _todayDateList;
  List<String> get repetitionDateList => _repetitionDateList;
  List<String> get inProgressDateList => _inProgressDateList;
  List<String> get notStartedDateList => _notStartedDateList;
  List<String> get completedDateList => _completedDateList;

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
      _completedDateList = visibleCompletedTasks.map((t) => t.date).toList();
      notifyListeners();
    }
  }

  Map<String, dynamic>? get nextUnreadTaskAndArticle => _nextUnread;

  List<Map<String, dynamic>> get allArticlesFlattened => _cachedFlattenedUnread;

  List<Map<String, dynamic>> get allArticlesFlattenedWithCompleted => _cachedFlattenedAll;

  void _updateInternalStateFromData() {
    if (_data == null) {
      _clearDashboardData();
      return;
    }

    // 1. Update Category Lists
    _todayDateList = _data!.todayTasks.map((t) => t.date).toList();
    _repetitionDateList = _data!.repetitionTasks.map((t) => t.date).toList();
    _inProgressDateList = _data!.inProgressTasks.map((t) => t.date).toList();
    _notStartedDateList = _data!.notStartedTasks.map((t) => t.date).toList();
    _completedDateList = _data!.completedTasks.map((t) => t.date).toList();

    // 2. Update Task Map for O(1) lookups
    final taskMap = <String, DashboardTask>{};
    for (var task in _data!.allTasks) {
      taskMap[task.date] = task;
    }
    _taskMap = taskMap;

    // 3. Update flattened lists (If not already updated by isolate)
    // This part is a fallback for optimistic updates
    if (_cachedFlattenedUnread.isEmpty && _data!.allTasks.isNotEmpty) {
      _recalculateFlattenedLists();
    }

    // 4. Calculate next unread
    if (_cachedFlattenedUnread.isEmpty) {
      _nextUnread = null;
    } else {
      if (_lastViewedUrl != null) {
        try {
          _nextUnread = _cachedFlattenedUnread.firstWhere((item) => (item['article'] as ArticleModel).url == _lastViewedUrl);
        } catch (_) {
          _nextUnread = _cachedFlattenedUnread.first;
        }
      } else {
        _nextUnread = _cachedFlattenedUnread.first;
      }
    }
  }

  void _recalculateFlattenedLists() {
    if (_data == null) return;
    
    final unread = <Map<String, dynamic>>[];
    final all = <Map<String, dynamic>>[];
    
    for (var task in _data!.allTasks) {
      final articles = List<ArticleModel>.from(task.articles);
      if (articles.isNotEmpty) {
        articles.sort((a, b) => _compareSources(a.source, b.source));
        for (var article in articles) {
          final item = {'task': task, 'article': article};
          all.add(item);
          if (!article.isCompleted) {
            unread.add(item);
          }
        }
      }
    }
    _cachedFlattenedUnread = unread;
    _cachedFlattenedAll = all;
  }

  void _calculateFlattenedData(Map<String, dynamic> result) {
    _data = result['data'] as DashboardData;
    
    // Merge with our local repetitions
    if (_data != null) {
      _data = TaskCategorizer.categorize(
        allTasks: _data!.allTasks,
        daysLeft: _data!.daysLeft,
        repetitions: _repetitionTasks,
      );
    }

    _recalculateFlattenedLists();
    
    _updateInternalStateFromData();
  }

  void _clearDashboardData() {
    _data = null;
    _cachedFlattenedUnread = [];
    _cachedFlattenedAll = [];
    _nextUnread = null;
    _taskMap = {};
    _todayDateList = [];
    _repetitionDateList = [];
    _inProgressDateList = [];
    _notStartedDateList = [];
    _completedDateList = [];
  }

  Future<void> setLastViewedUrl(String url) async {
    if (_lastViewedUrl == url) return;
    _lastViewedUrl = url;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString('last_viewed_url', url);
    notifyListeners();
  }

  Future<void> _loadLastViewedUrl() async {
    if (_prefs != null && _lastViewedUrl != null) return;
    _prefs ??= await SharedPreferences.getInstance();
    _lastViewedUrl = _prefs?.getString('last_viewed_url');
    // Don't notify here if it's called during loading
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
    if (_needsVajiramLogin == value) return;
    _needsVajiramLogin = value;
    notifyListeners();
  }

  void setDashboardVisible(bool visible) {
    if (_isDashboardVisible == visible) return;
    _isDashboardVisible = visible;
    AppLogger.d('DEBUG: [DashboardProvider] Dashboard visibility: $_isDashboardVisible');
    notifyListeners();
  }

  void setReaderOpen(bool open) {
    if (_isReaderOpen == open) return;
    _isReaderOpen = open;
    AppLogger.d('DEBUG: [DashboardProvider] Reader open: $_isReaderOpen');
    notifyListeners();
  }

  bool isArticleCompleted(String? url) {
    if (url == null || _data == null) return false;
    for (var t in _data!.allTasks) {
      for (var a in t.articles) {
        if (a.url == url) return a.isCompleted;
      }
    }
    return false;
  }

  bool isQuizCompleted(String? source, String title) {
    if (_data == null) return false;
    for (var t in _data!.allTasks) {
      for (var q in t.quizzes) {
        if (q.title == title && q.source == source) return q.isCompleted;
      }
    }
    return false;
  }

  DashboardTask? getTaskByDate(String date) => _taskMap[date];

  double getTaskProgress(String date) {
    final task = _taskMap[date];
    if (task == null) return 0;
    final total = task.totalArticles + task.totalQuizzes;
    if (total == 0) return 0;
    return (task.articlesDone + task.quizzesDone) / total;
  }

  Map<String, int> getTaskStats(String date) {
    final task = _taskMap[date];
    if (task == null) return {'articlesDone': 0, 'totalArticles': 0, 'quizzesDone': 0, 'totalQuizzes': 0};
    return {
      'articlesDone': task.articlesDone,
      'totalArticles': task.totalArticles,
      'quizzesDone': task.quizzesDone,
      'totalQuizzes': task.totalQuizzes,
    };
  }

  /// Syncs all configured article sources.
  Future<void> syncAllArticles({bool forceRefresh = false, bool isRetryAfterLogin = false, bool onlyRecent = true}) async {
    if (_isReaderOpen) {
      AppLogger.d('DEBUG: [DashboardProvider] Reader is open, skipping background sync');
      return;
    }

    _isSyncing = true;
    _syncStatus = isRetryAfterLogin ? 'Retrying sync after login...' : (forceRefresh ? 'Force refreshing sources...' : 'Starting sync...');
    notifyListeners();

    try {
      final profile = await ProfileService().getProfile();
      if (profile != null) {
        try {
          if (forceRefresh) {
            // Full refresh should definitely pull latest repetitions
            await _repetitionSync.downloadAll();
            _lastFetchDate = DateFormatter.toIso(DateTime.now());
          }
          
          // Use coordinatedSync for manual triggers to ensure strict sequence and metadata updates
          await _repository.coordinatedSync(
            profile.startDate,
            forceRefresh: forceRefresh,
            onStatusUpdate: (status) {
              if (_syncStatus != status) {
                _syncStatus = status;
                notifyListeners();
              }
            },
            shouldPause: () => _isReaderOpen,
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
        notifyListeners();
      }
    } catch (e) {
      _error = "Sync failed: $e";
      notifyListeners();
    } finally {
      _isSyncing = false;
      _syncStatus = null;
      notifyListeners();
    }
  }

  /// Fetches dashboard data.
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadLastViewedUrl();
      
      final todayStr = DateFormatter.toIso(DateTime.now());
      
      // Step: Check if we have any data at all. If not, we wait for initial sync.
      final localCount = await IsarService.isar.localContents.count();
      if (localCount == 0) {
        AppLogger.d("Dashboard loading: No local data found. Showing skeleton until initial sync...");
        // Keep _isLoading = true and return. NotifyListeners was called at start of method.
        return;
      }

      // Step 3: Morning fetch when the app opens
      if (_lastFetchDate != todayStr) {
        AppLogger.d("New day detected. Performing morning fetch for due repetitions...");
        await _repetitionSync.downloadAll();
        _lastFetchDate = todayStr;
      }

      _repetitionTasks = await _repetitionSync.getAllRepetitions();
      final result = await _repository.getDashboardData();
      _calculateFlattenedData(result);

      // We removed the automatic coordinatedSync from here to only trigger it on manual sync.
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMonths() async {
    loadMoreCompletedTasks();
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
          joinedAt: profile.joinedAt,
          startDate: profile.startDate,
          articleSources: profile.articleSources,
          quizSources: profile.quizSources,
          repetitionIntervals: profile.repetitionIntervals,
          themeColorValue: profile.themeColorValue,
          examDate: date,
          isPremium: profile.isPremium,
          trialStartDate: profile.trialStartDate,
          trialEndDate: profile.trialEndDate,
          subscriptionPlan: profile.subscriptionPlan,
          subscriptionStartDate: profile.subscriptionStartDate,
          subscriptionEndDate: profile.subscriptionEndDate,
          manualPremium: profile.manualPremium,
          manualPremiumReason: profile.manualPremiumReason,
          purchasePlatform: profile.purchasePlatform,
          lastValidationAt: profile.lastValidationAt,
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

      final allTasks = _data!.allTasks.map((t) => t.date == task.date ? updatedTask : t).toList();
      _data = TaskCategorizer.categorize(
        allTasks: allTasks, 
        daysLeft: _data!.daysLeft,
        repetitions: _repetitionTasks,
      );
      _recalculateFlattenedLists();
      _updateInternalStateFromData();
      
      notifyListeners();

      // Check for day completion
      if (updatedTask.isFullyCompleted) {
        await _recordRepetitionCompletion(task);
      }
    }

    // 2. Sync to Firestore in the background
    final isoDate = DateFormatter.toIso(DateFormatter.parseAny(task.date));
    final dateObj = DateTime.parse(isoDate);
    final year = dateObj.year.toString();
    final monthId = "${dateObj.year}_${dateObj.month.toString().padLeft(2, '0')}";
    final articleId = article.url?.hashCode.toString() ?? article.title.hashCode.toString();

    try {
      await _repository.markArticleCompleted(
        article.source ?? "unknown",
        year,
        monthId,
        isoDate,
        articleId,
      );
    } catch (e) {
      AppLogger.e('[DashboardProvider] local save failed', e);
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
      _data = TaskCategorizer.categorize(
        allTasks: allTasks, 
        daysLeft: _data!.daysLeft,
        repetitions: _repetitionTasks,
      );
      _recalculateFlattenedLists();
      _updateInternalStateFromData();
      
      notifyListeners();

      // Check for day completion
      if (updatedTask.isFullyCompleted) {
        await _recordRepetitionCompletion(task);
      }
    }

    // 2. Sync to Firestore in the background
    final isoDate = DateFormatter.toIso(DateFormatter.parseAny(task.date));
    final dateObj = DateTime.parse(isoDate);
    final year = dateObj.year.toString();
    final monthId = "${dateObj.year}_${dateObj.month.toString().padLeft(2, '0')}";
    final quizId = quiz.title.hashCode.toString();

    try {
      await _repository.markQuizCompleted(
        quiz.source,
        year,
        monthId,
        isoDate,
        quizId,
      );
    } catch (e) {
      AppLogger.e('[DashboardProvider] local save failed for quiz', e);
    }
  }

  Future<void> _recordRepetitionCompletion(DashboardTask task) async {
    final String contentDate = DateFormatter.toIso(task.isoDate);
    final String today = DateFormatter.toIso(DateTime.now());

    // 1. Get current repetition record if exists
    RepetitionTask? existing = await _repetitionSync.getRepetition(contentDate);
    
    final profile = await ProfileService().getProfile();
    final List<int> intervals = profile?.repetitionIntervals ?? AppConstants.defaultRepetitionDays;

    if (existing == null) {
      // Step 2: Save the completed day for the first time
      final int firstInterval = intervals.isNotEmpty ? intervals[0] : 1;
      final String nextDue = DateFormatter.toIso(DateTime.now().add(Duration(days: firstInterval)));

      final newRep = RepetitionTask(
        contentDate: contentDate,
        firstCompletedDate: today,
        currentRepetition: 1,
        nextDueDate: nextDue,
        history: [],
      );

      await _repetitionSync.saveRepetition(newRep);
      _repetitionTasks.add(newRep);
      AppLogger.d("First completion recorded for $contentDate. Next due: $nextDue");
    } else {
      // Step 7: Update Firestore after a repetition is completed
      if (existing.isFullyCompleted) return;

      final int nextRepNumber = existing.currentRepetition + 1;
      final int intervalIndex = nextRepNumber - 1;

      String? nextDue;
      bool isFullyCompleted = false;

      if (intervalIndex < intervals.length) {
        nextDue = DateFormatter.toIso(DateTime.now().add(Duration(days: intervals[intervalIndex])));
      } else {
        isFullyCompleted = true;
      }

      final updatedHistory = List<RepetitionHistory>.from(existing.history)
        ..add(RepetitionHistory(
          repNumber: existing.currentRepetition,
          scheduledDate: existing.nextDueDate ?? today,
          completedDate: today,
        ));

      final updatedRep = existing.copyWith(
        currentRepetition: nextRepNumber,
        nextDueDate: nextDue,
        history: updatedHistory,
        isFullyCompleted: isFullyCompleted,
      );

      await _repetitionSync.saveRepetition(updatedRep);
      
      // Update local state immediately
      final idx = _repetitionTasks.indexWhere((r) => r.contentDate == contentDate);
      if (idx != -1) {
        _repetitionTasks[idx] = updatedRep;
      }

      AppLogger.d("Repetition ${existing.currentRepetition} completed for $contentDate. Next due: $nextDue");
    }

    // Re-run categorization to reflect UI changes (moving out of repetition section)
    if (_data != null) {
      _data = TaskCategorizer.categorize(
        allTasks: _data!.allTasks, 
        daysLeft: _data!.daysLeft,
        repetitions: _repetitionTasks,
      );
      _updateInternalStateFromData();
    }
    
    notifyListeners();
    
    // Trigger sync
    unawaited(_repetitionSync.sync(contentDate));
  }
}
