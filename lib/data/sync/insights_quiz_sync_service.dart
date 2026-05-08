import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/data/services/insights_quiz_study_service.dart';
import 'package:upsc_ca_ui/data/sync/base_sync_service.dart';

class InsightsQuizSyncService extends BaseSyncService {
  final InsightsQuizStudyService _studyService = InsightsQuizStudyService();

  InsightsQuizSyncService() : super(sourceName: 'InsightsIAS Quiz');

  @override
  Future<List<DailyStudyData>> fetchFromNetwork(int year, int month, {DateTime? startDate, Function(String)? onStatusUpdate}) async {
    return _studyService.fetchForMonth(year, month, startDate: startDate);
  }

  Future<Map<String, List<ArticleModel>>> getSyncedArticles() async {
    return getAllSyncedArticles();
  }

  Future<Map<String, List<QuizModel>>> getSyncedQuizzes() async {
    return getAllSyncedQuizzes();
  }
}
