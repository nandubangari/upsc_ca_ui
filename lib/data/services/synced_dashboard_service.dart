import 'package:flutter/foundation.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/data/services/dashboard_service.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_data.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/shared/models/profile_data.dart';
import 'package:upsc_ca_ui/data/sync/base_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/vajiram_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/vision_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/next_ias_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/insights_ias_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/chahal_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/drishti_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/insights_quiz_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/user_task_sync_service.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'package:upsc_ca_ui/core/utils/date_formatter.dart';
import 'package:upsc_ca_ui/core/utils/task_categorizer.dart';

class SyncedDashboardService implements DashboardService {
  final DashboardService _baseService;
  final List<BaseSyncService> _syncServices = [
    VajiramSyncService(),
    VisionSyncService(),
    NextIASSyncService(),
    InsightsIASSyncService(),
    ChahalSyncService(),
    DrishtiSyncService(),
    InsightsQuizSyncService(),
    UserTaskSyncService(),
  ];
  final ProfileService _profileService = ProfileService();

  SyncedDashboardService(this._baseService);

  @override
  Future<DashboardData> fetchDashboardData() async {
    // 1. Fetch base dashboard data and user profile in parallel
    final results = await Future.wait([
      _baseService.fetchDashboardData(),
      _profileService.getProfile(),
    ]);
    
    final DashboardData baseData = results[0] as DashboardData;
    final profile = results[1] as ProfileData?;
    final startDate = profile?.startDate ?? DateTime(2000);
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final startDateIso = DateFormatter.toIso(normalizedStartDate);

    // 2. Fetch synced articles and quizzes from all sources in PARALLEL
    final allSyncedArticles = <String, List<ArticleModel>>{};
    final allSyncedQuizzes = <String, List<QuizModel>>{};
    
    final List<Future<void>> fetchFutures = _syncServices.map((service) async {
      try {
        final sourceResults = await Future.wait([
          service.getAllSyncedArticles(startDate: profile?.startDate),
          service.getAllSyncedQuizzes(startDate: profile?.startDate),
        ]);
        
        final Map<String, List<ArticleModel>> sourceArticles = sourceResults[0] as Map<String, List<ArticleModel>>;
        final Map<String, List<QuizModel>> sourceQuizzes = sourceResults[1] as Map<String, List<QuizModel>>;
        final String sourceName = service.sourceName;

        sourceArticles.forEach((date, items) {
          if (date.compareTo(startDateIso) >= 0) {
            for (var item in items) {
              if (!item.isCustom || item.source == null) {
                // Ensure source is set for merged items
                // This might need a copyWith if model is immutable
                // But it's easier to handle during merge below.
              }
            }
            allSyncedArticles.putIfAbsent(date, () => []).addAll(items.map((i) => 
              (!i.isCustom || i.source == null) ? i.copyWith(source: sourceName) : i
            ));
          }
        });

        sourceQuizzes.forEach((date, quizzes) {
          if (date.compareTo(startDateIso) >= 0) {
            allSyncedQuizzes.putIfAbsent(date, () => []).addAll(quizzes);
          }
        });
      } catch (e) {
        AppLogger.e("[SyncedDashboardService] Parallel fetch failed for ${service.sourceName}", e);
      }
    }).toList();

    await Future.wait(fetchFutures);

    // 3. Move merging and categorization to background isolate
    final syncData = {
      'baseData': baseData.toJson(),
      'profile': profile?.toJson(),
      'allSyncedArticles': allSyncedArticles.map((k, v) => MapEntry(k, v.map((i) => i.toJson()).toList())),
      'allSyncedQuizzes': allSyncedQuizzes.map((k, v) => MapEntry(k, v.map((i) => i.toJson()).toList())),
    };

    try {
      final resultJson = await compute(_mergeAndCategorizeInBackground, syncData);
      return DashboardData.fromJson(resultJson);
    } catch (e) {
      AppLogger.e("[SyncedDashboardService] Background merge failed", e);
      // Fallback to minimal processing if background fails (though compute is usually reliable)
      return baseData;
    }
  }

