import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/data/local/isar_service.dart';
import 'package:upsc_ca_ui/data/local/models/local_sync_metadata.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'progress_sync_service.dart';
import 'repetition_sync_service.dart';
import 'profile_sync_service.dart';
import 'content_sync_service.dart';
import 'custom_task_sync_service.dart';

enum SyncEventType { initialSyncComplete, userDataSyncComplete, progressUpdate }

class SyncEvent {
  final SyncEventType type;
  final double? progress;
  final String? status;
  SyncEvent(this.type, {this.progress, this.status});
}

class SyncManager with WidgetsBindingObserver {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final ProgressSyncService _progressSync = ProgressSyncService();
  final RepetitionSyncService _repetitionSync = RepetitionSyncService();
  final ProfileSyncService _profileSync = ProfileSyncService();
  final ContentSyncService _contentSync = ContentSyncService();
  final CustomTaskSyncService _customTaskSync = CustomTaskSyncService();

  final Isar _isar = IsarService.isar;
  Timer? _safetyTimer;
  Timer? _idleTimer;
  
  bool _initialized = false;
  bool _isSyncingUserData = false;
  bool _isInitialSyncInProgress = false;
  bool _isIncrementalSyncInProgress = false;
  Completer<void>? _syncCompleter;
  
  bool get isInitialSyncInProgress => _isInitialSyncInProgress;

  final _eventController = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get events => _eventController.stream;

  void init() {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);
    
