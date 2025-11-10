# Tutorial Coach Mark - Fix Summary

## ✅ Problem Solved

**Before:** Tutorial showed text overlay but did NOT point to any widget (no circular highlight)
**After:** Tutorial properly highlights each widget with a circle/rectangle and shows explanation text

---

## 🔑 Key Fix

### The Main Issue:
Tutorial was starting **before widgets were rendered**, so GlobalKeys had no position/size data.

### The Solution:
```dart
@override
void initState() {
  super.initState();

  // ✅ Wait for first frame to render
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        createTutorial();
        showTutorial();
      }
    });
  });
}
```

---

## 📋 Checklist for Working Tutorials

### 1. GlobalKey Attachment ✅
```dart
// Define key
final GlobalKey myButtonKey = GlobalKey();

// Attach to widget
IconButton(
  key: myButtonKey, // ✅ MUST attach key here
  icon: Icon(Icons.add),
  onPressed: () {},
)
```

### 2. Wait for Widgets ✅
```dart
// ❌ WRONG - too early
@override
void initState() {
  super.initState();
  showTutorial(); // Widget not rendered yet!
}

// ✅ CORRECT
@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) showTutorial();
    });
  });
}
```

### 3. Bottom Navigation Fix ✅
```dart
bottomNavigationBar: Stack(
  children: [
    // Invisible overlay to capture positions
    SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(child: Container(key: key1, color: Colors.transparent)),
          Expanded(child: Container(key: key2, color: Colors.transparent)),
          Expanded(child: Container(key: key3, color: Colors.transparent)),
        ],
      ),
    ),
    // Actual bottom nav
    BottomNavigationBar(items: [...]),
  ],
),
```

---

## 🎯 Complete Working Example

See: `lib/examples/tutorial_example_fixed.dart`

This example includes:
- ✅ 9 different target highlights
- ✅ Circular and rectangular shapes
- ✅ Arabic explanations
- ✅ Bottom navigation highlighting
- ✅ Navigation controls (previous/next)
- ✅ Skip functionality

---

## 🎨 Customization Options

### Shape
```dart
shape: ShapeLightFocus.Circle,  // or RRect
radius: 15,                      // corner radius (if RRect)
```

### Position
```dart
align: ContentAlign.top,     // top, bottom, left, right
```

### Colors
```dart
colorShadow: Colors.red,     // overlay color
opacityShadow: 0.8,          // darkness (0-1)
color: Colors.blue,          // highlight color (optional)
```

---

## 📝 Quick Copy-Paste Template

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late TutorialCoachMark tutorial;
  final GlobalKey buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _createTutorial();
          tutorial.show(context: context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: buttonKey, // ✅ Attach key
            icon: Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(child: Text('Tutorial Demo')),
    );
  }

  void _createTutorial() {
    tutorial = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "myButton",
          keyTarget: buttonKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "اضغط هنا للإضافة",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## ✨ Result

Now your tutorial will:
1. **Highlight** the widget with a circle/rectangle
2. **Darken** the rest of the screen
3. **Show** clear explanation text
4. **Point** directly to the target
5. **Guide** users step by step

Just like the image you showed! 🎉
