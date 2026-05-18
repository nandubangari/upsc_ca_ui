import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:upsc_ca_ui/data/services/isar_dashboard_service.dart';
import 'package:upsc_ca_ui/data/sync/content_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/progress_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/custom_task_sync_service.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/data/sync/sync_manager.dart';
import 'package:upsc_ca_ui/core/utils/date_formatter.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/data/services/vision_study_service.dart';
import 'package:upsc_ca_ui/data/services/insights_ias_study_service.dart';
import 'package:upsc_ca_ui/data/services/chahal_study_service.dart';
import 'package:upsc_ca_ui/data/services/drishti_study_service.dart';
import 'package:upsc_ca_ui/data/services/next_ias_study_service.dart';
import 'package:upsc_ca_ui/data/services/vajiram_study_service.dart';
import 'package:upsc_ca_ui/data/services/vajiram_session_service.dart';
import 'package:upsc_ca_ui/data/services/insights_quiz_study_service.dart';
import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';
import 'package:upsc_ca_ui/data/local/models/local_content.dart';

class DashboardRepository {
  final IsarDashboardService _isarService = IsarDashboardService();
  final ContentSyncService _contentSync = ContentSyncService();
  final ProgressSyncService _progressSync = ProgressSyncService();
  final CustomTaskSyncService _customTaskSync = CustomTaskSyncService();

  // Study Services for scraping
  final VisionStudyService _visionService = VisionStudyService();
  final InsightsIASStudyService _insightsService = InsightsIASStudyService();
  final ChahalStudyService _chahalService = ChahalStudyService();
  final DrishtiStudyService _drishtiService = DrishtiStudyService();
  final NextIASStudyService _nextIasService = NextIASStudyService();
  final VajiramStudyService _vajiramService = VajiramStudyService();
  final VajiramSessionService _vajiramSession = VajiramSessionService();
  final InsightsQuizStudyService _insightsQuizService = InsightsQuizStudyService();

  // Cache and tracking for range-based sources
  final Set<String> _processedVajiramMonths = {};
  final Set<String> _processedInsightsQuizMonths = {};
  final Set<String> _processedChahalMonths = {};

  DashboardRepository();

  Future<Map<String, dynamic>> getDashboardData() async {
    return _isarService.fetchDashboardData();
  }

  Future<void> syncMonths(List<DateTime> months) async {
    for (var month in months) {
      await _contentSync.syncContentForMonth(month.year, month.month);
    }
  }

  /// Coordinated sync logic following strict sequence: Fetch -> Save Local -> Push to RTDB -> Update Metadata.
  Future<void> coordinatedSync(DateTime startDate, {
    bool forceRefresh = false,
    Function(String)? onStatusUpdate,
    bool Function()? shouldPause,
  }) async {
    // 0. Check connectivity
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.every((r) => r == ConnectivityResult.none)) {
      AppLogger.d("Sync skipped: No internet connection.");
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bool hasData = await _contentSync.hasGlobalData();
    
    DateTime syncPointer;
    if (!hasData) {
      onStatusUpdate?.call("Starting full global library backfill...");
      syncPointer = DateTime(startDate.year, startDate.month, startDate.day);
    } else {
      onStatusUpdate?.call("Checking incremental sync status...");
      final lastSyncTs = await _contentSync.getLastGlobalSyncTimestamp();
      DateTime lastSyncDate;
      
      if (lastSyncTs != null) {
        final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncTs);
        final difference = now.difference(lastSyncTime);

        // If it's fresh (less than 1 hour) and not a forced refresh, skip
        if (!forceRefresh && difference.inHours < 1) {
          AppLogger.d("Sync skipped: last sync was ${difference.inMinutes} minutes ago (less than 1 hour).");
          onStatusUpdate?.call("Sync skipped (Recently updated)");
          return;
        }

        // Safety: If lastSyncTime is future, use today
        if (lastSyncTime.isAfter(now)) {
          AppLogger.d("Sync warning: lastSyncTime is in the future. Resetting pointer to today.");
          lastSyncDate = today;
        } else {
          lastSyncDate = DateTime(lastSyncTime.year, lastSyncTime.month, lastSyncTime.day);
        }
      } else {
        // Fallback: if data exists but we don't know when it was last synced,
        // restart backfill from startDate to ensure nothing is missed.
        AppLogger.d("Sync warning: Global data exists but last_global_sync is missing. Restarting backfill from startDate.");
        lastSyncDate = startDate;
      }

      // Buffer of 3 days
      syncPointer = lastSyncDate.subtract(const Duration(days: 3));
      
      // Clamp to startDate
      if (syncPointer.isBefore(startDate)) {
        syncPointer = DateTime(startDate.year, startDate.month, startDate.day);
      }
    }

