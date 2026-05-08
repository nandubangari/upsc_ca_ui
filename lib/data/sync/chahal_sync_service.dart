import 'package:upsc_ca_ui/data/services/chahal_study_service.dart';
import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';
import 'package:upsc_ca_ui/data/sync/base_sync_service.dart';

class ChahalSyncService extends BaseSyncService {
  final ChahalStudyService _studyService = ChahalStudyService();

  ChahalSyncService() : super(sourceName: 'Chahal Academy');

  @override
  Future<List<DailyStudyData>> fetchFromNetwork(int year, int month, {DateTime? startDate, Function(String)? onStatusUpdate}) async {
    return _studyService.fetch(
      year: year,
      month: month,
      startDate: startDate,
      onStatusUpdate: onStatusUpdate,
    );
  }

  Future<void> syncQuizzes({
    required DateTime startDate,
    bool forceRefresh = false,
    Function(String)? onStatusUpdate,
  }) async {
    await syncRange(startDate: startDate, forceRefresh: forceRefresh, onStatusUpdate: onStatusUpdate);
  }
}
