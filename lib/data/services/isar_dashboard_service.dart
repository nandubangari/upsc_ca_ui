import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/data/local/isar_service.dart';
import 'package:upsc_ca_ui/data/local/models/local_content.dart';
import 'package:upsc_ca_ui/data/local/models/local_sync_metadata.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_data.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/core/utils/task_categorizer.dart';
import 'package:upsc_ca_ui/core/utils/date_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'package:upsc_ca_ui/shared/models/repetition_task.dart';

class IsarDashboardService {
  final Isar _isar = IsarService.isar;

  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = DateFormatter.toIso(today);
      
      final profile = await ProfileService().getProfile();
      final userStartDate = profile?.startDate ?? DateTime(now.year, now.month - 6, 1);
      final startDateStr = DateFormatter.toIso(userStartDate);

      final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

      // 1. Fetch all repetitions to identify needed historical tasks
      final completionDocsRaw = await _isar.localSyncMetadatas.filter()
          .collectionEqualTo("repetitions")
          .documentIdStartsWith("${uid}_repetitions_")
          .findAll();
      
      final List<RepetitionTask> repetitions = completionDocsRaw.map((doc) {
        try {
          return RepetitionTask.fromJson(jsonDecode(doc.localData));
        } catch (_) {
          return null;
        }
      }).whereType<RepetitionTask>().toList();

      // Identify dates that need to be fetched even if outside user window (safety)
      final Set<String> extraDatesToFetch = repetitions
          .where((c) => !c.isFullyCompleted && c.nextDueDate != null && c.nextDueDate!.compareTo(todayStr) <= 0)
          .map((c) => c.contentDate)
          .toSet();

      // 2. Fetch local content
      // We fetch everything after userStartDate OR anything in extraDatesToFetch
      final localContentRaw = await _isar.localContents
          .filter()
          .dateGreaterThan(startDateStr, include: true)
          .or()
          .anyOf(extraDatesToFetch, (q, String date) => q.dateEqualTo(date))
          .findAll();
      
      final progressDocsRaw = await _isar.localSyncMetadatas.filter()
          .collectionEqualTo("progress")
          .documentIdStartsWith("${uid}_progress_")
          .findAll();

      final customTasksDocsRaw = await _isar.localSyncMetadatas.filter()
          .collectionEqualTo("customTasks")
          .documentIdStartsWith("${uid}_customTasks_")
          .findAll();

      int daysLeft = 0;
      if (profile != null) {
        if (profile.examDate != null) {
          daysLeft = profile.examDate!.difference(today).inDays;
          if (daysLeft < 0) daysLeft = 0;
        }
      }

