import '../vajiram_study_service.dart';
import '../../models/study_item_model.dart';
import 'base_sync_service.dart';

class VajiramSyncService extends BaseSyncService {
  final VajiramStudyService _studyService = VajiramStudyService();

  VajiramSyncService() : super(sourceName: 'Vajiram');

  @override
  Future<List<DailyStudyData>> fetchFromNetwork(int year, int month, {DateTime? startDate, Function(String)? onStatusUpdate}) async {
    return await _studyService.fetch(
      year: year,
      month: month,
      onStatusUpdate: onStatusUpdate,
    );
  }

  // Helper for backward compatibility or direct calls if needed
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