  static Map<String, dynamic> _mergeAndCategorizeInBackground(Map<String, dynamic> data) {
    final baseData = DashboardData.fromJson(data['baseData']);
    final profile = data['profile'] != null ? ProfileData.fromJson(data['profile']) : null;
    
    final Map<String, List<ArticleModel>> allSyncedArticles = (data['allSyncedArticles'] as Map).map(
      (k, v) => MapEntry(k as String, (v as List).map((i) => ArticleModel.fromJson(i)).toList())
    );
    final Map<String, List<QuizModel>> allSyncedQuizzes = (data['allSyncedQuizzes'] as Map).map(
      (k, v) => MapEntry(k as String, (v as List).map((i) => QuizModel.fromJson(i)).toList())
    );

    final startDate = profile?.startDate ?? DateTime(2000);
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final startDateIso = normalizedStartDate.toIso8601String().split('T')[0];

    // Merge logic (copied from original and adapted)
    final Map<String, DashboardTask> taskMap = {};
    for (var t in baseData.allTasks) {
      final iso = _toIsoDate(t.date);
      taskMap[iso] = t;
    }

    // Merge Articles
    allSyncedArticles.forEach((isoDate, items) {
      if (isoDate.compareTo(startDateIso) < 0) return;

      final Map<String, ArticleModel> uniqueIncoming = {};
      for (var item in items) {
        uniqueIncoming[item.url ?? ''] = item;
      }
      final incomingArticles = uniqueIncoming.values.toList();

      if (taskMap.containsKey(isoDate)) {
        final existingTask = taskMap[isoDate]!;
        final Map<String, ArticleModel> merged = { for (var a in existingTask.articles) a.url ?? '': a };

        for (var incoming in incomingArticles) {
          final url = incoming.url ?? '';
          if (merged.containsKey(url)) {
            final existing = merged[url]!;
            merged[url] = existing.copyWith(
              title: incoming.title.length > existing.title.length ? incoming.title : existing.title,
              subtitle: (existing.subtitle == null || existing.subtitle!.isEmpty) ? incoming.subtitle : existing.subtitle,
              isCompleted: incoming.isCompleted || existing.isCompleted,
              completedAt: existing.completedAt ?? incoming.completedAt,
              source: existing.source ?? incoming.source,
            );
          } else {
            merged[url] = incoming;
          }
        }
        taskMap[isoDate] = existingTask.copyWith(articles: merged.values.toList());
      } else {
        taskMap[isoDate] = DashboardTask(
          date: _isoToAppDate(isoDate),
          articlesDone: 0, totalArticles: incomingArticles.length,
          quizzesDone: 0, totalQuizzes: 0,
          articles: incomingArticles,
        );
      }
    });

    // Merge Quizzes
    allSyncedQuizzes.forEach((isoDate, quizzes) {
      if (isoDate.compareTo(startDateIso) < 0) return;

      if (taskMap.containsKey(isoDate)) {
        final existingTask = taskMap[isoDate]!;
        final Map<String, QuizModel> merged = { for (var q in existingTask.quizzes) q.title: q };
        for (var incoming in quizzes) {
          if (merged.containsKey(incoming.title)) {
            final existing = merged[incoming.title]!;
            merged[incoming.title] = existing.copyWith(
              isCompleted: incoming.isCompleted || existing.isCompleted,
              completedAt: existing.completedAt ?? incoming.completedAt,
            );
          } else {
            merged[incoming.title] = incoming;
          }
        }
        taskMap[isoDate] = existingTask.copyWith(quizzes: merged.values.toList());
      } else {
        taskMap[isoDate] = DashboardTask(
          date: _isoToAppDate(isoDate),
          articlesDone: 0, totalArticles: 0,
          quizzesDone: 0, totalQuizzes: quizzes.length,
          quizzes: quizzes, articles: [],
        );
      }
    });

    // Recalculate counts
    taskMap.forEach((iso, task) {
      taskMap[iso] = task.copyWith(
        totalArticles: task.articles.length,
        articlesDone: task.articles.where((a) => a.isCompleted).length,
        totalQuizzes: task.quizzes.length,
        quizzesDone: task.quizzes.where((q) => q.isCompleted).length,
      );
    });

    // Spaced Repetition Logic (Revisions)
    if (profile != null && profile.repetitionDays.isNotEmpty) {
      final List<DashboardTask> completedHistory = taskMap.values.where((t) => t.isFullyCompleted).toList();
      for (var task in completedHistory) {
        final lastDone = _getLatestCompletionDate(task);
        if (lastDone == null) continue;

        for (int interval in profile.repetitionDays) {
          if (interval <= 0) continue;
          DateTime scheduled = lastDone.add(Duration(days: interval));
          scheduled = _adjustToAvailableDay(scheduled, profile.availableDays);
          
          final iso = scheduled.toIso8601String().split('T')[0];
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          if (scheduled.isBefore(today)) continue;

          if (taskMap.containsKey(iso)) {
            final existing = taskMap[iso]!;
            final mergedArticles = { for (var a in [...existing.articles, ...task.articles]) a.url: a }.values.toList();
            final mergedQuizzes = { for (var q in [...existing.quizzes, ...task.quizzes]) q.title: q }.values.toList();

            taskMap[iso] = existing.copyWith(
              articles: mergedArticles,
              quizzes: mergedQuizzes,
              totalArticles: mergedArticles.length,
              totalQuizzes: mergedQuizzes.length,
              articlesDone: mergedArticles.where((a) => a.isCompleted).length,
              quizzesDone: mergedQuizzes.where((q) => q.isCompleted).length,
            );
          } else {
            taskMap[iso] = DashboardTask(
              date: _isoToAppDate(iso),
              articlesDone: 0, totalArticles: task.articles.length,
              quizzesDone: 0, totalQuizzes: task.quizzes.length,
              type: TaskType.revision,
              dueDays: scheduled.difference(today).inDays,
              articles: task.articles.map((a) => a.copyWith(isCompleted: false, completedAt: null)).toList(),
              quizzes: task.quizzes.map((q) => q.copyWith(isCompleted: false, completedAt: null)).toList(),
            );
          }
        }
      }
    }

    // Categorization
    int daysLeft = 0;
    if (profile?.examDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      daysLeft = profile!.examDate!.difference(today).inDays;
      if (daysLeft < 0) daysLeft = 0;
    }

    final categorized = TaskCategorizer.categorize(allTasks: taskMap.values.toList(), daysLeft: daysLeft);
    return categorized.toJson();
  }