      // Offload heavy transformation, JSON parsing, and flattening to an isolate
      return await compute(_processDashboardData, {
        'localContentRaw': localContentRaw,
        'progressDocsRaw': progressDocsRaw,
        'customTasksDocsRaw': customTasksDocsRaw,
        'repetitions': repetitions,
        'daysLeft': daysLeft,
        'articleSources': profile?.articleSources ?? {},
        'quizSources': profile?.quizSources ?? {},
      });
    } catch (e, stack) {
      AppLogger.e("Critical error in IsarDashboardService.fetchDashboardData", e, stack);
      return {
        'data': DashboardData(
          daysLeft: 0,
          todayTasks: [],
          repetitionTasks: [],
          notStartedTasks: [],
          completedTasks: [],
        ),
        'unread': [],
        'all': [],
      };
    }
  }

  static Map<String, dynamic> _processDashboardData(Map<String, dynamic> params) {
    final List<LocalContent> localContentRaw = params['localContentRaw'];
    final List<LocalSyncMetadata> progressDocsRaw = params['progressDocsRaw'];
    final List<LocalSyncMetadata> customTasksDocsRaw = params['customTasksDocsRaw'] ?? [];
    final List<RepetitionTask> repetitions = params['repetitions'] ?? [];
    final int daysLeft = params['daysLeft'];
    final Map<String, bool> articleSourcesPref = Map<String, bool>.from(params['articleSources'] ?? {});
    final Map<String, bool> quizSourcesPref = Map<String, bool>.from(params['quizSources'] ?? {});

    final Map<String, dynamic> allProgress = {};
    for (var doc in progressDocsRaw) {
      try {
        final data = jsonDecode(doc.localData) as Map<String, dynamic>;
        _mergeMapsStatic(allProgress, data);
      } catch (e) {
        // Silent failure in isolate
      }
    }

    final Map<String, DashboardTask> taskMap = {};

    // 1. Process regular local content
    for (var item in localContentRaw) {
      final dateStr = item.date;
      final taskDate = _isoToAppDateStatic(dateStr);
      
      taskMap.putIfAbsent(dateStr, () => DashboardTask(
        date: taskDate,
        articlesDone: 0,
        totalArticles: 0,
        quizzesDone: 0,
        totalQuizzes: 0,
        articles: [],
        quizzes: [],
      ));

      final task = taskMap[dateStr]!;
      
      bool isCompleted = false;
      String? completedAt;
      final monthId = "${item.year}_${item.month}";
      try {
        final dynamic progressVal;
        if (item.type == 'article') {
          progressVal = allProgress['completed']?[monthId]?[dateStr]?['articles']?[item.contentId];
        } else {
          progressVal = allProgress['completed']?[monthId]?[dateStr]?['quizzes']?[item.contentId];
        }
        
        if (progressVal != null) {
          isCompleted = true;
          if (progressVal is String) {
            completedAt = progressVal;
          }
        }
      } catch (_) {}

      if (item.type == 'article') {
        // Filter out articles from disabled sources
        if (articleSourcesPref[item.sourceId] == false) continue;

        task.articles.add(ArticleModel(
          title: item.title,
          subtitle: item.subtitle,
          url: item.url,
          source: item.sourceId,
          isCompleted: isCompleted,
          completedAt: completedAt,
          date: dateStr,
        ));
      } else {
        // Filter out quizzes from disabled sources
        if (quizSourcesPref[item.sourceId] == false) continue;

        task.quizzes.add(QuizModel(
          title: item.title,
          source: item.sourceId,
          url: item.url,
          isCompleted: isCompleted,
          completedAt: completedAt,
          date: dateStr,
        ));
      }
    }

    // 2. Process Custom Tasks from metadata
    for (var doc in customTasksDocsRaw) {
      try {
        final Map<String, dynamic> data = jsonDecode(doc.localData);
        data.forEach((dateStr, dayContent) {
          if (dayContent is Map<String, dynamic> && dayContent.containsKey('articles')) {
            final taskDate = _isoToAppDateStatic(dateStr);
            taskMap.putIfAbsent(dateStr, () => DashboardTask(
              date: taskDate,
              articlesDone: 0,
              totalArticles: 0,
              quizzesDone: 0,
              totalQuizzes: 0,
              articles: [],
              quizzes: [],
            ));

            final task = taskMap[dateStr]!;
            final articlesMap = dayContent['articles'] as Map<String, dynamic>;
            
            articlesMap.forEach((url, artJson) {
              final art = ArticleModel.fromJson(artJson as Map<String, dynamic>);
              
              // Only add if not already present (custom tasks can overlap with scraped ones if URLs match)
              if (!task.articles.any((a) => a.url == art.url)) {
                // Check progress for custom task too
                bool isCompleted = art.isCompleted;
                String? completedAt = art.completedAt;
                
                final dt = DateTime.tryParse(dateStr);
                if (dt != null) {
                  final monthId = "${dt.year}_${dt.month.toString().padLeft(2, '0')}";
                  final contentId = art.url?.hashCode.toString() ?? art.title.hashCode.toString();
                  final progressVal = allProgress['completed']?[monthId]?[dateStr]?['articles']?[contentId];
                  if (progressVal != null) {
                    isCompleted = true;
                    if (progressVal is String) completedAt = progressVal;
                  }
                }

                task.articles.add(art.copyWith(isCompleted: isCompleted, completedAt: completedAt));
              }
            });
          }
        });
      } catch (e) {
        // Silent failure in isolate
      }
    }

    // Filter out tasks that have no articles or quizzes after source filtering
    final filteredTaskMap = Map<String, DashboardTask>.from(taskMap);
    filteredTaskMap.removeWhere((date, task) => task.articles.isEmpty && task.quizzes.isEmpty);

    filteredTaskMap.forEach((date, task) {
      filteredTaskMap[date] = task.copyWith(
        totalArticles: task.articles.length,
        articlesDone: task.articles.where((a) => a.isCompleted).length,
        totalQuizzes: task.quizzes.length,
        quizzesDone: task.quizzes.where((q) => q.isCompleted).length,
      );
    });

    final dashboardData = TaskCategorizer.categorize(
      allTasks: filteredTaskMap.values.toList(),
      daysLeft: daysLeft,
      repetitions: repetitions,
    );

    // 2. Perform flattening inside the isolate
    final unread = <Map<String, dynamic>>[];
    final all = <Map<String, dynamic>>[];
    
    for (var task in dashboardData.allTasks) {
      final articles = List<ArticleModel>.from(task.articles);
      if (articles.isNotEmpty) {
        articles.sort((a, b) => _compareSourcesStatic(a.source, b.source));
        for (var article in articles) {
          final item = {'task': task, 'article': article};
          all.add(item);
          if (!article.isCompleted) {
            unread.add(item);
          }
        }
      }
    }

    return {
      'data': dashboardData,
      'unread': unread,
      'all': all,
    };
  }

  static int _compareSourcesStatic(String? s1, String? s2) {
    const order = ['vajiram', 'vision ias', 'next ias', 'insights ias'];
    final source1 = s1?.toLowerCase() ?? '';
    final source2 = s2?.toLowerCase() ?? '';
    
    final i1 = order.indexOf(source1);
    final i2 = order.indexOf(source2);
    
    if (i1 == -1 && i2 == -1) return source1.compareTo(source2);
    if (i1 == -1) return 1;
    if (i2 == -1) return -1;
    
    return i1.compareTo(i2);
  }

  static void _mergeMapsStatic(Map<String, dynamic> target, Map<String, dynamic> source) {
    source.forEach((key, value) {
      if (value is Map<String, dynamic> && target[key] is Map<String, dynamic>) {
        _mergeMapsStatic(target[key], value);
      } else {
        target[key] = value;
      }
    });
  }

  static String _isoToAppDateStatic(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
