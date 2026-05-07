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

  List<BaseSyncService> get syncServices => _syncServices;

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
    final Map<String, DashboardTask> taskMap = {};
    for (var t in baseData.allTasks) {
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
          isCompleted: item.isCompleted,
          source: item.source,
          completedAt: item.completedAt,
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

            if (needsUpdate || existing.completedAt != incoming.completedAt) {
              mergedArticles[url] = ArticleDetail(
                title: updatedTitle,
                subtitle: updatedSubtitle,
                url: incoming.url,
                isCompleted: incoming.isCompleted, // Use incoming completion
                source: incoming.source ?? existing.source,
                completedAt: incoming.completedAt,
              );
            }
          } else {
            mergedArticles[url] = incoming;
          }
        }
        
        final finalArticles = mergedArticles.values.toList();
        
        taskMap[isoDate] = DashboardTask(
          date: existingTask.date,
          articlesDone: 0, // Will be recalculated at the end
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
          if (mergedQuizzes.containsKey(incoming.title)) {
            final existing = mergedQuizzes[incoming.title]!;
            if (incoming.isCompleted && (!existing.isCompleted || existing.completedAt == null)) {
              mergedQuizzes[incoming.title] = incoming;
            }
          } else {
            mergedQuizzes[incoming.title] = incoming;
          }
        }

        final finalQuizzes = mergedQuizzes.values.toList();
        
        taskMap[isoDate] = DashboardTask(
          date: existingTask.date,
          articlesDone: existingTask.articlesDone,
          totalArticles: existingTask.totalArticles,
          quizzesDone: 0, // Will be recalculated at the end
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

    // 🟢 Recalculate Done Counts for ALL tasks in taskMap to ensure accuracy
    taskMap.forEach((iso, task) {
      final articlesDone = task.articles.where((a) => a.isCompleted).length;
      final quizzesDone = task.quizzes.where((q) => q.isCompleted).length;
      taskMap[iso] = task.copyWith(
        articlesDone: articlesDone,
        quizzesDone: quizzesDone,
      );
    });

    // 4. Generate Spaced Repetitions
    if (profile != null && profile.repetitionDays.isNotEmpty) {
      final List<DashboardTask> originalTasks = taskMap.values.toList();
      for (var task in originalTasks) {
        // If all items are completed, schedule revisions
        bool isTaskComplete = task.isFullyCompleted;

        if (isTaskComplete) {
          final lastDone = _getLatestCompletionDate(task);
          if (lastDone != null) {
            for (int interval in profile.repetitionDays) {
              DateTime scheduled = lastDone.add(Duration(days: interval));
              scheduled = _adjustToAvailableDay(scheduled, profile.availableDays);
              
              final iso = DateFormatter.toIso(scheduled);
              final appDate = DateFormatter.isoToAppDate(iso);
              
              // Only schedule future revisions (or today's)
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              if (scheduled.isBefore(today)) continue;

              final dueDays = scheduled.difference(today).inDays;

              // Create or Update Revision Task
              if (taskMap.containsKey(iso)) {
                final existing = taskMap[iso]!;
                // Merge items into existing task if it's already there
                final mergedArticles = [...existing.articles, ...task.articles];
                final mergedQuizzes = [...existing.quizzes, ...task.quizzes];
                
                // Deduplicate items during merge
                final uniqueArticles = {for (var a in mergedArticles) a.url: a}.values.toList();
                final uniqueQuizzes = {for (var q in mergedQuizzes) q.title: q}.values.toList();

                taskMap[iso] = existing.copyWith(
                  articles: uniqueArticles,
                  quizzes: uniqueQuizzes,
                  totalArticles: uniqueArticles.length,
                  totalQuizzes: uniqueQuizzes.length,
                  articlesDone: uniqueArticles.where((a) => a.isCompleted).length,
                  quizzesDone: uniqueQuizzes.where((q) => q.isCompleted).length,
                );
              } else {
                taskMap[iso] = DashboardTask(
                  date: appDate,
                  articlesDone: 0, // Revision starts fresh
                  totalArticles: task.articles.length,
                  quizzesDone: 0,
                  totalQuizzes: task.quizzes.length,
                  type: TaskType.revision,
                  dueDays: dueDays,
                  articles: task.articles.map((a) => a.copyWith(isCompleted: false, completedAt: null)).toList(),
                  quizzes: task.quizzes.map((q) => q.copyWith(isCompleted: false, completedAt: null)).toList(),
                );
              }
            }
          }
        }
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayIso = DateFormatter.toIso(today);

    // Calculate days left from exam date
    int daysLeft = 0;
    if (profile?.examDate != null) {
      final exam = DateTime(profile!.examDate!.year, profile.examDate!.month, profile.examDate!.day);
      daysLeft = exam.difference(today).inDays;
      if (daysLeft < 0) daysLeft = 0;
    }

    // 5. Categorize Tasks with Dynamic Quota for Today
    final List<DashboardTask> allTasksSorted = taskMap.values.toList()
      ..sort((a, b) => a.isoDate.compareTo(b.isoDate)); // Oldest first for backlog priority

    final List<DashboardTask> todayTasks = [];
    final List<DashboardTask> inProgressTasks = [];
    final List<DashboardTask> notStartedTasks = [];
    final List<DashboardTask> completedTasks = [];

    // Separate completed and uncompleted
    final List<DashboardTask> uncompleted = [];
    for (var task in allTasksSorted) {
      if (task.isFullyCompleted) {
        completedTasks.add(task);
      } else {
        uncompleted.add(task);
      }
    }

    // Calculate Quota
    // quota = max(3, ceil(total_uncompleted / days_left))
    final int quota = daysLeft > 0 
        ? (uncompleted.length / daysLeft).ceil().clamp(3, uncompleted.length)
        : uncompleted.length;

    print('DEBUG: [Dashboard] Days Left: $daysLeft, Uncompleted Tasks: ${uncompleted.length}, Quota: $quota');

    // Assign tasks based on quota and status
    int assignedToToday = 0;
    for (var task in uncompleted) {
      final bool isStarted = (task.articlesDone + task.quizzesDone) > 0;
      
      if (assignedToToday < quota) {
        todayTasks.add(task);
        assignedToToday++;
      } else if (isStarted) {
        // Surplus started tasks stay in "In Progress"
        inProgressTasks.add(task);
      } else {
        notStartedTasks.add(task);
      }
    }

    // Sort sections for display (usually latest first looks better in history, 
    // but today's tasks should probably be oldest first to encourage clearing backlog)
    // We'll keep history latest first.
    completedTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));

    return DashboardData(
      daysLeft: daysLeft,
      todayTasks: todayTasks,
      inProgressTasks: inProgressTasks,
      notStartedTasks: notStartedTasks,
      completedTasks: completedTasks,
    );
  }

  DateTime? _getLatestCompletionDate(DashboardTask task) {
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

  DateTime _adjustToAvailableDay(DateTime scheduled, List<int> availableDays) {
    if (availableDays.isEmpty) return scheduled;
    DateTime adjusted = DateTime(scheduled.year, scheduled.month, scheduled.day);
    // Loop max 7 days to avoid infinite loop
    for (int i = 0; i < 7; i++) {
      if (availableDays.contains(adjusted.weekday)) return adjusted;
      adjusted = adjusted.add(const Duration(days: 1));
    }
    return adjusted;
  }
}