    // 1. Listen for auth changes to trigger sync
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        AppLogger.d("User logged in. Checking sync status...");
        unawaited(checkSyncStatus());
      }
    });

    // 2. Listen for profile setup completion
    ProfileService.onSetupComplete.listen((complete) {
      if (complete) {
        AppLogger.d("Profile setup complete detected. Triggering sync check...");
        unawaited(checkSyncStatus());
      }
    });

    // 3. Defer connectivity listener and initial checks
    unawaited(Future.microtask(() async {
      Connectivity().onConnectivityChanged.listen((results) {
        if (results.any((r) => r != ConnectivityResult.none)) {
          AppLogger.d("Internet restored. Triggering sync...");
          unawaited(checkSyncStatus());
          unawaited(triggerSyncAll());
        }
      });

      await checkSyncStatus();
    }));

    _safetyTimer = Timer.periodic(const Duration(minutes: 30), (_) => unawaited(triggerSyncAll()));
  }

  /// Public entry point to check and trigger all sync types based on readiness
  Future<void> checkSyncStatus() async {
    if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
      AppLogger.d("Sync: checkSyncStatus already in progress, awaiting existing future...");
      return _syncCompleter!.future;
    }
    
    final isReady = await ProfileService().isProfileSetupComplete();
    if (!isReady) {
      AppLogger.d("Skip sync checks: Profile setup not complete.");
      return;
    }

    _syncCompleter = Completer<void>();
    AppLogger.d("Sync: Starting comprehensive status check...");
    try {
      await Future.wait([
        _checkInitialContentSync(),
        _checkIncrementalContentUpdate(),
        _syncUserData(),
      ]);
      AppLogger.d("Sync: All status checks complete.");
      if (!_syncCompleter!.isCompleted) _syncCompleter!.complete();
    } catch (e, stack) {
      AppLogger.e("Sync: Status check failed", e, stack);
      if (!_syncCompleter!.isCompleted) _syncCompleter!.completeError(e);
    } finally {
      // We don't reset _syncCompleter to null immediately to allow latecomers to get the completed future
    }
  }

  Future<void> _checkIncrementalContentUpdate() async {
    if (_isIncrementalSyncInProgress) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.d("Skip incremental sync: No user logged in.");
      return;
    }

    _isIncrementalSyncInProgress = true;
    _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: 0.05, status: "Checking for new content..."));
    
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.every((r) => r == ConnectivityResult.none)) return;

      AppLogger.d("Sync: Checking for incremental content updates from RTDB...");
      
      final remoteTimestamp = await _contentSync.getLastGlobalSyncTimestamp();
      if (remoteTimestamp == null) return;

      final prefs = await SharedPreferences.getInstance();
      final localTimestamp = prefs.getInt('local_last_global_sync') ?? 0;

      if (remoteTimestamp > localTimestamp) {
        AppLogger.d("Sync: New remote content detected ($remoteTimestamp > $localTimestamp). Starting incremental sync...");
        _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: 0.1, status: "Fetching latest articles..."));
        
        // Find which months need syncing. For simplicity, we sync the last 2 months if there's an update.
        final now = DateTime.now();
        final months = [
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month - 1, 1),
        ];

        for (int i = 0; i < months.length; i++) {
          final month = months[i];
          final progress = 0.1 + (i / months.length) * 0.1;
          _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: progress, status: "Updating content for ${_getMonthName(month.month)}..."));
          await _contentSync.syncContentForMonth(month.year, month.month);
        }

        // Update local timestamp
        await prefs.setInt('local_last_global_sync', remoteTimestamp);
        AppLogger.d("Sync: Incremental content sync complete. Broadcast triggered.");
        _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: 0.25, status: "Content updated!"));
        _eventController.add(SyncEvent(SyncEventType.initialSyncComplete)); // Reuse this event to trigger Dashboard reload
      } else {
        AppLogger.d("Sync: No new remote content detected ($remoteTimestamp <= $localTimestamp).");
        _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: 0.25, status: "Content is up to date"));
      }
    } catch (e) {
      AppLogger.e("Sync: Incremental content check failed", e);
    } finally {
      _isIncrementalSyncInProgress = false;
    }
  }

  Future<void> _checkInitialContentSync() async {
    if (_isInitialSyncInProgress) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.d("Skip initial sync: No user logged in.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool isFullSynced = prefs.getBool('is_full_library_synced_v1') ?? false;

    if (!isFullSynced) {
      _isInitialSyncInProgress = true;
      AppLogger.d("Local content full sync missing. Triggering full global library download...");
      _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: 0.1, status: "Connecting to global library..."));
      
      // 1. Download Global Library
      try {
        await _contentSync.downloadAllGlobalContent(onProgress: (p, s) {
          _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: 0.1 + (p * 0.5), status: s));
        });
      } catch (e) {
        AppLogger.e("Full library download failed", e);
      }
      
      // Update local timestamp and full sync flag after full download
      final remoteTimestamp = await _contentSync.getLastGlobalSyncTimestamp();
      if (remoteTimestamp != null) {
        await prefs.setInt('local_last_global_sync', remoteTimestamp);
      }
      await prefs.setBool('is_full_library_synced_v1', true);
      
      // 2. Download User Private Data
      _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: 0.7, status: "Synchronizing your progress..."));
      await _syncUserData();

      _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: 1.0, status: "Synchronization complete!"));
      AppLogger.d("DEBUG: Initial sync broadcast triggered.");
      _isInitialSyncInProgress = false;
      _eventController.add(SyncEvent(SyncEventType.initialSyncComplete));
    } else {
      AppLogger.d("Global library already fully synced. Ensuring listeners are unblocked.");
      // ALWAYS broadcast completion so DashboardProvider doesn't hang if localCount is 0 for some reason
      _eventController.add(SyncEvent(SyncEventType.initialSyncComplete));
    }
  }

  Future<void> _syncUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isSyncingUserData) {
      AppLogger.d("Sync: User data sync already in progress. Skipping.");
      return;
    }

    _isSyncingUserData = true;
    AppLogger.d("Sync: Pulling user data (progress, repetitions, custom tasks) on startup...");
    _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: 0.3, status: "Synchronizing your progress..."));
    
    try {
      // Parallel pull for all user collections
      final tasks = [
        _profileSync.download('main'),
        _progressSync.downloadAll(),
        _repetitionSync.downloadAll(),
        _customTaskSync.downloadAll(),
      ];

      // We wrap them to report progress as they complete
      int completedCount = 0;
      final wrappedTasks = tasks.map((t) => t.then((_) {
        completedCount++;
        final progress = 0.3 + (completedCount / tasks.length) * 0.6; // 30% to 90%
        _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: progress, status: "Syncing user data ($completedCount/${tasks.length})..."));
      }));

      await Future.wait(wrappedTasks);
      
      AppLogger.d("Sync: User data pull complete.");
      _eventController.add(SyncEvent(SyncEventType.progressUpdate, progress: 1.0, status: "Synchronization complete!"));
      _eventController.add(SyncEvent(SyncEventType.userDataSyncComplete));
    } catch (e) {
      AppLogger.e("Sync: User data pull failed", e);
    } finally {
      _isSyncingUserData = false;
    }
  }

  void dispose() {
    _eventController.close();
    WidgetsBinding.instance.removeObserver(this);
    _safetyTimer?.cancel();
    _idleTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      AppLogger.d("App lifecycle change: $state. Triggering background sync...");
      // Use unawaited to avoid blocking the lifecycle transition itself
      unawaited(triggerSyncAll());
    }
  }

  void resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(minutes: 5), () {
      AppLogger.d("User idle for 5 minutes. Triggering sync...");
      unawaited(triggerSyncAll());
    });
  }

  Future<void> triggerSyncAll() async {
    final isReady = await ProfileService().isProfileSetupComplete();
    if (!isReady) return;

    final dirtyDocs = await _isar.localSyncMetadatas.filter().isDirtyEqualTo(true).findAll();
    
    if (dirtyDocs.isEmpty) {
      AppLogger.d("Sync: No dirty documents found.");
      return;
    }

    AppLogger.d("Sync: Found ${dirtyDocs.length} dirty documents across collections. Starting batch upload...");

    final List<Future<void>> syncTasks = [
      _syncCollection(_progressSync),
      _syncCollection(_repetitionSync),
      _syncCollection(_profileSync),
      _syncCollection(_contentSync),
      _syncCollection(_customTaskSync),
    ];

    await Future.wait(syncTasks);
    AppLogger.d("Sync: Batch upload session complete.");
  }

  Future<void> _syncCollection(dynamic service) async {
    final dirty = await _isar.localSyncMetadatas
        .filter()
        .collectionEqualTo(service.collectionName)
        .isDirtyEqualTo(true)
        .findAll();

    for (var doc in dirty) {
      await service.sync(doc.originalDocId);
    }
  }

  String _getMonthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    if (month < 1 || month > 12) return month.toString();
    return months[month - 1];
  }
}
