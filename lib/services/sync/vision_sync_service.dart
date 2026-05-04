import '../vision_study_service.dart';
import '../../models/study_item_model.dart';
import 'base_sync_service.dart';

class VisionSyncService extends BaseSyncService {
  final VisionStudyService _studyService = VisionStudyService();

  VisionSyncService() : super(sourceName: 'VisionIAS');

  @override
  Future<List<DailyStudyData>> fetchFromNetwork(int year, int month, {DateTime? startDate, Function(String)? onStatusUpdate}) async {
    final List<DailyStudyData> allDays = [];
    final now = DateTime.now();
    
    // VisionIAS is fetched day by day. We need to find how many days are in this month.
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      
      // Skip future dates
      if (date.isAfter(now)) continue;

      // Skip dates before the start date
      if (startDate != null) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
        if (normalizedDate.isBefore(normalizedStartDate)) continue;
      }

      final dateStr = "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
      
      final dailyData = await _studyService.fetchByDate(dateStr, onStatusUpdate: onStatusUpdate);
      if (dailyData != null) {
        allDays.add(dailyData);
      }
      
      // Small delay to prevent rate limiting
      await Future.delayed(const Duration(milliseconds: 200));
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

  Future<Map<String, List<StudyItem>>> getSyncedArticles() async {
    return await getAllSyncedArticles();
  }
}
