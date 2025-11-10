# Tutorial Coach Mark System - Complete Guide

## Overview

The app now has a professional tutorial system that highlights **ONE button/feature at a time** with an overlay, similar to the image you shared. Users see a spotlight on each button with an explanation card below or above it.

## How It Works

### User Experience:

1. **First Time Opening Screen**: When users open a screen for the first time, the tutorial automatically starts
2. **Dark Overlay**: The entire screen dims except for the highlighted button/element
3. **Spotlight Effect**: The current button/feature is highlighted with a rounded spotlight
4. **Explanation Card**: A beautiful white card appears with:
   - An icon representing the feature
   - Title of the feature
   - Clear description of what it does
   - "SKIP" button (to exit tutorial)
   - "NEXT" button (to move to next element)
5. **One at a Time**: Only ONE element is highlighted at a time
6. **Sequential Flow**: User taps NEXT to learn about the next button
7. **Persistent**: Tutorial shows only once per screen (saved in SharedPreferences)

### Visual Design:

- Dark overlay dims the screen
- Highlighted element has a rounded spotlight (circle or rounded rectangle)
- White explanation card with:
  - Icon in a colored circle at the top
  - Bold title in app's main color
  - Clear description text
  - Two buttons: SKIP (outlined) and NEXT (filled with main color)
- Smooth animations between steps
- Arrow icon on NEXT button for better UX

## Implemented Screens

### 1. Home Screen (`homeScreen.dart`)
Highlights 4 key elements in order:
1. **Search Bar** - How to search for properties
2. **Filter Button** - How to use advanced filters
3. **Companies List** - How to browse companies
4. **Compounds List** - How to view compounds

### 2. Compound Detail Screen (`CompoundScreen.dart`)
Highlights 4 key elements:
1. **Photo Gallery** - How to swipe through images
2. **Information Tabs** - How to switch between tabs
3. **Available Units** - How to browse units
4. **Contact Button** - How to contact sales

### 3. Unit Detail Screen (`unit_detail_screen.dart`)
Highlights 3-5 elements:
1. **Unit Photos** - Image gallery
2. **Favorite Button** - Save to favorites
3. **Share Button** - Share the unit
4. **Floor Plan** (if available) - View floor plan
5. **Contact Button** - Contact sales team

### 4. Favorites Screen (`FavoriteScreen.dart`)
Highlights 1-3 elements:
1. **Tabs** - Switch between Compounds/Units
2. **Favorite Item** (if any exist) - View details
3. **Remove Button** (if any exist) - Remove from favorites

### 5. History Screen
Highlights 3-4 elements:
1. **Search** - Search history
2. **Filter** - Filter by type
3. **Clear Button** - Clear all history
4. **History Item** (if any exist) - View again

## Web Platform Support

The tutorial system works on **both mobile and web** platforms! The `tutorial_coach_mark` package is compatible with:
- Android
- iOS
- Web

## Code Structure

### Files:

1. **`lib/core/services/tutorial_coach_service.dart`**
   - Main service that creates tutorials
   - Contains methods for each screen
   - Handles styling and animations

2. **`lib/core/services/tutorial_service.dart`**
   - Manages SharedPreferences
   - Tracks which tutorials have been seen
   - Provides reset functionality

### Adding Tutorial to a New Screen:

```dart
// 1. Import the service
import 'package:real/core/services/tutorial_coach_service.dart';

// 2. Create GlobalKeys in your State class
class _MyScreenState extends State<MyScreen> {
  final GlobalKey _button1Key = GlobalKey();
  final GlobalKey _button2Key = GlobalKey();
  final GlobalKey _button3Key = GlobalKey();

  // 3. Call tutorial in initState
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded();
    });
  }

  // 4. Implement the tutorial method
  Future<void> _showTutorialIfNeeded() async {
    final tutorialService = TutorialCoachService();
    await Future.delayed(Duration(milliseconds: 500));

    if (mounted) {
      await tutorialService.showMyScreenTutorial(
        context: context,
        button1Key: _button1Key,
        button2Key: _button2Key,
        button3Key: _button3Key,
      );
    }
  }

  // 5. Add keys to your UI widgets
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: _button1Key, // Add key here
            onPressed: () {},
            child: Text('Button 1'),
          ),
          IconButton(
            key: _button2Key, // Add key here
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          Container(
            key: _button3Key, // Add key here
            child: Text('Some feature'),
          ),
        ],
      ),
    );
  }
}
```

### Creating a New Tutorial Method:

Add this to `tutorial_coach_service.dart`:

```dart
/// Show tutorial for my new screen
Future<void> showMyScreenTutorial({
  required BuildContext context,
  required GlobalKey button1Key,
  required GlobalKey button2Key,
  required GlobalKey button3Key,
}) async {
  const String myScreenTutorialKey = 'tutorial_my_screen_seen';
  final hasSeen = await _tutorialService.hasSeen(myScreenTutorialKey);
  if (hasSeen) return;

  final targets = <TargetFocus>[
    createTarget(
      key: button1Key,
      identify: "button1",
      title: "Feature Name",
      description: "Explain what this button does and why it's useful.",
      align: ContentAlign.bottom,
      icon: Icons.star, // Choose appropriate icon
    ),
    createTarget(
      key: button2Key,
      identify: "button2",
      title: "Another Feature",
      description: "Explain this feature clearly.",
      align: ContentAlign.bottom,
      shape: ShapeLightFocus.Circle, // Use Circle for round buttons
      icon: Icons.search,
    ),
    createTarget(
      key: button3Key,
      identify: "button3",
      title: "Third Feature",
      description: "Clear explanation here.",
      align: ContentAlign.top, // Position card above the element
      icon: Icons.share,
    ),
  ];

  final tutorial = createTutorial(
    targets: targets,
    onFinish: () async {
      await _tutorialService.markAsSeen(myScreenTutorialKey);
    },
  );

  tutorial.show(context: context);
}
```