  static String _toIsoDate(String dateStr) {
    try {
      return DateTime.parse(dateStr).toIso8601String().split('T')[0];
    } catch (_) {
      try {
        final parts = dateStr.split(' ');
        if (parts.length == 3) {
          final day = parts[0].padLeft(2, '0');
          final monthStr = parts[1].toUpperCase();
          final year = parts[2];
          final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
          final monthIdx = months.indexOf(monthStr) + 1;
          if (monthIdx > 0) return '$year-${monthIdx.toString().padLeft(2, '0')}-$day';
        }
      } catch (_) {}
      return "0000-00-00";
    }
  }

  static String _isoToAppDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  static DateTime? _getLatestCompletionDate(DashboardTask task) {
    DateTime? latest;
    for (var a in task.articles) {
      if (a.completedAt != null) {
        final dt = DateTime.tryParse(a.completedAt!);
        if (dt != null && (latest == null || dt.isAfter(latest))) latest = dt;
      }
    }
    for (var q in task.quizzes) {
      if (q.completedAt != null) {
        final dt = DateTime.tryParse(q.completedAt!);
        if (dt != null && (latest == null || dt.isAfter(latest))) latest = dt;
      }
    }
    return latest;
  }

  static DateTime _adjustToAvailableDay(DateTime scheduled, List<int> availableDays) {
    if (availableDays.isEmpty) return scheduled;
    DateTime adjusted = DateTime(scheduled.year, scheduled.month, scheduled.day);
    for (int i = 0; i < 7; i++) {
      if (availableDays.contains(adjusted.weekday)) return adjusted;
      adjusted = adjusted.add(const Duration(days: 1));
    }
    return adjusted;
  }
}
