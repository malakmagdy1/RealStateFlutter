# Animations Implementation Guide

## Overview
This guide explains how to use the new animations that have been added to your Flutter app.

## 1. Scroll Animation for Screen Transitions

### What it does:
Creates a smooth vertical scroll animation (from bottom to top) when navigating between screens, similar to the video example you showed.

### How to use:

```dart
import 'package:real/core/animations/page_transitions.dart';

// Instead of using Navigator.push with MaterialPageRoute:
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => SomeScreen()),
);

// Use the extension method:
context.pushScroll(SomeScreen());
```

### All available navigation animations:

```dart
// 1. Scroll animation (vertical from bottom)
context.pushScroll(NextScreen());

// 2. Slide animation (horizontal from right)
context.pushSlide(NextScreen());

// 3. Fade animation
context.pushFade(NextScreen());

// 4. Scale animation (zoom in effect)
context.pushScale(NextScreen());

// 5. Slide + Fade combined
context.pushSlideFade(NextScreen());
```

### Example in your code:

```dart
// In compound_card.dart or unit_card.dart
onTap: () {
  // Old way:
  // Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen()));

  // New animated way:
  context.pushScroll(UnitDetailScreen(unit: unit));
}
```

## 2. Animated Image Picker

### What it does:
Shows a beautiful animated bottom sheet with options for Camera and Gallery when picking profile images.

### Where it's implemented:
- Mobile: `lib/feature/home/presentation/profileScreen.dart`
- Web: Uses default picker (web doesn't support camera)

### How it works:

When you tap the camera icon on the profile avatar, instead of directly opening the gallery, it now:
1. Shows an animated bottom sheet sliding up from the bottom
2. Displays two options with smooth scale animations:
   - **Camera** (pink/main color)
   - **Gallery** (blue)
3. Each option has a circular icon with shadow
4. On tap, closes the sheet and opens the selected source

### Features:
- ✅ Smooth fade-in animation for the sheet
- ✅ Scale animation for the option cards
- ✅ Drag handle for visual feedback
- ✅ Color-coded options
- ✅ Professional design with shadows and borders

## 3. Updating Other Screens

### To add scroll animation to navigation in other screens:

1. **Import the animations package**:
```dart
import 'package:real/core/animations/page_transitions.dart';
```

2. **Replace Navigator.push calls**:
```dart
// Find this pattern:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SomeScreen()),
);

// Replace with:
context.pushScroll(SomeScreen());
```

### Common locations where you might want to add this:

- `lib/feature/home/presentation/widget/compunds_name.dart` - Line ~50 (when tapping compound)
- `lib/feature/compound/presentation/widget/unit_card.dart` - Line ~120 (when tapping unit)
- `lib/feature/home/presentation/widget/company_name_scrol.dart` - When tapping company
- `lib/feature/home/presentation/homeScreen.dart` - Various navigation points

## 4. Testing the Animations

### To test scroll animation:
1. Run your app
2. Navigate from home screen to any detail screen
3. You should see a smooth scroll-up animation

### To test image picker animation:
1. Run your app
2. Go to Profile screen
3. Tap the camera icon on the avatar
4. You should see an animated bottom sheet appear
5. The two options (Camera/Gallery) should scale in with a bounce effect

## 5. Customization Options

### Adjust animation duration:
```dart
// In page_transitions.dart, modify the duration parameter:
class ScrollPageRoute<T> extends PageRoute<T> {
  ScrollPageRoute({
    required this.builder,
    RouteSettings? settings,
    this.duration = const Duration(milliseconds: 400), // Change this
  }) : super(settings: settings);
}
```

### Adjust animation curve:
```dart
// In the buildTransitions method:
const curve = Curves.ease; // Try: Curves.easeInOut, Curves.fastOutSlowIn, etc.
```

### Available curves:
- `Curves.ease` - Smooth and natural (current)
- `Curves.easeInOut` - Accelerates then decelerates
- `Curves.fastOutSlowIn` - Quick start, slow end
- `Curves.bounceOut` - Bouncy effect at the end
- `Curves.elasticOut` - Elastic/rubber band effect

## 6. Next Steps

Consider adding animations to:
- [ ] List items (staggered fade-in)
- [ ] Card hover effects (web)
- [ ] Loading states
- [ ] Filter/search results
- [ ] Tab transitions
- [ ] Dialog appearances

## Notes

- All animations are optimized for 60fps performance
- Animations work on both Android and iOS
- Web version has simpler image picker (no camera option)
- Animations are disabled in tests to avoid delays
