# Implementation Plan - Minimize Article Reader Header Spacing

The goal is to reduce the top and bottom spacing of the title row in the article reader to maximize content visibility.

## Proposed Changes

### [Article Reader Screen](file:///D:/Workspace/Android/Flutter/upsc_ca_ui/lib/features/reader/screens/article_reader_screen.dart)

- **Reduce `SliverAppBar` `toolbarHeight`**:
    - Current: `isTablet ? 110 : 90`
    - New: `isTablet ? 80 : 64` (Standard Material toolbar height is 56, we'll use a bit more for the 2-line title).
- **Adjust Header `Container` padding**:
    - Currently using `mediaQuery.viewPadding.top` inside the `Container`. Since `SliverAppBar` automatically handles the status bar area (it sits behind it), we can refine the internal padding to be more compact.
    - Change `padding: EdgeInsets.fromLTRB(hPadding, mediaQuery.viewPadding.top, hPadding, 0)` to `padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 0)`.
    - Set `SliverAppBar` `primary: true` (which is default) to handle status bar height.

#### Code Changes:

```dart
// Before
SliverAppBar(
  pinned: true,
  automaticallyImplyLeading: false,
  backgroundColor: backgroundColor,
  elevation: 0,
  scrolledUnderElevation: 0,
  toolbarHeight: isTablet ? 110 : 90,
  titleSpacing: 0,
  title: Container(
    padding: EdgeInsets.fromLTRB(hPadding, mediaQuery.viewPadding.top, hPadding, 0),
    child: Row(...)
  )
)

// After
SliverAppBar(
  pinned: true,
  automaticallyImplyLeading: false,
  backgroundColor: backgroundColor,
  elevation: 0,
  scrolledUnderElevation: 0,
  toolbarHeight: isTablet ? 80 : 64, // Reduced height
  titleSpacing: 0,
  centerTitle: false,
  title: Padding(
    padding: EdgeInsets.symmetric(horizontal: hPadding), // Removed top padding, using toolbar height to center
    child: Row(...)
  )
)
```

## Verification Plan

### Manual Verification
1.  **Header Check**: Open an article and verify that the title row is significantly more compact.
2.  **Status Bar**: Ensure the title doesn't overlap with the device status bar (time, battery, etc.).
3.  **Title Wrapping**: Verify that 2-line titles still fit within the reduced height.
4.  **Theming**: Check that the background color of the pinned app bar remains consistent.
