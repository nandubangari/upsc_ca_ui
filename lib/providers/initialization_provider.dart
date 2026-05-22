import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/data/sync/sync_manager.dart';
import 'package:upsc_ca_ui/providers/subscription_provider.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';

class InitializationProvider with ChangeNotifier {
  bool _isInitialized = false;
  double _progress = 0.0;
  String _status = "Initializing...";
  StreamSubscription? _syncSubscription;
  DateTime? _startTime;

  bool get isInitialized => _isInitialized;
  double get progress => _progress;
  String get status => _status;

  InitializationProvider() {
    _isInitialized = false;
  }

  void startInitialization(BuildContext context) {
    if (_isInitialized) {
      AppLogger.d("Initialization already complete. Skipping.");
      return;
    }

    _listenToSync(context);
    _performInitialization(context);
  }

  void reset() {
    _isInitialized = false;
    _progress = 0.0;
    _status = "Initializing...";
    _syncSubscription?.cancel();
    _syncSubscription = null;
    notifyListeners();
  }

  void _listenToSync(BuildContext context) {
    _syncSubscription?.cancel();
    _syncSubscription = SyncManager().events.listen((event) {
      if (event.type == SyncEventType.progressUpdate) {
        _progress = event.progress ?? _progress;
        _status = event.status ?? _status;
        notifyListeners();
      }
    });
  }

  Future<void> _performInitialization(BuildContext context) async {
    AppLogger.d("Starting app initialization flow...");
    _startTime = DateTime.now();
    _isInitialized = false; 
    
    try {
      // 1. Check Profile Setup status
      final isSetupComplete = await ProfileService().isProfileSetupComplete();
      if (!isSetupComplete) {
        AppLogger.d("Initialization: Profile setup not complete. Skipping.");
        _isInitialized = true;
        _syncSubscription?.cancel();
        _syncSubscription = null;
        notifyListeners();
        return;
      }

      // 2. Refresh Subscription Status (First priority)
      _status = "Verifying your subscription...";
      _progress = 0.05;
      notifyListeners();
      
      if (!context.mounted) return;
      final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      
      AppLogger.d("Initialization: Refreshing subscription status (forced)...");
      // Use forced cloud fetch to ensure we catch expirations
      await subProvider.refreshStatus(forceCloud: true);
      
      AppLogger.d("Initialization: Subscription status refreshed. Access: ${subProvider.accessLevel}");
      
      _progress = 0.15;
      notifyListeners();

      // 3. Trigger SyncManager checks
      _status = "Synchronizing your data...";
      notifyListeners();
      
      AppLogger.d("Initialization: Waiting for SyncManager.checkSyncStatus...");
      await SyncManager().checkSyncStatus();
      AppLogger.d("Initialization: SyncManager.checkSyncStatus finished.");

      AppLogger.d("Initialization flow core tasks complete.");
    } catch (e, stack) {
      AppLogger.e("Initialization flow failed", e, stack);
    } finally {
      // Ensure the loading screen is shown for at least 1.5 seconds to prevent flicker 
      // and ensure data is properly propagated to UI
      final elapsed = DateTime.now().difference(_startTime!);
      if (elapsed < const Duration(milliseconds: 1500)) {
        await Future.delayed(const Duration(milliseconds: 1500) - elapsed);
      }

      // STOP listening to background sync events to avoid overwriting 100% progress
      _syncSubscription?.cancel();
      _syncSubscription = null;

      _isInitialized = true;
      _progress = 1.0;
      _status = "Ready";
      notifyListeners();
      AppLogger.d("Initialization: Final state broadcast. isInitialized: $_isInitialized");
    }
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}
