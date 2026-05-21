# Implementation Plan - Fix Initial Sync Missing Historical Tasks (v2)

Fix the issue where new accounts only show tasks from the last 2 months by ensuring the full global library download runs correctly and is not skipped by pre-login incremental updates.

## Proposed Changes

### Sync Management

#### [sync_manager.dart](file:///D:/Workspace/Android/Flutter/upsc_ca_ui/lib/data/sync/sync_manager.dart)

-   Introduce a persistent flag `is_full_library_synced_v1` in `SharedPreferences` to track if the comprehensive global library has been downloaded.
-   Update `_checkInitialContentSync()` to rely on this flag instead of checking if `localCount == 0`.
-   Update `_checkIncrementalContentUpdate()` to only run if a user is logged in.
-   Add an explicit call to `_checkInitialContentSync()` when the user finishes profile setup (in `SyncManager.init` listener or manual trigger).

```dart
  Future<void> _checkInitialContentSync() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isFullSynced = prefs.getBool('is_full_library_synced_v1') ?? false;

    if (!isFullSynced) {
      AppLogger.d("Initial sync: Starting full global content download...");
      await _contentSync.downloadAllGlobalContent();

      await prefs.setBool('is_full_library_synced_v1', true);
      _eventController.add(SyncEvent(SyncEventType.initialSyncComplete));
    }
  }
```

### Dashboard Logic

#### [isar_dashboard_service.dart](file:///D:/Workspace/Android/Flutter/upsc_ca_ui/lib/data/services/isar_dashboard_service.dart)

-   Ensure `fetchDashboardData` uses the user's `startDate` correctly. If the `startDate` is far in the past, it should fetch all those records from Isar.
-   Current logic: `final startDateStr = DateFormatter.toIso(userStartDate);` and `localContentRaw = await _isar.localContents.filter().dateGreaterThan(startDateStr, include: true).findAll();`. This is correct, provided the data exists in Isar.

### Data Model

#### [local_content.dart](file:///D:/Workspace/Android/Flutter/upsc_ca_ui/lib/data/local/models/local_content.dart)

-   Change `year` and `month` to `String` (Wait, they already are).
-   The `contentId` is unique and replaces old items. This is good.

## Verification Plan

### Automated Tests
- I will verify the logic by analyzing the code flow. Since this involves Firebase and Isar, unit tests might be complex without mocks, but I can verify the `SyncManager` logic by adding logging and checking the behavior in simulation.

### Manual Verification
1.  **Fresh Install**: Clear app data.
2.  **Login**: Sign in with Google.
3.  **Setup Profile**: Set start date to Jan 1, 2026.
4.  **Observe Logs**: Verify `downloadAllGlobalContent` is called.
5.  **Verify UI**: Verify tasks for Jan, Feb, Mar are visible in "Not Started" or "Completed" (depending on their state).
6.  **Verify Persistence**: Restart app, ensure tasks are still there and `is_full_library_synced_v1` is true.
