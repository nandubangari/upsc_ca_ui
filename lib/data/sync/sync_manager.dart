import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/data/local/isar_service.dart';
import 'package:upsc_ca_ui/data/local/models/local_content.dart';
import 'package:upsc_ca_ui/data/local/models/local_sync_metadata.dart';
import 'progress_sync_service.dart';
import 'repetition_sync_service.dart';
import 'profile_sync_service.dart';
import 'content_sync_service.dart';
import 'custom_task_sync_service.dart';

enum SyncEventType { initialSyncComplete, userDataSyncComplete }

class SyncEvent {
  final SyncEventType type;
  SyncEvent(this.type);
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
  
  bool _isSyncingUserData = false;

  final _eventController = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get events => _eventController.stream;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    
    // 1. Listen for auth changes to trigger sync
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        AppLogger.d("User logged in. Checking sync status...");
        unawaited(_checkInitialContentSync());
        unawaited(_syncUserData());
      }
    });

    // 2. Defer connectivity listener and initial checks to avoid blocking startup frames
    unawaited(Future.microtask(() async {
      // Connectivity listener
      Connectivity().onConnectivityChanged.listen((results) {
        if (results.any((r) => r != ConnectivityResult.none)) {
          AppLogger.d("Internet restored. Triggering sync...");
          unawaited(triggerSyncAll());
          unawaited(_syncUserData());
          unawaited(_checkIncrementalContentUpdate());
        }
      });

      // Initial content check (Download global content if local is empty)
      await _checkInitialContentSync();
      
      // Incremental content check (Check if RTDB has new data)
      await _checkIncrementalContentUpdate();
      
      // Also pull latest user specific data (progress, custom tasks, repetitions)
      await _syncUserData();
    }));

    _safetyTimer = Timer.periodic(const Duration(minutes: 30), (_) => unawaited(triggerSyncAll()));
  }

  Future<void> _checkIncrementalContentUpdate() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.every((r) => r == ConnectivityResult.none)) return;

    AppLogger.d("Sync: Checking for incremental content updates from RTDB...");
    
    try {
      final remoteTimestamp = await _contentSync.getLastGlobalSyncTimestamp();
      if (remoteTimestamp == null) return;

      final prefs = await SharedPreferences.getInstance();
      final localTimestamp = prefs.getInt('local_last_global_sync') ?? 0;

      if (remoteTimestamp > localTimestamp) {
        AppLogger.d("Sync: New remote content detected ($remoteTimestamp > $localTimestamp). Starting incremental sync...");
        
        // Find which months need syncing. For simplicity, we sync the last 2 months if there's an update.
        // A more complex logic could track exactly which days changed, but month-level sync in Isar is efficient.
        final now = DateTime.now();
        final months = [
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month - 1, 1),
        ];

        for (var month in months) {
          await _contentSync.syncContentForMonth(month.year, month.month);
        }

        // Update local timestamp
        await prefs.setInt('local_last_global_sync', remoteTimestamp);
        AppLogger.d("Sync: Incremental content sync complete. Broadcast triggered.");
        _eventController.add(SyncEvent(SyncEventType.initialSyncComplete)); // Reuse this event to trigger Dashboard reload
      } else {
        AppLogger.d("Sync: No new remote content detected ($remoteTimestamp <= $localTimestamp).");
      }
    } catch (e) {
      AppLogger.e("Sync: Incremental content check failed", e);
    }
  }

  Future<void> _checkInitialContentSync() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.d("Skip initial sync: No user logged in.");
      return;
    }

    final localCount = await _isar.localContents.count();
    if (localCount == 0) {
      AppLogger.d("Local content is empty. Triggering full user data download...");
      
      // 1. Download Global Library
      await _contentSync.downloadAllGlobalContent();
      
      // Update local timestamp after full download
      final remoteTimestamp = await _contentSync.getLastGlobalSyncTimestamp();
      if (remoteTimestamp != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('local_last_global_sync', remoteTimestamp);
      }
      
      // 2. Download User Private Data
      await _syncUserData();

      AppLogger.d("DEBUG: Initial sync broadcast triggered.");
      _eventController.add(SyncEvent(SyncEventType.initialSyncComplete));
    } else {
      AppLogger.d("Local content already exists ($localCount items). Skipping initial content sync.");
    }
  }

  Future<void> _syncUserData({bool force = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isSyncingUserData) {
      AppLogger.d("Sync: User data sync already in progress. Skipping.");
      return;
    }

    _isSyncingUserData = true;
    AppLogger.d("Sync: Pulling user data (progress, repetitions, custom tasks) on startup...");
    
    try {
      // Parallel pull for all user collections
      await Future.wait([
        _profileSync.download('main'),
        _progressSync.downloadAll(),
        _repetitionSync.downloadAll(),
        _customTaskSync.downloadAll(),
      ]);
      
      AppLogger.d("Sync: User data pull complete.");
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
}
