import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/data/services/insights_ias_study_service.dart';
import 'package:upsc_ca_ui/data/sync/base_sync_service.dart';

class InsightsIASSyncService extends BaseSyncService {
  final InsightsIASStudyService _studyService = InsightsIASStudyService();

  InsightsIASSyncService() : super(sourceName: 'InsightsIAS');

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

      final dailyData = await _studyService.fetchByDate(date, onStatusUpdate: onStatusUpdate);
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

  Future<Map<String, List<ArticleModel>>> getSyncedArticles() async {
    return getAllSyncedArticles();
  }

  Future<Map<String, List<QuizModel>>> getSyncedQuizzes() async {
    return getAllSyncedQuizzes();
  }
}
