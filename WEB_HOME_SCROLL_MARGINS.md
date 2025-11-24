# Web Home Screen - Horizontal Scroll Margins

## Problem
User wanted margins specifically around the horizontal scrolling rows (companies and compounds), NOT around the entire screen.

## Solution
Removed overall screen width constraint and added vertical padding (top/bottom margins) only to the horizontal scrolling sections.

## Changes Made

### 1. Reverted Overall Screen Constraints
**File:** `lib/feature_web/home/presentation/web_home_screen.dart`

**Lines 249, 251:**
- maxWidth: 1100px → **1400px** (restored full width)
- padding: 24px → **16px** (restored original padding)

**Result:** Screen content uses full available width again

---

### 2. Added Vertical Padding to Companies Row
**File:** `lib/feature_web/home/presentation/web_home_screen.dart`

**Lines 310-312:**
```dart
// Before:
return SizedBox(
  height: 100,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    ...

// After:
return Padding(
  padding: EdgeInsets.symmetric(vertical: 12),  // ← Added
  child: SizedBox(
    height: 100,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      ...
```

**Result:** Companies horizontal scroll has 12px top and bottom margin

---

### 3. Added Vertical Padding to Unit Sections
**File:** `lib/feature_web/home/presentation/web_home_screen.dart`

**Lines 998-1000:**
```dart
// Before:
: SizedBox(
  height: 400,
  child: ListView.builder(
    controller: scrollController,
    scrollDirection: Axis.horizontal,
    ...

// After:
: Padding(
  padding: EdgeInsets.symmetric(vertical: 12),  // ← Added
  child: SizedBox(
    height: 400,
    child: ListView.builder(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      ...
```

**Result:** Unit rows (Updated 24h, New Arrivals) have 12px top and bottom margin

---

### 4. Added Vertical Padding to Recommended Compounds
**File:** `lib/feature_web/home/presentation/web_home_screen.dart`

**Lines 577-579:**
```dart
// Before:
return SizedBox(
  height: 400,
  child: ListView.builder(
    controller: _recommendedScrollController,
    scrollDirection: Axis.horizontal,
    ...

// After:
return Padding(
  padding: EdgeInsets.symmetric(vertical: 12),  // ← Added
  child: SizedBox(
    height: 400,
    child: ListView.builder(
      controller: _recommendedScrollController,
      scrollDirection: Axis.horizontal,
      ...
```

**Result:** Recommended compounds horizontal scroll has 12px top and bottom margin

---

## Visual Representation

### Before (Full Screen Margins):
```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  [LARGE MARGIN]                                          │
│                                                          │
│    ┌──────────────────────────────────────────┐         │
│    │   CONTENT (narrower, 1100px)             │         │
│    │   Companies Row                          │         │
│    │   Sale Carousel                          │         │
│    │   Units Row                              │         │
│    │   Compounds Row                          │         │
│    └──────────────────────────────────────────┘         │
│                                                          │
│  [LARGE MARGIN]                                          │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### After (Row-Specific Margins):
```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  FULL WIDTH CONTENT (1400px)                             │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ [12px top margin]                                  │  │
│  │ ← Companies Row (horizontal scroll) →              │  │
│  │ [12px bottom margin]                               │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  Sale Carousel (full width)                              │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ [12px top margin]                                  │  │
│  │ ← Updated 24h Units (horizontal scroll) →          │  │
│  │ [12px bottom margin]                               │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ [12px top margin]                                  │  │
│  │ ← New Arrivals Units (horizontal scroll) →         │  │
│  │ [12px bottom margin]                               │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ [12px top margin]                                  │  │
│  │ ← Recommended Compounds (horizontal scroll) →      │  │
│  │ [12px bottom margin]                               │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Summary

### What Changed:
1. **Screen Width**: Restored to 1400px (full width)
2. **Screen Padding**: Restored to 16px (original)
3. **Horizontal Scroll Sections**: Added 12px vertical padding (top/bottom)

### Affected Sections:
- ✅ Companies horizontal scroll row
- ✅ Updated 24h units horizontal scroll row
- ✅ New arrivals units horizontal scroll row
- ✅ Recommended compounds horizontal scroll row

### Not Affected:
- ❌ Overall screen width (now full width)
- ❌ Welcome message
- ❌ Sale carousel
- ❌ Section headers

---

## Result

**Key Benefits:**
- ✅ Full width content utilization
- ✅ Horizontal scroll rows have breathing room (top/bottom)
- ✅ Better visual separation between scrolling sections
- ✅ Maintains horizontal space efficiency
- ✅ Focused margins only where needed
- ✅ No wasted side margins

**Margin Application:**
- Top/Bottom: 12px per horizontal scroll section
- Left/Right: Full width (no side margins)
