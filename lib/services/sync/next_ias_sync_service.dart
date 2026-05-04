import '../next_ias_study_service.dart';
import '../../models/study_item_model.dart';
import 'base_sync_service.dart';

class NextIASSyncService extends BaseSyncService {
  final NextIASStudyService _studyService = NextIASStudyService();

  NextIASSyncService() : super(sourceName: 'NextIAS');

  @override
  Future<List<DailyStudyData>> fetchFromNetwork(int year, int month, {DateTime? startDate, Function(String)? onStatusUpdate}) async {
    final List<DailyStudyData> allDays = [];
    final now = DateTime.now();
    
    // Find how many days are in this month.
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

      // Format for NextIAS URL: dd-mm-yyyy
      final dateStr = "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year";
      
      final dailyData = await _studyService.fetchByDate(dateStr, onStatusUpdate: onStatusUpdate);
      if (dailyData != null) {
        allDays.add(dailyData);
      }
      
      // Small delay to prevent rate limiting
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return allDays;
  }

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
