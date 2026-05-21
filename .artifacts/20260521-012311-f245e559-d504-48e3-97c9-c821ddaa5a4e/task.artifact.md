# Tasks

- [x] Research existing sync and data loading logic
    - [x] Analyze `SyncManager` initialization and sync triggers
    - [x] Analyze `DashboardProvider` data loading
    - [x] Analyze `ProfileSetupScreen` and `ProfileService` post-setup actions
- [x] Identify why tasks before April 2026 are missing on initial sync
- [x] Create implementation plan to ensure full sync on account creation
- [x] Implement the fix
    - [x] Update `SyncManager` with persistent full sync flag
    - [x] Refactor `_checkInitialContentSync` and `_checkIncrementalContentUpdate`
- [x] Verify the fix
