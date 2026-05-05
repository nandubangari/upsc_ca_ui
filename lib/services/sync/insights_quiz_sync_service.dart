import '../insights_quiz_study_service.dart';
import '../../models/study_item_model.dart';
import '../../models/dashboard_data.dart';
import 'base_sync_service.dart';

class InsightsQuizSyncService extends BaseSyncService {
  final InsightsQuizStudyService _studyService = InsightsQuizStudyService();

  InsightsQuizSyncService() : super(sourceName: 'InsightsIAS Quiz');

  @override
  Future<List<DailyStudyData>> fetchFromNetwork(int year, int month, {DateTime? startDate, Function(String)? onStatusUpdate}) async {
    return await _studyService.fetchForMonth(year, month, startDate: startDate);
  }

  Future<Map<String, List<StudyItem>>> getSyncedArticles() async {
    return await getAllSyncedArticles();
  }

  Future<Map<String, List<QuizDetail>>> getSyncedQuizzes() async {
    return await getAllSyncedQuizzes();
  }
}
