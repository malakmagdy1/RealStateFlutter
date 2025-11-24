# Card Dimensions Guide - Home Screen

## Overview
The card dimensions in the home screen are controlled in **TWO PLACES**:

### 1. Home Screen Container (Width)
### 2. Widget Component (Height/Aspect Ratio)

---

## 🏢 Company Cards

### Width: Controlled in `homeScreen.dart`
**Location:** `lib/feature/home/presentation/homeScreen.dart`
- **Line 568-570:** `SizedBox(height: 100)` - Container height for company section
- **NO width specified** - Companies use responsive sizing

### Height/Size: Controlled in Widget
**Location:** `lib/feature/home/presentation/widget/company_name_scrol.dart`
- **Lines 32-34:** Responsive sizing based on screen width
  ```dart
  final double logoRadius = screenWidth * 0.08; // 8% of screen width
  final double padding = screenWidth * 0.015;   // 1.5% of screen width
  final double fontSize = screenWidth * 0.04;   // 4% of screen width
  ```
- **Companies are RESPONSIVE** - they scale with screen size
- The widget itself controls ALL dimensions

---

## 🏘️ Compound Cards (Recommended Compounds)

### Width: Controlled in `homeScreen.dart`
**Location:** `lib/feature/home/presentation/homeScreen.dart`
- **Line 791-793:**
  ```dart
  return SizedBox(
    width: 190,  // ← COMPOUND CARD WIDTH
    child: Padding(...)
  ```

### Height: Controlled in Widget
**Location:** `lib/feature/home/presentation/widget/compunds_name.dart`
- The widget uses **automatic height** based on its content
- No fixed height - it wraps content naturally
- The card expands based on image aspect ratio and text content

**To change compound card size in home screen:**
- **Width:** Edit line 792 in `homeScreen.dart`
- **Height:** The widget auto-sizes, but you can add constraints in the widget file

---

## 🏠 Unit Cards (New Arrivals & Updated 24h)

### Width: Controlled in `homeScreen.dart`
**Location:** `lib/feature/home/presentation/homeScreen.dart`

**New Arrivals Section:**
- **Line 1381-1382:**
  ```dart
  return Container(
    width: 190,  // ← UNIT CARD WIDTH
    margin: EdgeInsets.only(...)
  ```

**Updated 24 Hours Section:**
- **Line 1648-1649:** Same structure with `width: 190`

### Height: Controlled in Widget
**Location:** `lib/feature/compound/presentation/widget/unit_card.dart`
- **Line 99-100:**
  ```dart
  child: AspectRatio(
    aspectRatio: 0.72,  // ← WIDTH TO HEIGHT RATIO
  ```
- **AspectRatio of 0.72** means:
  - If width = 190, then height = 190 / 0.72 = **264 pixels**

**To change unit card size in home screen:**
- **Width:** Edit lines 1382 and 1649 in `homeScreen.dart`
- **Height:** Edit aspectRatio in line 100 of `unit_card.dart`
  - Lower number = taller card (e.g., 0.6 = much taller)
  - Higher number = shorter card (e.g., 0.85 = shorter/wider)

---

## Summary Table

| Card Type | Width Location | Height Location | Current Width | Current Height |
|-----------|---------------|-----------------|---------------|----------------|
| **Company** | homeScreen.dart line 568 (container: 100) | company_name_scrol.dart (responsive) | Responsive (8% screen) | 100 (container) |
| **Compound** | homeScreen.dart line 792 | compunds_name.dart (auto) | 190 | Auto |
| **Unit** | homeScreen.dart lines 1382, 1649 | unit_card.dart line 100 | 190 | ~264 (0.72 ratio) |

---

## Quick Edit Guide

### To Make Cards Bigger:
1. **Compounds & Units Width:** Increase the number in `width: 190` (e.g., `width: 220`)
2. **Unit Height:** Decrease aspectRatio (e.g., `aspectRatio: 0.65` for taller cards)

### To Make Cards Smaller:
1. **Compounds & Units Width:** Decrease the number in `width: 190` (e.g., `width: 160`)
2. **Unit Height:** Increase aspectRatio (e.g., `aspectRatio: 0.80` for shorter cards)

### To Keep Uniform Sizing:
- Use the **same width value** (190) for both compounds and units
- This creates visual consistency

---

## Important Notes

✅ **Width is in homeScreen.dart** - Easy to find and change
✅ **Height/AspectRatio is in widget files** - Maintains consistency across the app
✅ **Companies are fully responsive** - No fixed width
✅ **Changing aspectRatio affects ALL unit cards** across the entire app, not just home screen

## Date
2025-11-24