## Testing the Tutorial

### Test on First Launch:

1. Open the app for the first time
2. Navigate to Home Screen
3. Tutorial should automatically start
4. Follow through all steps
5. Test SKIP button
6. Test NEXT button

### Reset Tutorial for Testing:

Add a debug button in your profile/settings screen:

```dart
import 'package:real/core/services/tutorial_service.dart';

// In your build method:
if (kDebugMode) {
  ElevatedButton(
    onPressed: () async {
      final tutorialService = TutorialService();
      await tutorialService.resetAllTutorials();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All tutorials reset! Reopen screens to see them again.')),
      );
    },
    child: Text('Reset All Tutorials (Debug)'),
  ),
}
```

### Reset Single Tutorial:

```dart
final tutorialService = TutorialService();
await tutorialService.resetHomeTutorialAsSeen();
// Or use the generic method:
await tutorialService.resetTutorialByKey('tutorial_home_seen');
```

## Customization Options

### Change Colors:

Edit `tutorial_coach_service.dart` line 18:

```dart
colorShadow: AppColors.mainColor, // Change to your preferred color
```

### Change Overlay Opacity:

```dart
opacityShadow: 0.8, // 0.0 = transparent, 1.0 = fully opaque
```

### Change Shape:

```dart
// For each target, you can specify:
shape: ShapeLightFocus.Circle, // For round buttons (FAB, IconButton)
// or
shape: ShapeLightFocus.RRect, // For rectangular elements (default)
```

### Change Text Alignment:

```dart
align: ContentAlign.bottom, // Card appears below the element
// or
align: ContentAlign.top, // Card appears above the element
// or
align: ContentAlign.left, // Card appears to the left
// or
align: ContentAlign.right, // Card appears to the right
```

### Change Button Text:

Edit line 21 in `tutorial_coach_service.dart`:

```dart
textSkip: "SKIP", // Change to your language (e.g., "تخطي" for Arabic)
```

And in the createTarget method around line 160:

```dart
Text('NEXT'), // Change to your language
```

## Best Practices

### ✅ DO:

1. **Keep it short**: 3-5 steps maximum per screen
2. **Focus on important features**: Only highlight features users need to know
3. **Use clear language**: Write simple, action-oriented descriptions
4. **Test on real devices**: Emulators may not show blur effects correctly
5. **Add delay**: Use `await Future.delayed(Duration(milliseconds: 500))` before showing tutorial
6. **Check mounted**: Always check `if (mounted)` before showing tutorial

### ❌ DON'T:

1. **Don't overuse**: Not every screen needs a tutorial
2. **Don't make it too long**: Users will skip if too many steps
3. **Don't use technical jargon**: Keep language simple
4. **Don't show on every launch**: Tutorial should show only once (already handled)
5. **Don't forget to add keys**: Tutorial won't work without GlobalKeys

## Troubleshooting

### Tutorial Not Showing:

**Check:**
1. Is this the first time opening the screen? (Tutorial shows only once)
2. Are all GlobalKeys properly assigned to widgets?
3. Is the tutorial method called in `initState` with `addPostFrameCallback`?
4. Is `mounted` check passing?
5. Check SharedPreferences - maybe tutorial was already marked as seen

**Fix:**
```dart
// Reset the specific tutorial
final tutorialService = TutorialService();
await tutorialService.resetAllTutorials();
```

### Elements Not Highlighting Correctly:

**Check:**
1. Did you assign the GlobalKey to the correct widget?
2. Is the widget actually rendered on screen?
3. Is the widget inside a `Visibility` or conditional rendering?

**Fix:**
```dart
// Make sure key is on the actual visible widget:
Container(
  key: _myKey, // ✅ Correct
  child: IconButton(...),
)

// NOT like this:
Container(
  child: IconButton(
    key: _myKey, // ❌ Wrong - key should be on the outer container
    ...
  ),
)
```

### Tutorial Showing Every Time:

**Check:**
1. Is `markAsSeen()` being called in `onFinish`?
2. Is SharedPreferences working correctly?

**Fix:**
```dart
// Make sure onFinish callback is correct:
final tutorial = createTutorial(
  targets: targets,
  onFinish: () async {
    await _tutorialService.markAsSeen('tutorial_key'); // Must be called
  },
);
```

### Blur Effect Not Working:

**Note:** Blur effects may not work on some emulators. Test on a real device.

## Comparison: Before vs After

### Before (Old Dialog System):
- ❌ Just showed text in a dialog
- ❌ Users had to read and remember
- ❌ No connection to actual UI elements
- ❌ Not engaging

### After (New Coach Mark System):
- ✅ Highlights actual buttons/features
- ✅ One element at a time (focused learning)
- ✅ Beautiful animations and design
- ✅ Users can see exactly where to tap
- ✅ Professional onboarding experience
- ✅ Works on mobile and web

## Summary

Your tutorial system now works **exactly like the image you shared**:

1. ✅ **Points to specific buttons** - Not explaining everything at once
2. ✅ **One at a time** - Shows ONE element with explanation
3. ✅ **Dark overlay** - Focuses attention on the highlighted element
4. ✅ **Beautiful cards** - Professional design with icons and clear text
5. ✅ **SKIP/NEXT buttons** - User control over the tutorial flow
6. ✅ **Sequential learning** - Step by step through features
7. ✅ **Persistent storage** - Shows only once per screen
8. ✅ **Works everywhere** - Mobile (Android/iOS) and Web

The system is fully implemented and ready to use! Each screen will show its tutorial automatically on first visit, highlighting each important button one by one with clear explanations.
