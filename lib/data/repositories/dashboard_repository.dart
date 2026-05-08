import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_data.dart';
import 'package:upsc_ca_ui/data/services/dashboard_service.dart';
import 'package:upsc_ca_ui/data/services/synced_dashboard_service.dart';
import 'package:upsc_ca_ui/data/sync/base_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/vajiram_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/vision_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/next_ias_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/insights_ias_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/chahal_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/drishti_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/insights_quiz_sync_service.dart';
import 'package:upsc_ca_ui/data/sync/user_task_sync_service.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';

class DashboardRepository {
  final DashboardService _baseService;
  late final SyncedDashboardService _syncedService;
  
  final VajiramSyncService _vajiramSync = VajiramSyncService();
  final VisionSyncService _visionSync = VisionSyncService();
  final NextIASSyncService _nextIasSync = NextIASSyncService();
  final InsightsIASSyncService _insightsIasSync = InsightsIASSyncService();
  final ChahalSyncService _chahalSync = ChahalSyncService();
  final DrishtiSyncService _drishtiSync = DrishtiSyncService();
  final InsightsQuizSyncService _insightsQuizSync = InsightsQuizSyncService();
  final UserTaskSyncService _userTaskSync = UserTaskSyncService();

  DashboardRepository({DashboardService? baseService}) 
      : _baseService = baseService ?? FirestoreDashboardService() {
    _syncedService = SyncedDashboardService(_baseService);
  }

  Future<DashboardData> getDashboardData({bool syncEnabled = true}) async {
    if (syncEnabled) {
      return _syncedService.fetchDashboardData();
    } else {
      return _baseService.fetchDashboardData();
    }
  }

  Future<void> syncAll(DateTime startDate, {bool forceRefresh = false, Function(String)? onStatusUpdate}) async {
    final List<BaseSyncService> services = [
      _vajiramSync,
      _visionSync,
      _nextIasSync,
      _insightsIasSync,
      _chahalSync,
      _drishtiSync,
      _insightsQuizSync,
    ];

    final List<Future<void>> syncFutures = services.map((service) async {
      try {
        await service.syncRange(
          startDate: startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) => onStatusUpdate?.call("[${service.sourceName}] $status"),
        );
      } catch (e) {
        if (service == _vajiramSync && e.toString().contains("LOGIN_REQUIRED")) {
          rethrow;
        }
        AppLogger.e("[DashboardRepository] ${service.sourceName} sync failed", e);
      }
    }).toList();

    await Future.wait(syncFutures);
  }

  Future<void> addCustomTask(String isoDate, ArticleModel item) async {
    await _userTaskSync.addCustomTask(isoDate, item);
  }

  // Helper to get the correct sync service for a source
  BaseSyncService? getSyncServiceForSource(String? sourceName, {bool isCustom = false}) {
    if (isCustom) return _userTaskSync;
    if (sourceName == null) return null;
    final lowerSource = sourceName.toLowerCase();
    if (lowerSource.contains('vajiram')) return _vajiramSync;
    if (lowerSource.contains('vision')) return _visionSync;
    if (lowerSource.contains('nextias')) return _nextIasSync;
    if (lowerSource.contains('insights') && lowerSource.contains('quiz')) return _insightsQuizSync;
    if (lowerSource.contains('insights')) return _insightsIasSync;
    if (lowerSource.contains('chahal')) return _chahalSync;
    if (lowerSource.contains('drishti')) return _drishtiSync;
    return null;
  }
}
