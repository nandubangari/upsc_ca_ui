import 'dashboard_service.dart';
import '../models/dashboard_data.dart';
import '../models/study_item_model.dart';
import '../models/profile_data.dart';
import 'sync/base_sync_service.dart';
import 'sync/vajiram_sync_service.dart';
import 'sync/vision_sync_service.dart';
import 'sync/next_ias_sync_service.dart';
import 'sync/insights_ias_sync_service.dart';
import 'sync/chahal_sync_service.dart';
import 'sync/drishti_sync_service.dart';
import 'sync/insights_quiz_sync_service.dart';
import 'profile_service.dart';
import '../core/utils/date_formatter.dart';

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
  ];
  final ProfileService _profileService = ProfileService();

  SyncedDashboardService(this._baseService);

  @override
  Future<DashboardData> fetchDashboardData() async {
    // 1. Fetch base dashboard data and user profile
    final results = await Future.wait([
      _baseService.fetchDashboardData(),
      _profileService.getProfile(),
    ]);
    
    final DashboardData baseData = results[0] as DashboardData;
    final profile = results[1] as ProfileData?;
    final startDate = profile?.startDate ?? DateTime(2000); // Default to far past if no profile
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final startDateIso = DateFormatter.toIso(normalizedStartDate);

    // 2. Fetch synced articles and quizzes from all sources
    final allSyncedArticles = <String, List<StudyItem>>{};
    final allSyncedQuizzes = <String, List<QuizDetail>>{};
    int totalSyncedArticlesCount = 0;
    int totalSyncedQuizzesCount = 0;
    
    for (var service in _syncServices) {
      final sourceArticles = await service.getAllSyncedArticles();
      final sourceQuizzes = await service.getAllSyncedQuizzes();
      final String sourceName = service.sourceName;

      sourceArticles.forEach((date, items) {
        // Set source for each item
        for (var item in items) {
          item.source = sourceName;
        }

        // Only include articles on or after the profile start date
        if (date.compareTo(startDateIso) >= 0) {
          if (allSyncedArticles.containsKey(date)) {
             allSyncedArticles[date]!.addAll(items);
          } else {
             allSyncedArticles[date] = List<StudyItem>.from(items);
          }
          totalSyncedArticlesCount += items.length;
        }
      });

      sourceQuizzes.forEach((date, quizzes) {
        if (date.compareTo(startDateIso) >= 0) {
          if (allSyncedQuizzes.containsKey(date)) {
            allSyncedQuizzes[date]!.addAll(quizzes);
          } else {
            allSyncedQuizzes[date] = List<QuizDetail>.from(quizzes);
          }
          totalSyncedQuizzesCount += quizzes.length;
        }
      });
    }

    print('DEBUG: [Dashboard] Total raw synced articles fetched: $totalSyncedArticlesCount');
    print('DEBUG: [Dashboard] Total raw synced quizzes fetched: $totalSyncedQuizzesCount');

    // 3. Merge synced articles and quizzes into the dashboard tasks
    final allTasks = <DashboardTask>[
      ...baseData.todayTasks,
      ...baseData.notStartedTasks,
      ...baseData.completedTasks,
    ];

    // Use ISO dates as keys for consistent sorting and merging
    final Map<String, DashboardTask> taskMap = {};
    for (var t in allTasks) {
      final iso = DateFormatter.toIso(DateFormatter.parseAny(t.date));
      taskMap[iso] = t;
    }

    // Merge Articles
    allSyncedArticles.forEach((isoDate, items) {
      final appDate = DateFormatter.isoToAppDate(isoDate);
      
      // 🟢 Deduplicate by URL within the same date (across all sources)
      final Map<String, ArticleDetail> uniqueIncoming = {};
      for (var item in items) {
        uniqueIncoming[item.url] = ArticleDetail(
          title: item.title,
          subtitle: item.subtitle,
          url: item.url,
          isCompleted: false,
          source: item.source,
        );
      }

      final articleDetails = uniqueIncoming.values.toList();

      if (taskMap.containsKey(isoDate)) {
        final existingTask = taskMap[isoDate]!;
        
        // Merge articles, updating those with missing info (like subtitles)
        final Map<String, ArticleDetail> mergedArticles = {
          for (var a in existingTask.articles) a.url ?? '': a
        };

        for (var incoming in articleDetails) {
          final url = incoming.url ?? '';
          if (mergedArticles.containsKey(url)) {
            final existing = mergedArticles[url]!;
            
            // Check if title or subtitle needs update
            bool needsUpdate = false;
            String updatedTitle = existing.title;
            String? updatedSubtitle = existing.subtitle;

            // 1. Update Title if different (refined from sync)
            if (existing.title != incoming.title) {
              updatedTitle = incoming.title;
              needsUpdate = true;
            }

            // 2. Update Subtitle if missing
            final hasIncomingSubtitle = incoming.subtitle != null && 
                                       incoming.subtitle!.isNotEmpty && 
                                       incoming.subtitle!.toLowerCase() != "null";
            
            final existingSubtitle = existing.subtitle;
            final needsSubtitle = existingSubtitle == null || 
                                 existingSubtitle.isEmpty || 
                                 existingSubtitle.toLowerCase() == "null";

            if (needsSubtitle && hasIncomingSubtitle) {
              updatedSubtitle = incoming.subtitle;
              needsUpdate = true;
            }

            if (needsUpdate) {
              mergedArticles[url] = ArticleDetail(
                title: updatedTitle,
                subtitle: updatedSubtitle,
                url: incoming.url,
                isCompleted: existing.isCompleted,
                source: incoming.source ?? existing.source,
              );
            }
          } else {
            mergedArticles[url] = incoming;
          }
        }
        
        final finalArticles = mergedArticles.values.toList();
        
        taskMap[isoDate] = DashboardTask(
          date: existingTask.date,
          articlesDone: existingTask.articlesDone,
          totalArticles: finalArticles.length,
          quizzesDone: existingTask.quizzesDone,
          totalQuizzes: existingTask.totalQuizzes,
          type: existingTask.type,
          dueDays: existingTask.dueDays,
          lastCompleted: existingTask.lastCompleted,
          repetitions: existingTask.repetitions,
          quizzes: existingTask.quizzes,
          articles: finalArticles,
        );
      } else {
        taskMap[isoDate] = DashboardTask(
          date: appDate,
          articlesDone: 0,
          totalArticles: articleDetails.length,
          quizzesDone: 0,
          totalQuizzes: 0,
          articles: articleDetails,
        );
      }
    });

    // Merge Quizzes
    allSyncedQuizzes.forEach((isoDate, quizzes) {
      if (taskMap.containsKey(isoDate)) {
        final existingTask = taskMap[isoDate]!;
        
        final Map<String, QuizDetail> mergedQuizzes = {
          for (var q in existingTask.quizzes) q.title: q
        };

        for (var incoming in quizzes) {
          if (!mergedQuizzes.containsKey(incoming.title)) {
            mergedQuizzes[incoming.title] = incoming;
          }
        }

        final finalQuizzes = mergedQuizzes.values.toList();
        
        taskMap[isoDate] = DashboardTask(
          date: existingTask.date,
          articlesDone: existingTask.articlesDone,
          totalArticles: existingTask.totalArticles,
          quizzesDone: existingTask.quizzesDone,
          totalQuizzes: finalQuizzes.length,
          type: existingTask.type,
          dueDays: existingTask.dueDays,
          lastCompleted: existingTask.lastCompleted,
          repetitions: existingTask.repetitions,
          quizzes: finalQuizzes,
          articles: existingTask.articles,
        );
      } else {
        final appDate = DateFormatter.isoToAppDate(isoDate);
        taskMap[isoDate] = DashboardTask(
          date: appDate,
          articlesDone: 0,
          totalArticles: 0,
          quizzesDone: 0,
          totalQuizzes: quizzes.length,
          quizzes: quizzes,
          articles: [],
        );
      }
    });

    final todayIso = DateFormatter.toIso(DateTime.now());

    final List<DashboardTask> todayTasks = [];
    final List<DashboardTask> notStartedTasks = [];
    final List<DashboardTask> completedTasks = [];

    // Sort ISO dates descending (latest first)
    final sortedIsoDates = taskMap.keys.toList()..sort((a, b) => b.compareTo(a));

    for (var iso in sortedIsoDates) {
      final task = taskMap[iso]!;
      if (iso == todayIso) {
        todayTasks.add(task);
      } else if (task.articlesDone + task.quizzesDone == task.totalArticles + task.totalQuizzes && 
                 (task.totalArticles + task.totalQuizzes) > 0) {
        completedTasks.add(task);
      } else {
        notStartedTasks.add(task);
      }
    }

    // Calculate days left from exam date
    int daysLeft = 0;
    if (profile?.examDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final exam = DateTime(profile!.examDate!.year, profile.examDate!.month, profile.examDate!.day);
      daysLeft = exam.difference(today).inDays;
      if (daysLeft < 0) daysLeft = 0;
    }

    return DashboardData(
      daysLeft: daysLeft,
      todayTasks: todayTasks,
      notStartedTasks: notStartedTasks,
      completedTasks: completedTasks,
    );
  }
}
