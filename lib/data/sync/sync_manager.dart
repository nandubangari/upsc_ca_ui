import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/data/local/isar_service.dart';
import 'package:upsc_ca_ui/data/local/models/local_content.dart';
import 'package:upsc_ca_ui/data/local/models/local_sync_metadata.dart';
import 'progress_sync_service.dart';
import 'repetition_sync_service.dart';
import 'profile_sync_service.dart';
import 'content_sync_service.dart';
import 'custom_task_sync_service.dart';

enum SyncEventType { initialSyncComplete }

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

  final _eventController = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get events => _eventController.stream;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    
    // 1. Listen for auth changes to trigger sync
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        AppLogger.d("User logged in. Checking initial sync...");
        unawaited(_checkInitialContentSync());
      }
    });

    // 2. Defer connectivity listener and initial checks to avoid blocking startup frames
    unawaited(Future.microtask(() async {
      // Connectivity listener
      Connectivity().onConnectivityChanged.listen((results) {
        if (results.any((r) => r != ConnectivityResult.none)) {
          AppLogger.d("Internet restored. Triggering sync...");
          unawaited(triggerSyncAll());
        }
      });

      // Initial content check (Download global content if local is empty)
      await _checkInitialContentSync();
    }));

    _safetyTimer = Timer.periodic(const Duration(minutes: 30), (_) => unawaited(triggerSyncAll()));
  }

  Future<void> _checkInitialContentSync() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.d("Skip initial sync: No user logged in.");
      return;
    }

    final localCount = await _isar.localContents.count();
    if (localCount == 0) {
      AppLogger.d("Local content is empty. Triggering global content download...");
      await _contentSync.downloadAllGlobalContent();
      AppLogger.d("DEBUG: Initial sync broadcast triggered.");
      _eventController.add(SyncEvent(SyncEventType.initialSyncComplete));
    } else {
      AppLogger.d("Local content already exists ($localCount items). Skipping initial sync.");
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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      AppLogger.d("App backgrounded/closed. Triggering final sync...");
      triggerSyncAll();
    }
  }

  void resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(minutes: 5), () {
      AppLogger.d("User idle for 5 minutes. Triggering sync...");
      triggerSyncAll();
    });
  }

  Future<void> triggerSyncAll() async {
    final dirtyDocs = await _isar.localSyncMetadatas.filter().isDirtyEqualTo(true).findAll();
    
    if (dirtyDocs.isEmpty) {
      AppLogger.d("No dirty documents to sync.");
      return;
    }

    AppLogger.d("Found ${dirtyDocs.length} dirty documents. Syncing...");

    await _syncCollection(_progressSync);
    await _syncCollection(_repetitionSync);
    await _syncCollection(_profileSync);
    await _syncCollection(_contentSync);
    await _syncCollection(_customTaskSync);
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
