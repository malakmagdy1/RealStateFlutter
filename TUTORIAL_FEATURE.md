# Tutorial/Onboarding Feature

## Overview

A simple, elegant tutorial system has been implemented in the app to guide users through key features. The tutorial uses blurred dialogs with multi-step walkthroughs and is stored locally using SharedPreferences (no backend required).

## Features

- ✅ **Simple Blurred Dialog**: Beautiful blurred background effect
- ✅ **Multi-Step Tutorial**: Guide users through multiple features with progress indicators
- ✅ **Persistent Storage**: Uses SharedPreferences to track which tutorials have been shown
- ✅ **Separate Tutorials**: Different tutorials for different screens
- ✅ **Skip Option**: Users can skip tutorials at any time
- ✅ **Show Once**: Tutorials are shown only once per screen

## Implementation Details

### Files Created

1. **lib/core/services/tutorial_service.dart**
   - Manages tutorial state using SharedPreferences
   - Provides methods to check and mark tutorials as seen
   - Includes reset functionality for testing

2. **lib/core/widgets/tutorial_dialog.dart**
   - Reusable tutorial dialog widget
   - Supports single-step and multi-step tutorials
   - Beautiful blur effect and animations

### Screens with Tutorials

1. **Home Screen** (`homeScreen.dart`)
   - Search Properties
   - Save Favorites
   - Filter Results
   - View Details

2. **Compound Detail Screen** (`CompoundScreen.dart`)
   - View Images
   - Available Units
   - Contact Sales
   - Rate & Review

3. **Web Home Screen** (`web_home_screen.dart`)
   - Web Experience
   - Browse Companies
   - View Compounds
   - Advanced Filtering

## Usage Examples

### Basic Tutorial (Single Message)

```dart
import 'package:real/core/services/tutorial_service.dart';
import 'package:real/core/widgets/tutorial_dialog.dart';

Future<void> showWelcome() async {
  final tutorialService = TutorialService();
  final hasSeen = await tutorialService.hasSeenHomeTutorial();

  if (!hasSeen && mounted) {
    await TutorialDialog.showWelcome(
      context: context,
      screenName: 'Home',
      description: 'Welcome to our app! Here you can browse properties and save favorites.',
      onFinish: () async {
        await tutorialService.markHomeTutorialAsSeen();
      },
    );
  }
}
```

### Multi-Step Tutorial

```dart
Future<void> showTutorial() async {
  final tutorialService = TutorialService();
  final hasSeen = await tutorialService.hasSeenHomeTutorial();

  if (!hasSeen && mounted) {
    await TutorialDialog.showMultiStep(
      context: context,
      title: 'Welcome!',
      steps: [
        TutorialStep(
          icon: Icons.search,
          title: 'Search',
          description: 'Find properties using our powerful search.',
        ),
        TutorialStep(
          icon: Icons.favorite,
          title: 'Save Favorites',
          description: 'Tap the heart to save properties.',
        ),
      ],
      onFinish: () async {
        await tutorialService.markHomeTutorialAsSeen();
      },
    );
  }
}
```

### Adding Tutorial to a New Screen

1. Import the required files:
```dart
import 'package:real/core/services/tutorial_service.dart';
import 'package:real/core/widgets/tutorial_dialog.dart';
```

2. Add the tutorial check in `initState`:
```dart
@override
void initState() {
  super.initState();
  // ... other initialization code

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _showTutorialIfNeeded();
  });
}
```

3. Implement the tutorial method:
```dart
Future<void> _showTutorialIfNeeded() async {
  final tutorialService = TutorialService();
  final hasSeen = await tutorialService.hasSeenMyScreenTutorial(); // Use appropriate method

  if (!hasSeen && mounted) {
    await TutorialDialog.showMultiStep(
      context: context,
      title: 'Your Screen Title',
      steps: [
        // Add your tutorial steps here
      ],
      onFinish: () async {
        await tutorialService.markMyScreenTutorialAsSeen(); // Use appropriate method
      },
    );
  }
}
```

## Testing

### Reset All Tutorials

To reset all tutorials during development/testing:

```dart
final tutorialService = TutorialService();
await tutorialService.resetAllTutorials();
```

### Reset Specific Tutorial

```dart
final tutorialService = TutorialService();
await tutorialService.resetHomeTutorialAsSeen();
```

### Test in Debug Mode

Add a debug button to your settings screen:

```dart
if (kDebugMode) {
  ElevatedButton(
    onPressed: () async {
      final tutorialService = TutorialService();
      await tutorialService.resetAllTutorials();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All tutorials reset!')),
      );
    },
    child: Text('Reset Tutorials'),
  ),
}
```

## Customization

### Change Tutorial Appearance

Edit `lib/core/widgets/tutorial_dialog.dart`:

- **Blur Amount**: Change `sigmaX` and `sigmaY` in line 18
- **Dialog Width**: Change `maxWidth` in line 114
- **Colors**: Modify `AppColors.mainColor` to your theme color
- **Icon Size**: Change icon size in line 134
- **Button Style**: Customize button appearance in lines 223-230

### Add New Screen Tutorial

1. Add a new key constant in `TutorialService`:
```dart
static const String _myNewScreenKey = 'tutorial_my_screen_seen';
```

2. Add getter and setter methods:
```dart
Future<bool> hasSeenMyNewScreenTutorial() async {
  return hasSeen(_myNewScreenKey);
}

Future<void> markMyNewScreenTutorialAsSeen() async {
  return markAsSeen(_myNewScreenKey);
}
```

3. Update `resetAllTutorials()` to include the new key

## Best Practices

1. **Show After Build**: Always use `WidgetsBinding.instance.addPostFrameCallback` to show tutorials after the UI is built
2. **Check Mounted**: Always check `mounted` before showing dialogs
3. **Clear Context**: Use the tutorial immediately or store it properly
4. **Don't Overuse**: Only add tutorials for complex screens that need explanation
5. **Keep it Short**: Use 3-5 steps maximum for multi-step tutorials
6. **Skip Option**: Always provide a skip button for users who don't want to see tutorials

## Troubleshooting

### Tutorial Not Showing

- Check if `hasSeen` returns false
- Verify `mounted` is true
- Check SharedPreferences initialization
- Ensure tutorial is called after widget build

### Tutorial Showing Every Time

- Make sure `markAsSeen()` is called in `onFinish`
- Check SharedPreferences is working correctly
- Verify the correct key is being used

### Dialog Not Blurred

- Check if `BackdropFilter` is supported on the platform
- Verify `ImageFilter.blur` parameters
- Test on a physical device (blur may not work in some emulators)

## Notes

- Tutorials are stored per-device using SharedPreferences
- No backend/API integration required
- Each screen has its own tutorial state
- Tutorials can be reset for testing purposes
- The tutorial service is designed to be extended easily for new screens
