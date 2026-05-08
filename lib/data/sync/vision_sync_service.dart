import 'package:upsc_ca_ui/data/services/vision_study_service.dart';
import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/data/sync/base_sync_service.dart';

class VisionSyncService extends BaseSyncService {
  final VisionStudyService _studyService = VisionStudyService();

  VisionSyncService() : super(sourceName: 'VisionIAS');

  @override
  Future<List<DailyStudyData>> fetchFromNetwork(int year, int month, {DateTime? startDate, Function(String)? onStatusUpdate}) async {
    final List<DailyStudyData> allDays = [];
    final now = DateTime.now();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    final List<String> targetDates = [];
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (date.isAfter(now)) continue;

      if (startDate != null) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
        if (normalizedDate.isBefore(normalizedStartDate)) continue;
      }
      targetDates.add("$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}");
    }

    // Parallelize with concurrency limit to respect VisionIAS servers while speeding up
    const int batchSize = 5;
    for (int i = 0; i < targetDates.length; i += batchSize) {
      final batch = targetDates.skip(i).take(batchSize).toList();
      final results = await Future.wait(batch.map((d) => _studyService.fetchByDate(d, onStatusUpdate: onStatusUpdate)));
      allDays.addAll(results.whereType<DailyStudyData>());
      
      // Small pause between batches
      if (i + batchSize < targetDates.length) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    return allDays;
  }

  // Helper for direct calls if needed
  Future<void> syncArticles({
    required DateTime startDate,
    bool forceRefresh = false,
    Function(String)? onStatusUpdate,
  }) async {
    await syncRange(startDate: startDate, forceRefresh: forceRefresh, onStatusUpdate: onStatusUpdate);
  }

  Future<Map<String, List<ArticleModel>>> getSyncedArticles() async {
    return getAllSyncedArticles();
  }
}
