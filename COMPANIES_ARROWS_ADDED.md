# Companies Section - Navigation Arrows Added

## Changes Made

Added left/right navigation arrows to the companies horizontal scroll section, matching the style of other scrolling sections.

---

## File Modified

**File:** `lib/feature_web/home/presentation/web_home_screen.dart`

---

## Detailed Changes

### 1. Added Scroll Controller
**Lines 68:**
```dart
final ScrollController _companiesScrollController = ScrollController();
```

**Line 143:**
```dart
_companiesScrollController.dispose();
```

---

### 2. Added Scroll Methods
**Lines 231-257:**
```dart
// Scroll companies to the left (4 containers)
void _scrollCompaniesLeft() {
  final currentPosition = _companiesScrollController.offset;
  final containerWidth = 120.0; // Width of each company logo
  final spacing = 16.0; // Spacing between logos
  final scrollAmount = (containerWidth + spacing) * 4; // Move 4 containers

  _companiesScrollController.animateTo(
    currentPosition - scrollAmount,
    duration: Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );
}

// Scroll companies to the right (4 containers)
void _scrollCompaniesRight() {
  final currentPosition = _companiesScrollController.offset;
  final containerWidth = 120.0; // Width of each company logo
  final spacing = 16.0; // Spacing between logos
  final scrollAmount = (containerWidth + spacing) * 4; // Move 4 containers

  _companiesScrollController.animateTo(
    currentPosition + scrollAmount,
    duration: Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );
}
```

---

### 3. Added Navigation Arrows UI
**Lines 328-400:**

```dart
// Before:
CustomText20(l10n.companiesName),

// After:
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    CustomText20(l10n.companiesName),
    // Navigation arrows
    BlocBuilder<CompanyBloc, CompanyState>(
      builder: (context, state) {
        final showArrows = state is CompanySuccess &&
                          state.response.companies.isNotEmpty;
        if (!showArrows) return SizedBox.shrink();

        return Row(
          children: [
            // Left arrow
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _scrollCompaniesLeft,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.mainColor.withOpacity(0.3)
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.mainColor,
                    size: 20,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            // Right arrow (similar structure)
          ],
        );
      },
    ),
  ],
),
```

---

### 4. Connected ScrollController to ListView
**Line 417:**
```dart
// Before:
child: ListView.builder(
  scrollDirection: Axis.horizontal,
  itemCount: state.response.companies.length,

// After:
child: ListView.builder(
  controller: _companiesScrollController,  // ← Added
  scrollDirection: Axis.horizontal,
  itemCount: state.response.companies.length,
```

---

## Visual Result

### Before:
```
┌────────────────────────────────────────────────────┐
│  Companies                                         │
│                                                    │
│  ← Logo1 → ← Logo2 → ← Logo3 → ← Logo4 → ...      │
│                                                    │
└────────────────────────────────────────────────────┘
No navigation arrows ❌
```

### After:
```
┌────────────────────────────────────────────────────┐
│  Companies                            [←] [→]      │
│                                                    │
│  ← Logo1 → ← Logo2 → ← Logo3 → ← Logo4 → ...      │
│                                                    │
└────────────────────────────────────────────────────┘
Navigation arrows available ✅
```

---

## Features

### Arrow Behavior:
- **Visibility**: Only shown when companies are loaded and available
- **Scroll Amount**: Moves 4 company logos at a time
- **Animation**: Smooth 500ms easeInOut animation
- **Styling**: Matches other section arrows (same size, color, shadow)

### Arrow Styling:
- **Size**: 20px icons
- **Padding**: 8px
- **Border Radius**: 8px
- **Border Color**: Main color with 30% opacity
- **Background**: White
- **Shadow**: Light shadow for depth
- **Spacing**: 12px between arrows
- **Hover**: Mouse cursor changes to pointer

---

## Scroll Calculation

```dart
Container Width:  120px (company logo)
Spacing:          16px
Total per item:   136px
Scroll amount:    136px × 4 = 544px
```

---

## Consistency

All horizontal scroll sections now have navigation arrows:
- ✅ Companies row
- ✅ Updated 24h units
- ✅ New arrivals units
- ✅ Recommended compounds

All arrows use the same styling and behavior pattern.
