import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';
import '../services/synced_dashboard_service.dart';
import '../services/sync/vajiram_sync_service.dart';
import '../services/sync/vision_sync_service.dart';
import '../services/sync/next_ias_sync_service.dart';
import '../services/sync/insights_ias_sync_service.dart';
import '../services/profile_service.dart';

class DashboardProvider with ChangeNotifier {
  DashboardData? _data;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  String? _syncStatus;
  DashboardService _service = SyncedDashboardService(EmptyDashboardService());
  final VajiramSyncService _vajiramSync = VajiramSyncService();
  final VisionSyncService _visionSync = VisionSyncService();
  final NextIASSyncService _nextIasSync = NextIASSyncService();
  final InsightsIASSyncService _insightsIasSync = InsightsIASSyncService();

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String? get syncStatus => _syncStatus;
  DashboardService get service => _service;

  /// Updates the service source and reloads data.
  void setService(DashboardService newService) {
    _service = newService;
    loadDashboardData();
  }

  /// Switches to Firestore service.
  void switchToFirestore() {
    setService(FirestoreDashboardService());
  }

  /// Switches to Local service (empty base, synced Vajiram data).
  void switchToLocal() {
    setService(SyncedDashboardService(EmptyDashboardService()));
  }

  /// Syncs all configured article sources.
  Future<void> syncAllArticles({bool forceRefresh = false}) async {
    _isSyncing = true;
    _syncStatus = forceRefresh ? 'Force refreshing sources...' : 'Starting sync...';
    notifyListeners();

    try {
      final profile = await ProfileService().getProfile();
      if (profile != null) {
        // Sync Vajiram
        await _vajiramSync.syncArticles(
          startDate: profile.startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) {
            _syncStatus = "[Vajiram] $status";
            notifyListeners();
          },
        );

        // Sync VisionIAS
        await _visionSync.syncArticles(
          startDate: profile.startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) {
            _syncStatus = "[Vision] $status";
            notifyListeners();
          },
        );

        // Sync NextIAS
        await _nextIasSync.syncArticles(
          startDate: profile.startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) {
            _syncStatus = "[NextIAS] $status";
            notifyListeners();
          },
        );

        // Sync InsightsIAS
        await _insightsIasSync.syncArticles(
          startDate: profile.startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) {
            _syncStatus = "[InsightsIAS] $status";
            notifyListeners();
          },
        );

        // Reload data after sync
        await loadDashboardData();
      } else {
        _error = "Profile not found. Please setup profile first.";
      }
    } catch (e) {
      _error = "Sync failed: $e";
    } finally {
      _isSyncing = false;
      _syncStatus = null;
      notifyListeners();
    }
  }

  /// Fetches dashboard data using the current service.
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _service.fetchDashboardData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