    // Perform the sync loop
    try {
      await syncAll(
        startDate, 
        onlyRecent: false, // We control the pointer ourselves
        forceRefresh: true, // Force to ensure we re-fetch the buffer
        onStatusUpdate: onStatusUpdate,
        shouldPause: shouldPause,
        customSyncPointer: syncPointer,
      );
      
      onStatusUpdate?.call("Finalizing sync metadata...");
      await _contentSync.updateLastGlobalSync();
    } catch (e) {
      AppLogger.e("Coordinated sync failed at loop stage", e);
      // Rethrow to let the provider handle specific errors like LOGIN_REQUIRED
      rethrow;
    }
  }

  /// Syncs all data from [startDate] to today.
  Future<void> syncAll(DateTime startDate, {
    bool forceRefresh = false, 
    bool onlyRecent = false, 
    Function(String)? onStatusUpdate, 
    bool Function()? shouldPause,
    DateTime? customSyncPointer,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Normalize startDate to midnight
    DateTime syncPointer = customSyncPointer ?? DateTime(startDate.year, startDate.month, startDate.day);

    if (customSyncPointer == null) {
      // Optimized sync window logic (legacy/default path)
      if (onlyRecent) {
        // Step 1: Check last global sync time from RTDB
        onStatusUpdate?.call("Checking global sync status...");
        final lastGlobalSyncTs = await _contentSync.getLastGlobalSyncTimestamp();
        
        DateTime lastSyncDate;
        if (lastGlobalSyncTs != null) {
          lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastGlobalSyncTs);
        } else {
          lastSyncDate = today.subtract(const Duration(days: 3));
        }

        // Step 2: Set window to (lastSyncDate - 3 days) to (Today)
        syncPointer = lastSyncDate.subtract(const Duration(days: 3));
        
        // Safety guard: don't sync before user's start date
        if (syncPointer.isBefore(startDate)) {
          syncPointer = DateTime(startDate.year, startDate.month, startDate.day);
        }
        
        // Safety guard: limit catch-up to 7 days if onlyRecent is true
        final sevenDaysAgo = today.subtract(const Duration(days: 7));
        if (syncPointer.isBefore(sevenDaysAgo)) {
          syncPointer = sevenDaysAgo;
        }
      } else if (forceRefresh) {
        // If full force refresh, migrate historical local data to RTDB first
        onStatusUpdate?.call("Migrating historical data to global library...");
        await _contentSync.pushLocalContentToRTDB(startDate, today);
      }
    }
    
    // Total days to sync for status reporting
    final totalDays = today.difference(syncPointer).inDays + 1;
    int processedDays = 0;

    AppLogger.d("Starting focused sync from ${DateFormatter.toIso(syncPointer)} to today ($totalDays days)");

    // Only sync from RTDB if we are NOT in a coordinated full backfill/sync
    // to avoid cycles and prioritize scraping for those cases.
    if (customSyncPointer == null) {
      // 0. Initial Fast Content Sync from RTDB (Optimized)
      final List<DateTime> monthsToSync = [];
      DateTime monthPointer = DateTime(syncPointer.year, syncPointer.month, 1);
      while (monthPointer.isBefore(today) || (monthPointer.year == today.year && monthPointer.month == today.month)) {
        monthsToSync.add(monthPointer);
        monthPointer = DateTime(monthPointer.year, monthPointer.month + 1, 1);
      }
      
      onStatusUpdate?.call("Syncing global content library...");
      await syncMonths(monthsToSync);
    }

    // 0. Pre-verify Vajiram Session
    final cookies = await _vajiramSession.getCookies();
    if (cookies != null && cookies.isNotEmpty) {
      onStatusUpdate?.call("Verifying Vajiram session...");
      final isValid = await _vajiramService.verifySession(cookies);
      if (!isValid) {
        AppLogger.d("Vajiram session invalid, throwing LOGIN_REQUIRED");
        throw Exception("LOGIN_REQUIRED");
      }
    }

    // Tracking for parallel execution
    _processedVajiramMonths.clear();
    _processedInsightsQuizMonths.clear();
    _processedChahalMonths.clear();

    while (syncPointer.isBefore(today) || syncPointer.isAtSameMomentAs(today)) {
      if (shouldPause?.call() ?? false) {
        AppLogger.d("Sync paused by UI request");
        break;
      }

      final isoDate = DateFormatter.toIso(syncPointer);
      final year = syncPointer.year;
      final month = syncPointer.month;
      final monthKey = "$year-$month";

      processedDays++;
      onStatusUpdate?.call("Syncing $isoDate ($processedDays/$totalDays)...");

      // 1. Parallel Fetching for the current date
      final List<Future<void>> scrapingTasks = [];

    // VisionIAS
    scrapingTasks.add(_scrapeSingleSource(syncPointer, isoDate, 'VisionIAS', () => _visionService.fetchByDate(isoDate)));

    // InsightsIAS
    scrapingTasks.add(_scrapeSingleSource(syncPointer, isoDate, 'InsightsIAS', () => _insightsService.fetchByDate(syncPointer)));

    // NextIAS
    scrapingTasks.add(_scrapeSingleSource(syncPointer, isoDate, 'NextIAS', () => _nextIasService.fetchByDate(isoDate)));

    // DrishtiIAS
    scrapingTasks.add(_scrapeSingleSource(syncPointer, isoDate, 'Drishti IAS', () => _drishtiService.fetchByDate(isoDate)));

    // Range-based sources (Process exactly once per month in the sync session)
    
    // Insights Quiz
    if (!_processedInsightsQuizMonths.contains(monthKey)) {
      scrapingTasks.add(_scrapeSingleSource(syncPointer, isoDate, 'InsightsIAS', () async {
        _processedInsightsQuizMonths.add(monthKey);
        return await _insightsQuizService.fetchForMonth(year, month, startDate: startDate);
      }));
    }

    // Vajiram
    if (!_processedVajiramMonths.contains(monthKey)) {
      scrapingTasks.add(_scrapeSingleSource(syncPointer, isoDate, 'Vajiram', () async {
        _processedVajiramMonths.add(monthKey);
        return await _vajiramService.fetch(year: year, month: month, maxPages: onlyRecent ? 2 : null, cookies: cookies);
      }));
    }

    // Chahal
    if (!_processedChahalMonths.contains(monthKey)) {
      scrapingTasks.add(_scrapeSingleSource(syncPointer, isoDate, 'Chahal Academy', () async {
        _processedChahalMonths.add(monthKey);
        return await _chahalService.fetch(year: year, month: month, startDate: startDate);
      }));
    }

      // Execute all scrapers in parallel for this date
      await Future.wait(scrapingTasks);

      // Move to next day
      syncPointer = syncPointer.add(const Duration(days: 1));
    }

    onStatusUpdate?.call("Syncing user progress...");
    await SyncManager().triggerSyncAll();

    // Final check for any local content not yet in RTDB
    onStatusUpdate?.call("Finalizing global sync...");
    final dirtyContent = await _contentSync.getDirtyDocs();
    
    if (dirtyContent.isNotEmpty) {
      AppLogger.d("Found ${dirtyContent.length} local items to push to global library");
      for (var doc in dirtyContent) {
        // originalDocId is in format: sourceId_dateStr
        await _contentSync.sync(doc.originalDocId);
      }
    }

    AppLogger.d("Comprehensive sync complete.");
  }

  Future<void> _scrapeSingleSource(DateTime pointerDate, String isoDate, String sourceId, Future<dynamic> Function() fetcher) async {
    try {
      final data = await fetcher();
      
      List<DailyStudyData> resultsList = [];
      if (data is DailyStudyData) {
        resultsList = [data];
      } else if (data is List<DailyStudyData>) {
        resultsList = data;
      } else if (data is List) {
        resultsList = data.whereType<DailyStudyData>().toList();
      }

      if (resultsList.isEmpty) return;

      // Group all new items by date for batched processing
      final Map<String, List<LocalContent>> itemsByDate = {};
      
      for (var daily in resultsList) {
        final dailyIsoDate = daily.date;
        final List<LocalContent> dailyItems = [];
        
        // Articles
        for (var article in daily.items) {
          final articleId = article.url?.hashCode.toString() ?? article.title.hashCode.toString();
          final effectiveSourceId = article.source ?? sourceId;
          dailyItems.add(LocalContent()
            ..contentId = articleId
            ..type = 'article'
            ..year = dailyIsoDate.split('-')[0]
            ..month = dailyIsoDate.split('-')[1]
            ..date = dailyIsoDate
            ..sourceId = effectiveSourceId
            ..title = article.title
            ..subtitle = article.subtitle
            ..url = article.url
            ..lastFetchedAt = DateTime.now());
        }

        // Quizzes
        for (var quiz in daily.quizzes) {
          final quizId = quiz.title.hashCode.toString();
          final effectiveSourceId = quiz.source ?? sourceId;
          dailyItems.add(LocalContent()
            ..contentId = quizId
            ..type = 'quiz'
            ..year = dailyIsoDate.split('-')[0]
            ..month = dailyIsoDate.split('-')[1]
            ..date = dailyIsoDate
            ..sourceId = effectiveSourceId
            ..title = quiz.title
            ..url = quiz.url
            ..lastFetchedAt = DateTime.now());
        }

        if (dailyItems.isNotEmpty) {
          itemsByDate.putIfAbsent(dailyIsoDate, () => []).addAll(dailyItems);
        }
      }

      // 2. Batched Save and Batched RTDB Push
      for (var entry in itemsByDate.entries) {
        final date = entry.key;
        final items = entry.value;

        // Sequence: Save Local -> Push to RTDB
        await _contentSync.saveLocalContent(items);

        // Group by actual sourceId for markContentDirty
        final Set<String> uniqueSources = items.map((i) => i.sourceId).toSet();
        for (var sid in uniqueSources) {
          await _contentSync.markContentDirty(sid, date);
          // Immediate upload to RTDB for this source/date
          await _contentSync.sync("${sid}_$date");
        }
      }
    } catch (e) {
      AppLogger.e("Failed to scrape source $sourceId", e);
      rethrow;
    }
  }

  Future<void> markArticleCompleted(String sourceId, String year, String monthId, String date, String articleId) async {
    await _progressSync.markArticleCompleted(
      sourceId: sourceId,
      year: year,
      monthId: monthId,
      date: date,
      articleId: articleId,
    );
    // 🟢 Immediate sync
    unawaited(_progressSync.sync("${year}_$monthId"));
    SyncManager().resetIdleTimer();
  }

  Future<void> markQuizCompleted(String sourceId, String year, String monthId, String date, String quizId) async {
    await _progressSync.markQuizCompleted(
      sourceId: sourceId,
      year: year,
      monthId: monthId,
      date: date,
      quizId: quizId,
    );
    // 🟢 Immediate sync
    unawaited(_progressSync.sync("${year}_$monthId"));
    SyncManager().resetIdleTimer();
  }

  Future<void> addCustomTask(String isoDate, ArticleModel item) async {
    await _customTaskSync.addCustomTask(isoDate, item);
    // 🟢 Immediate sync
    final date = DateTime.tryParse(isoDate);
    if (date != null) {
      final documentId = "${date.year}_${date.month.toString().padLeft(2, '0')}";
      unawaited(_customTaskSync.sync(documentId));
    }
    SyncManager().resetIdleTimer();
  }

  Future<void> syncCustomTasks(String isoDate) async {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return;
    final documentId = "${date.year}_${date.month.toString().padLeft(2, '0')}";
    await _customTaskSync.sync(documentId);
  }

  Future<void> deleteCustomTask(String isoDate, String articleUrl) async {
    await _customTaskSync.deleteCustomTask(isoDate, articleUrl);
    // 🟢 Immediate sync
    final date = DateTime.tryParse(isoDate);
    if (date != null) {
      final documentId = "${date.year}_${date.month.toString().padLeft(2, '0')}";
      unawaited(_customTaskSync.sync(documentId));
    }
    SyncManager().resetIdleTimer();
  }

  Future<void> downloadAllCustomTasks() async {
    await _customTaskSync.downloadAll();
  }
}
