import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../models/profile_data.dart';
import '../services/dashboard_service.dart';
import '../services/synced_dashboard_service.dart';
import '../services/sync/vajiram_sync_service.dart';
import '../services/sync/vision_sync_service.dart';
import '../services/sync/next_ias_sync_service.dart';
import '../services/sync/insights_ias_sync_service.dart';
import '../services/sync/chahal_sync_service.dart';
import '../services/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardProvider with ChangeNotifier {
  DashboardData? _data;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  String? _syncStatus;
  bool _needsVajiramLogin = false;
  DashboardService _service = SyncedDashboardService(EmptyDashboardService());
  final VajiramSyncService _vajiramSync = VajiramSyncService();
  final VisionSyncService _visionSync = VisionSyncService();
  final NextIASSyncService _nextIasSync = NextIASSyncService();
  final InsightsIASSyncService _insightsIasSync = InsightsIASSyncService();
  final ChahalSyncService _chahalSync = ChahalSyncService();

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String? get syncStatus => _syncStatus;
  bool get needsVajiramLogin => _needsVajiramLogin;
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

  void setNeedsVajiramLogin(bool value) {
    _needsVajiramLogin = value;
    notifyListeners();
  }

  /// Syncs all configured article sources.
  Future<void> syncAllArticles({bool forceRefresh = false, bool isRetryAfterLogin = false}) async {
    _isSyncing = true;
    _syncStatus = isRetryAfterLogin ? 'Retrying sync after login...' : (forceRefresh ? 'Force refreshing sources...' : 'Starting sync...');
    print('DEBUG: [DashboardProvider] syncAllArticles called (forceRefresh: $forceRefresh, isRetry: $isRetryAfterLogin)');
    notifyListeners();

    try {
      final profile = await ProfileService().getProfile();
      if (profile != null) {
        // Sync Vajiram
        try {
          await _vajiramSync.syncArticles(
            startDate: profile.startDate,
            forceRefresh: forceRefresh,
            onStatusUpdate: (status) {
              _syncStatus = "[Vajiram] $status";
              notifyListeners();
            },
          );
        } catch (e) {
          if (e.toString().contains("LOGIN_REQUIRED")) {
            _needsVajiramLogin = true;
            _syncStatus = "[Vajiram] Login Required";
            notifyListeners();
            // We don't rethrow here to allow other sources to sync if possible, 
            // but we stop the Vajiram specific sync and notify UI.
          } else {
            rethrow;
          }
        }

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

        // Sync Chahal Academy
        await _chahalSync.syncQuizzes(
          startDate: profile.startDate,
          forceRefresh: forceRefresh,
          onStatusUpdate: (status) {
            _syncStatus = "[Chahal] $status";
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

  /// Updates the target exam date.
  Future<void> updateExamDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final profile = await ProfileService().getProfile();
      if (profile != null) {
        final updatedProfile = ProfileData(
          name: profile.name,
          startDate: profile.startDate,
          articleSources: profile.articleSources,
          quizSources: profile.quizSources,
          repetitionDays: profile.repetitionDays,
          availableDays: profile.availableDays,
          themeColorValue: profile.themeColorValue,
          examDate: date,
        );
        
        await ProfileService().saveProfileToCloud(user.uid, updatedProfile);
        await loadDashboardData();
      }
    } catch (e) {
      print("Error updating exam date: $e");
    }
  }
}
