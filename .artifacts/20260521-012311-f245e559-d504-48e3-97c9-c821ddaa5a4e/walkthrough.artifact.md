# Walkthrough - Fixing Missing Historical Tasks

I fixed a critical sync bug where historical tasks were missing after account creation.

## The Issue
1.  On app startup (before login), an "Incremental Sync" would run, downloading only the last 2 months of data to provide a "preview" or handle background updates.
2.  This "Incremental Sync" populated the local Isar database with some records.
3.  When the user logged in or created an account, the "Initial Sync" logic checked if the local database was empty (`localCount == 0`).
4.  Because the database was no longer empty (thanks to the pre-login incremental sync), the "Initial Sync" was skipped, and the full global library download never occurred.
5.  Consequently, the user could only see tasks from April 1st, 2026 onwards, even if their preparation start date was earlier.

## The Fix

### 1. Persistent Sync Tracking
I introduced a new boolean flag `is_full_library_synced_v1` in `SharedPreferences`. The app now relies on this flag to decide whether it needs to perform a full download, rather than just checking if the database is empty.

### 2. Login-Gated Sync
I modified `SyncManager` to prevent both incremental and initial syncs from running until a `FirebaseAuth` user is actually detected. This prevents the race condition where unauthenticated syncs "spoil" the database for the authenticated full sync.

### 3. Refactored `SyncManager` Logic
-   `_checkIncrementalContentUpdate` now returns early if no user is logged in.
-   `_checkInitialContentSync` now checks the persistent flag. If false, it triggers `downloadAllGlobalContent()`, sets the flag to true upon completion, and updates the `local_last_global_sync` timestamp.

## Verification Summary
-   Code analysis confirms that `localCount == 0` check is replaced by a persistent flag check.
-   Login gating ensures sync only happens for authenticated users.
-   This approach guarantees that even if a partial sync occurred previously, the full historical backfill will always trigger for new accounts until completion.

render_diffs(file:///D:/Workspace/Android/Flutter/upsc_ca_ui/lib/data/sync/sync_manager.dart)
