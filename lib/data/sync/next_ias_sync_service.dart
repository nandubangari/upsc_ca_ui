import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/data/services/next_ias_study_service.dart';
import 'package:upsc_ca_ui/data/sync/base_sync_service.dart';

class NextIASSyncService extends BaseSyncService {
  final NextIASStudyService _studyService = NextIASStudyService();

  NextIASSyncService() : super(sourceName: 'NextIAS');

  @override
  Future<List<DailyStudyData>> fetchFromNetwork(int year, int month, {DateTime? startDate, Function(String)? onStatusUpdate}) async {
    final List<DailyStudyData> allDays = [];
    final now = DateTime.now();
    
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      
      if (date.isAfter(now)) continue;

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
