# 🎨 Animations Implementation Guide

## ✅ Implemented Animations

### 1. **Hover Scale Animation** (All Cards)
**Location:** `lib/core/animations/hover_scale_animation.dart`

**Features:**
- AnimatedContainer with `Curves.easeOut`
- Transform matrix with scale effect
- Activates on MouseRegion hover
- Default scale: 1.03 (3% larger on hover)
- Duration: 200ms

**Usage:**
```dart
HoverScaleAnimation(
  child: YourWidget(),
)
```

**Applied To:**
- ✅ CompoundsName (Mobile compound card)
- 🔄 UnitCard (Mobile unit card) - TODO
- 🔄 WebCompoundCard (Web compound card) - TODO
- 🔄 WebUnitCard (Web unit card) - TODO

---

### 2. **Pulse Animation** (Icons)
**Location:** `lib/core/animations/pulse_animation.dart`

**Features:**
- Scale sequence: 1.0 → 1.3 → 0.9 → 1.0
- Shake animation: vibrate left-right (5px)
- Total duration: 600ms
- Triggers on tap

**Usage:**
```dart
class _MyWidgetState extends State<MyWidget> {
  bool _animate = false;

  @override
  Widget build(BuildContext context) {
    return PulseAnimation(
      animate: _animate,
      child: IconButton(
        icon: Icon(Icons.favorite),
        onPressed: () {
          setState(() => _animate = true);
          Future.delayed(Duration(milliseconds: 600), () {
            if (mounted) setState(() => _animate = false);
          });
        },
      ),
    );
  }
}
```

**Applied To:**
- ✅ Favorite button in CompoundsName
- ✅ Share button in CompoundsName
- 🔄 Favorite button in UnitCard - TODO
- 🔄 Share button in UnitCard - TODO
- 🔄 Notification icon - TODO (needs FCM integration)

---

### 3. **Hero Animation** (Screen Transitions)
**Location:** Built-in Flutter Hero widget

**Features:**
- Smooth transition between screens
- Card "flies" from list to detail screen
- Automatically handles animation curve

**Usage:**
```dart
// In list/grid (compound card):
Hero(
  tag: 'compound_${compound.id}',
  child: CompoundCard(...),
)

// In detail screen:
Hero(
  tag: 'compound_${compound.id}',
  child: CompoundDetailImage(...),
)
```

**Applied To:**
- ✅ CompoundsName → CompoundScreen transition
- 🔄 UnitCard → UnitDetailScreen transition - TODO
- 🔄 WebCompoundCard transitions - TODO
- 🔄 WebUnitCard transitions - TODO

---

## 🔄 TODO: Apply to Remaining Widgets

### Mobile Unit Card
**File:** `lib/feature/compound/presentation/widget/unit_card.dart`

**Steps:**
1. Convert to StatefulWidget
2. Add animation state variables:
   ```dart
   bool _animateFavorite = false;
   bool _animateShare = false;
   ```
3. Wrap card in:
   ```dart
   HoverScaleAnimation(
     child: Hero(
       tag: 'unit_${widget.unit.id}',
       child: Card(...),
     ),
   )
   ```
4. Wrap favorite button:
   ```dart
   PulseAnimation(
     animate: _animateFavorite,
     child: GestureDetector(...),
   )
   ```
5. Wrap share button:
   ```dart
   PulseAnimation(
     animate: _animateShare,
     child: GestureDetector(...),
   )
   ```

---

### Web Compound Card
**File:** `lib/feature_web/widgets/web_compound_card.dart`

**Steps:**
1. Convert to StatefulWidget
2. Add animation state (same as mobile)
3. Wrap with HoverScaleAnimation
4. Add Hero tag
5. Add PulseAnimation to buttons

---

### Web Unit Card
**File:** `lib/feature_web/widgets/web_unit_card.dart`

