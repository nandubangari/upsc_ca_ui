import 'dashboard_service.dart';
import '../models/dashboard_data.dart';
import '../models/study_item_model.dart';
import '../models/profile_data.dart';
import 'sync/base_sync_service.dart';
import 'sync/vajiram_sync_service.dart';
import 'sync/vision_sync_service.dart';
import 'sync/next_ias_sync_service.dart';
import 'sync/insights_ias_sync_service.dart';
import 'profile_service.dart';
import '../core/utils/date_formatter.dart';

class SyncedDashboardService implements DashboardService {
  final DashboardService _baseService;
  final List<BaseSyncService> _syncServices = [
    VajiramSyncService(),
    VisionSyncService(),
    NextIASSyncService(),
    InsightsIASSyncService(),
    // Add future sources here
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

    // 2. Fetch synced articles from all sources
    final allSyncedArticles = <String, List<StudyItem>>{};
    int totalSyncedCount = 0;
    
    for (var service in _syncServices) {
      final sourceArticles = await service.getAllSyncedArticles();
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
          totalSyncedCount += items.length;
        }
      });
    }

    print('DEBUG: [Dashboard] Total raw synced articles fetched: $totalSyncedCount');

    // 3. Merge synced articles into the dashboard tasks
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

    return DashboardData(
      daysLeft: baseData.daysLeft,
      todayTasks: todayTasks,
      notStartedTasks: notStartedTasks,
      completedTasks: completedTasks,
    );
  }
}
