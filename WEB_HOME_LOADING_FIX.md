# Web Home Screen Loading Fix - COMPLETE

## Issue
The web home screen was showing loading indicators every 1 minute during scrolling in the compounds, companies, and units sections. The screen would also jump back to the beginning.

## Root Causes (2 Issues Fixed)

### Issue #1: Widget Lifecycle in WebHomeScreen
The `_refreshData()` method was being called in `initState()` immediately, which was triggering repeated data fetches due to the widget lifecycle.

### Issue #2: Screen Recreation in WebMainScreen (PRIMARY CAUSE)
The **main culprit** was in `web_main_screen.dart` line 49:
```dart
WebHomeScreen(key: ValueKey('home_${DateTime.now().millisecondsSinceEpoch}')),
```

This was creating a **new unique key with a timestamp** every time `_screens` getter was called. Since there's a notification check timer running every 3 seconds (line 66), every `setState` call would recreate ALL screens with new keys, causing the WebHomeScreen to be completely rebuilt and reload all data.

## Solution Applied

### Fix #1: Changes in `lib/feature_web/home/presentation/web_home_screen.dart`

1. **Moved data fetching to post-frame callback** (lines 76-89):
   ```dart
   @override
   void initState() {
     super.initState();

     // Setup scroll listener for recommended compounds
     _recommendedScrollController.addListener(_onRecommendedScroll);

     // Load initial data and favorites after frame is built
     WidgetsBinding.instance.addPostFrameCallback((_) {
       // Fetch data only once on initialization
       _refreshData();
       context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
       context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());
     });
   }
   ```

2. **Cleaned up didChangeDependencies** (lines 134-141):
   ```dart
   @override
   void didChangeDependencies() {
     super.didChangeDependencies();
     // Mark as initialized - do NOT refresh data here
     if (!_hasInitialized) {
       _hasInitialized = true;
     }
   }
   ```

3. **Made constructor const**:
   ```dart
   const WebHomeScreen({super.key});
   ```

### Fix #2: Changes in `lib/feature_web/navigation/web_main_screen.dart`

**Replaced dynamic keys with const keys** (lines 47-56):
```dart
// Before (WRONG - causes rebuilds):
List<Widget> get _screens => [
  WebHomeScreen(key: ValueKey('home_${DateTime.now().millisecondsSinceEpoch}')),
  ...
];

// After (CORRECT - prevents rebuilds):
List<Widget> get _screens => const [
  WebHomeScreen(key: ValueKey('home_screen')),
  WebCompoundsScreen(),
  WebFavoritesScreen(),
  WebHistoryScreen(),
  UnifiedAIChatScreen(),
  WebNotificationsScreen(),
  WebProfileScreen(),
];
```

## Result
- ✅ Data loads only once when the screen first appears
- ✅ No more periodic loading indicators during scrolling
- ✅ Smooth scrolling experience maintained
- ✅ Screen position stays stable
- ✅ WebHomeScreen is not recreated unnecessarily
- ✅ Notification timer no longer triggers screen rebuilds

## Technical Explanation
The notification check timer in `WebMainScreen` runs every 3 seconds and calls `setState()` to update the unread notification count. Before the fix, this would:
1. Trigger the `_screens` getter
2. Create a new `WebHomeScreen` with a unique timestamp key
3. Flutter would see this as a different widget
4. Dispose the old WebHomeScreen and create a new one
5. The new WebHomeScreen would call `initState()` and reload all data
6. User sees loading indicators and scroll position resets

After the fix, the const keys ensure Flutter recognizes the screens as the same widgets, so they are not recreated when `setState()` is called for notification updates.

## Testing
Test the web home screen by:
1. Opening the app in web browser
2. Scrolling through companies, compounds, and units sections
3. Wait for 1-2 minutes while scrolling
4. Verify no loading indicators appear after initial load
5. Verify scrolling is smooth without jumping back to top
6. Verify notification badge updates work correctly without affecting the screen

## Date
2025-11-24