**Steps:**
1. Convert to StatefulWidget
2. Add animation state
3. Wrap with HoverScaleAnimation
4. Add Hero tag
5. Add PulseAnimation to buttons

---

## 📱 Notification Icon Pulse Animation

### Implementation Location
**File:** `lib/feature_web/navigation/web_main_screen.dart` (and mobile nav)

### Steps:

1. **Add FCM Listener:**
```dart
class _NavigationState extends State<Navigation> {
  bool _animateNotification = false;

  @override
  void initState() {
    super.initState();

    // Listen for new notifications
    FCMService.onMessageReceived.listen((message) {
      setState(() => _animateNotification = true);
      Future.delayed(Duration(milliseconds: 600), () {
        if (mounted) setState(() => _animateNotification = false);
      });
    });
  }
}
```

2. **Wrap Notification Icon:**
```dart
PulseAnimation(
  animate: _animateNotification,
  child: IconButton(
    icon: Icon(Icons.notifications),
    onPressed: () => Navigator.push(...),
  ),
)
```

---

## 🎯 Animation Specifications

### Hover Animation:
- **Curve:** `Curves.easeOut`
- **Duration:** 200ms
- **Scale:** 1.03 (3% increase)
- **Transform:** Matrix4 scale

### Pulse Animation:
- **Duration:** 600ms total
- **Scale Sequence:**
  - 0-200ms: 1.0 → 1.3 (ease out)
  - 200-400ms: 1.3 → 0.9 (ease in-out)
  - 400-600ms: 0.9 → 1.0 (ease out)
- **Shake Sequence:**
  - 0-150ms: 0 → 5px right
  - 150-300ms: 5px → -5px left
  - 300-450ms: -5px → 5px right
  - 450-600ms: 5px → 0 center

### Hero Animation:
- **Built-in Flutter animation**
- **Auto curve:** rectlinear for images, ease-in-out for text
- **Duration:** 300ms (default)

---

## 🧪 Testing Checklist

### Mobile:
- [ ] Hover over compound cards (requires mouse/trackpad)
- [ ] Tap favorite button → see pulse animation
- [ ] Tap share button → see pulse animation
- [ ] Open compound detail → see hero transition
- [ ] Receive notification → see icon pulse

### Web:
- [ ] Hover over compound cards → see scale up
- [ ] Hover over unit cards → see scale up
- [ ] Click favorite → see pulse
- [ ] Click share → see pulse
- [ ] Open detail screens → see hero transition
- [ ] Receive notification → see icon pulse

---

## 📊 Performance Considerations

1. **Hover Animation:**
   - Uses `AnimatedContainer` (efficient)
   - Hardware accelerated transforms
   - Minimal CPU usage

2. **Pulse Animation:**
   - Uses `AnimationController` (efficient)
   - Only runs when triggered
   - Auto-disposes with widget

3. **Hero Animation:**
   - Built-in Flutter optimization
   - GPU accelerated
   - No manual cleanup needed

---

## 🎨 Customization

### Adjust Hover Scale:
```dart
HoverScaleAnimation(
  scale: 1.05, // 5% larger
  duration: Duration(milliseconds: 300),
  child: YourWidget(),
)
```

### Adjust Pulse Duration:
```dart
PulseAnimation(
  animate: _animate,
  duration: Duration(milliseconds: 800), // slower
  child: YourIcon(),
)
```

---

## ✅ Summary

**Implemented:**
- ✅ HoverScaleAnimation widget
- ✅ PulseAnimation widget
- ✅ Applied to CompoundsName (mobile compound card)
- ✅ Hero animation for compound cards

**Remaining:**
- 🔄 Apply to UnitCard (mobile)
- 🔄 Apply to WebCompoundCard
- 🔄 Apply to WebUnitCard
- 🔄 Add notification icon pulse (needs FCM integration)

---

**Last Updated:** 2025-11-03
**Status:** 🟡 In Progress
**Completion:** ~40% (1/4 cards done + animation widgets created)
