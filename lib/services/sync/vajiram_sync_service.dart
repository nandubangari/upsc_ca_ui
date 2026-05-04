import '../vajiram_study_service.dart';
import '../vajiram_session_service.dart';
import '../../models/study_item_model.dart';
import 'base_sync_service.dart';

class VajiramSyncService extends BaseSyncService {
  final VajiramStudyService _studyService = VajiramStudyService();
  final VajiramSessionService _sessionService = VajiramSessionService();

  VajiramSyncService() : super(sourceName: 'Vajiram');

  @override
  Future<List<DailyStudyData>> fetchFromNetwork(int year, int month, {DateTime? startDate, Function(String)? onStatusUpdate}) async {
    final cookies = await _sessionService.getCookies();

    try {
      final data = await _studyService.fetch(
        year: year,
        month: month,
        cookies: cookies,
        onStatusUpdate: onStatusUpdate,
      );
      return data;
    } catch (e) {
      print('DEBUG: [VajiramSyncService] Network fetch failed for $year/$month: $e');
      if (e.toString().contains("LOGIN_REQUIRED")) {
        rethrow; // This will trigger needsVajiramLogin in DashboardProvider
      }
      return [];
    }
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
