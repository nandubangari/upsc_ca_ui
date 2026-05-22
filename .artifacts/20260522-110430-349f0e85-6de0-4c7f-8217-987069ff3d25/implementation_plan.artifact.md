# Implementation Plan - Preparation Start Date Floor

Set a hard floor of January 1, 2025, for the preparation start date in the profile setup.

## User Review Required

- **Default Logic**: If 10 days ago is before January 1, 2025 (which it currently isn't, but for future robustness), the default will be floored at January 1, 2025.

## Proposed Changes

### UI Components

#### [profile_setup_screen.dart](file:///D:/Workspace/Android/Flutter/upsc_ca_ui/lib/features/profile/screens/profile_setup_screen.dart)

- Update `initState()` to ensure the default `_startDate` (10 days ago) respects the Jan 01 2025 floor.
- Update `_loadProfileData()` to ensure any existing profile data or defaults also respect the floor.
- Update `_buildPersonalCard()` to set the `firstDate` of the `ModernDatePicker` to `DateTime(2025, 1, 1)`.

## Verification Plan

### Manual Verification
- Open the Profile Setup screen.
- Verify the "Preparation Start Date" cannot be set to a date before January 1, 2025.
- Verify the default value is either 10 days ago or Jan 01 2025 (whichever is later).
