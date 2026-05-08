import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/data/services/vajiram_study_service.dart';
import 'package:upsc_ca_ui/data/services/vajiram_session_service.dart';
import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/data/sync/base_sync_service.dart';

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
      AppLogger.d("[VajiramSyncService] Network fetch failed for $year/$month: $e");
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

  Future<Map<String, List<ArticleModel>>> getSyncedArticles() async {
    return getAllSyncedArticles();
  }
}


