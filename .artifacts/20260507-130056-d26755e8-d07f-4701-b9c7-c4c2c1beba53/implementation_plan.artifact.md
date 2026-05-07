# Optimized Sync and Dynamic Task Allocation

Implement an efficient sync strategy and a deadline-aware task allocation system to ensure exam readiness.

## Proposed Changes

### [Models] Profile and Update Support

#### [profile_data.dart](file:///D:/Workspace/Android/Flutter/upsc_ca_ui/lib/models/profile_data.dart)

- Add a `copyWith` method to `ProfileData` to allow easy updates of fields like `startDate`.

### [Sync Services] Resilient Data Merging

#### [base_sync_service.dart](file:///D:/Workspace/Android/Flutter/upsc_ca_ui/lib/services/sync/base_sync_service.dart)

- **Preserve Progress**: Modify `mergeAndSave` to read existing `isCompleted` and `completedAt` values from Firestore before any overwrite. Re-apply these values to incoming network data if URLs or titles match.
- **Incremental Sync Support**: Ensure `syncRange` can handle shorter windows effectively without data loss.

### [Providers] Smart Sync and Task Allocation

#### [dashboard_provider.dart](file:///D:/Workspace/Android/Flutter/upsc_ca_ui/lib/providers/dashboard_provider.dart)

- **Optimized Incremental Sync**:
    - **Full Sync Trigger**: Detect if `startDate` is changed (moved back) or if it's the first sync.
    - **Incremental Mode**: Otherwise, only sync for the **last 5 days** to save resources.
- **Dynamic "Today's Tasks" Quota**:
    - In `_reorganizeTasks`, calculate the number of tasks for "Today" based on:
        - `totalUncompletedDays` (count of tasks not in the "Completed" section).
        - `daysUntilExam` (from `profile.examDate`).
        - `quota = (totalUncompletedDays / daysUntilExam).ceil()`.
        - **Constraint**: `quota` must be at least **3**.
    - Distribute tasks:
        1. **Completed**: Stays in "Completed".
        2. **In Progress**: Stays in "In Progress" (currently started articles).
        3. **Today's Quota**: Take the oldest `quota` tasks from the remaining set and move them to "Today's Tasks".
        4. **Remaining**: Move to "Not Started".
- **Auto-Advance**: Automatically move `startDate` to the earliest unread task date after sync.

---

## Verification Plan

### Manual Verification
1. **Dynamic Quota Test**:
    - Set an exam date 10 days away.
    - Have 40 days of uncompleted tasks.
    - Verify that "Today's Tasks" section now shows **4** tasks (40/10).
    - Set exam date 100 days away. Verify it shows **3** tasks (minimum constraint).
2. **Incremental Sync Test**:
    - Run sync, then run it again. Verify logs show requests only for the last 5 days.
3. **Progress Preservation**:
    - Mark an article as done. Run a full sync (move start date back). Verify the article stays "Done".
4. **Start Date Change**:
    - Change preparation start date in settings. Verify a full sync is triggered for the new range.
