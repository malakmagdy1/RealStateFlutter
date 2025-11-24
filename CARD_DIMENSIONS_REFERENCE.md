# Card Dimensions Reference Guide

This document provides a comprehensive overview of how compound cards and unit cards are dimensioned across all screens in both web and mobile platforms.

## Card Types

### 1. Compound Card (CompoundsName widget - Mobile)
- **File**: `lib/feature/home/presentation/widget/compunds_name.dart`
- **Base Widget**: Custom card with animation controllers
- **Intrinsic Size**: Dynamic based on content and container constraints

### 2. Unit Card (UnitCard widget - Mobile)
- **File**: `lib/feature/compound/presentation/widget/unit_card.dart`
- **Base Widget**: Custom card with animation controllers
- **Intrinsic Size**: Dynamic based on content and container constraints

### 3. Web Compound Card (WebCompoundCard widget)
- **File**: `lib/feature_web/widgets/web_compound_card.dart`
- **Base Widget**: InkWell with hover effects
- **Intrinsic Size**: Dynamic based on content and container constraints

### 4. Web Unit Card (WebUnitCard widget)
- **File**: `lib/feature_web/widgets/web_unit_card.dart`
- **Base Widget**: InkWell with hover effects
- **Intrinsic Size**: Dynamic based on content and container constraints

---

## Web Screens Card Dimensions

### Web Home Screen (`lib/feature_web/home/presentation/web_home_screen.dart`)
**Compound Cards:**
- **Grid Type**: `SliverGridDelegateWithMaxCrossAxisExtent`
- **Max Cross Axis Extent**: 320px
- **Child Aspect Ratio**: 0.9 (width:height = 9:10)
- **Spacing**: mainAxisSpacing: 20, crossAxisSpacing: 20
- **Approximate Dimensions**: 320px wide × 355px tall
- **Usage**: Main compounds listing on home page

**Unit Cards:**
- **Grid Type**: `SliverGridDelegateWithMaxCrossAxisExtent`
- **Max Cross Axis Extent**: 320px
- **Child Aspect Ratio**: 0.9
- **Spacing**: mainAxisSpacing: 20, crossAxisSpacing: 20
- **Approximate Dimensions**: 320px wide × 355px tall
- **Usage**: Featured units section

### Web Compounds Screen (`lib/feature_web/compounds/presentation/web_compounds_screen.dart`)
**Compound Cards:**
- **Grid Type**: `SliverGridDelegateWithMaxCrossAxisExtent`
- **Max Cross Axis Extent**: 320px
- **Child Aspect Ratio**: 0.9
- **Spacing**: mainAxisSpacing: 20, crossAxisSpacing: 20
- **Approximate Dimensions**: 320px wide × 355px tall
- **Usage**: All compounds listing and search results

### Web Favorites Screen (`lib/feature_web/favorites/presentation/web_favorites_screen.dart`)
**Unit Cards:**
- **Grid Type**: `SliverGridDelegateWithMaxCrossAxisExtent`
- **Max Cross Axis Extent**: 300px (FIXED - updated recently)
- **Child Aspect Ratio**: 0.75 (width:height = 3:4)
- **Spacing**: crossAxisSpacing: 20, mainAxisSpacing: 20
- **Approximate Dimensions**: 300px wide × 400px tall
- **Usage**: Saved favorite units

**Compound Cards:**
- **Grid Type**: `SliverGridDelegateWithMaxCrossAxisExtent`
- **Max Cross Axis Extent**: 300px (FIXED - updated recently)
- **Child Aspect Ratio**: 0.75
- **Spacing**: crossAxisSpacing: 20, mainAxisSpacing: 20
- **Approximate Dimensions**: 300px wide × 400px tall
- **Usage**: Saved favorite compounds

### Web History Screen (`lib/feature_web/history/presentation/web_history_screen.dart`)
**Mixed Cards (Units and Compounds):**
- **Grid Type**: `SliverGridDelegateWithMaxCrossAxisExtent`
- **Max Cross Axis Extent**: 300px (FIXED - updated recently)
- **Child Aspect Ratio**: 0.9
- **Spacing**: mainAxisSpacing: 20, crossAxisSpacing: 20
- **Approximate Dimensions**: 300px wide × 333px tall
- **Usage**: Recently viewed units and compounds

### Web Company Detail Screen (`lib/feature_web/company/presentation/web_company_detail_screen.dart`)
**Company Stats Cards:**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 3 columns
- **Child Aspect Ratio**: 2.5 (width:height = 5:2)
- **Usage**: Company statistics display (total units, compounds, etc.)

**Compound Cards:**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 3 columns
- **Child Aspect Ratio**: 1.1 (width:height = 11:10)
- **Usage**: Company's compounds listing

### Web Compound Detail Screen (`lib/feature_web/compound/presentation/web_compound_detail_screen.dart`)
**Unit Filter Cards:**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 3 columns
- **Child Aspect Ratio**: 1.2
- **Usage**: Filter buttons for unit types

**Unit Cards (Main Grid):**
- **Grid Type**: `SliverGridDelegateWithMaxCrossAxisExtent`
- **Child Aspect Ratio**: 0.9
- **Usage**: Units in the selected compound

**Similar Units:**
- **Grid Type**: `SliverGridDelegateWithMaxCrossAxisExtent`
- **Max Cross Axis Extent**: 400px
- **Child Aspect Ratio**: 0.85
- **Approximate Dimensions**: 400px wide × 470px tall
- **Usage**: Recommended similar units

**Unit Type Cards:**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 6 columns
- **Child Aspect Ratio**: 2.5
- **Usage**: Unit type selection chips

---

## Mobile Screens Card Dimensions

### Mobile Home Screen (`lib/feature/home/presentation/homeScreen.dart`)
**Company Stats Cards:**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 3 columns
- **Child Aspect Ratio**: 0.9
- **Usage**: Statistics overview

**Unit Cards (Featured/Recent):**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 2 columns
- **Child Aspect Ratio**: 0.63 (width:height = 63:100)
- **Spacing**: Standard grid spacing
- **Usage**: Featured units and recent units sections

**Compound Cards:**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 2 columns
- **Child Aspect Ratio**: 0.63
- **Usage**: Recent compounds section

### Mobile Favorites Screen (`lib/feature/home/presentation/FavoriteScreen.dart`)
**Unit Cards:**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 2 columns
- **Child Aspect Ratio**: 0.63
- **Usage**: Favorited units

**Compound Cards:**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 2 columns
- **Child Aspect Ratio**: 0.63
- **Usage**: Favorited compounds

### Mobile Compound Screen (`lib/feature/home/presentation/CompoundScreen.dart`)
**Compound Cards:**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 2 columns
- **Child Aspect Ratio**: Not specified in grep results (likely default)
- **Usage**: All compounds listing with infinite scroll

### Mobile Compounds Search Screen (`lib/feature/compound/presentation/screen/compounds_screen.dart`)
**Unit Cards (Multiple Sections):**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 2 columns
- **Child Aspect Ratio**: 0.63
- **Usage**:
  - Search results
  - Filter results
  - Category browsing
  - All sections use same dimensions

### Mobile Unit Detail Screen (`lib/feature/compound/presentation/screen/unit_detail_screen.dart`)
**Similar Units:**
- **Grid Type**: `SliverGridDelegateWithFixedCrossAxisCount`
- **Cross Axis Count**: 2 columns
- **Child Aspect Ratio**: Not specified in grep results
- **Usage**: Recommended similar units at bottom of detail screen

---

## Dimension Strategies

### Fixed Dimensions Strategy (Web - Favorites & History)
**Approach**: `SliverGridDelegateWithMaxCrossAxisExtent`
- Cards maintain consistent width (300px)
- Grid automatically adjusts number of columns based on screen width
- Prevents cards from shrinking when browser window resizes
- Better for screens where card size consistency is important

**Formula**:
- Columns = floor(screenWidth / (maxCrossAxisExtent + crossAxisSpacing))
- Card Height = maxCrossAxisExtent / childAspectRatio

### Responsive Column Strategy (Mobile)
**Approach**: `SliverGridDelegateWithFixedCrossAxisCount`
- Fixed number of columns (usually 2 for mobile)
- Cards resize proportionally with screen width
- Maintains aspect ratio but changes absolute dimensions
- Better for mobile where screen sizes vary less

**Formula**:
- Card Width = (screenWidth - padding - (n-1) × spacing) / n
- Card Height = Card Width / childAspectRatio

### Hybrid Strategy (Web - Company & Compound Detail)
**Approach**: Mix of both strategies
- Some sections use fixed columns for layout control
- Other sections use max extent for flexibility
- Depends on content type and design requirements

---

## Common Aspect Ratios Used

| Aspect Ratio | Description | Common Usage |
|--------------|-------------|--------------|
| 0.63 | Tall portrait (63:100) | Mobile unit cards - provides vertical space for images and details |
| 0.75 | Standard portrait (3:4) | Web favorites - balanced proportions |
| 0.85 | Near square portrait | Web similar units - slightly taller |
| 0.9 | Near square (9:10) | Web compounds, web history - compact square-ish layout |
| 1.1 | Near square landscape | Company compounds - slightly wider than tall |
| 1.2 | Landscape | Filter buttons - horizontal emphasis |
| 2.5 | Wide landscape (5:2) | Stats cards, type chips - wide horizontal layout |

---

## Key Differences Between Platforms

### Web vs Mobile Card Philosophy

**Web Platform**:
- Uses maxCrossAxisExtent (300-400px) for better control
- Larger absolute dimensions to utilize screen space
- More breathing room with 20px spacing
- Hover effects and interactions
- Recently updated favorites/history to maintain fixed 300px width

**Mobile Platform**:
- Uses fixed 2 columns for consistency
- Aspect ratio 0.63 is standard for main content cards
- Smaller spacing to maximize content
- Touch-optimized interactions
- Cards resize with device width

### Spacing Patterns
- **Web**: Typically 20px spacing (both main and cross)
- **Mobile**: Standard Flutter defaults (varies by screen)

---

## Recent Changes

### November 2025 - Fixed Web Card Dimensions
**Modified Files**:
1. `lib/feature_web/favorites/presentation/web_favorites_screen.dart`
2. `lib/feature_web/history/presentation/web_history_screen.dart`

**Changes**:
- Changed from `SliverGridDelegateWithFixedCrossAxisCount` (4 columns)
- To `SliverGridDelegateWithMaxCrossAxisExtent` (300px max)
- Prevents cards from shrinking when browser window resizes
- Cards now maintain consistent 300px width
- Grid adjusts number of columns automatically

---

## Implementation Notes

### When to Use Each Strategy

**Use `maxCrossAxisExtent` when**:
- You want cards to maintain minimum/maximum size
- Screen is primarily web-based
- Card content has optimal readable size
- User might resize browser window
- Examples: Favorites, History, Home compounds

**Use `fixedCrossAxisCount` when**:
- You want consistent column layout
- Mobile-first design
- Screen width is relatively fixed
- Layout needs to be predictable
- Examples: Mobile grids, stat cards, filter chips

### Calculating Actual Card Dimensions

For `maxCrossAxisExtent`:
```
Card Width = min(maxCrossAxisExtent, (availableWidth - spacing) / columns)
Card Height = Card Width / childAspectRatio
```

For `fixedCrossAxisCount`:
```
Card Width = (availableWidth - (columns - 1) × spacing - padding) / columns
Card Height = Card Width / childAspectRatio
```

---

## Summary Table

| Screen | Platform | Card Type | Strategy | Max Extent / Columns | Aspect Ratio | Approx Size |
|--------|----------|-----------|----------|---------------------|--------------|-------------|
| Web Home | Web | Compound | maxExtent | 320px | 0.9 | 320×355px |
| Web Compounds | Web | Compound | maxExtent | 320px | 0.9 | 320×355px |
| Web Favorites | Web | Unit | maxExtent | 300px | 0.75 | 300×400px |
| Web Favorites | Web | Compound | maxExtent | 300px | 0.75 | 300×400px |
| Web History | Web | Mixed | maxExtent | 300px | 0.9 | 300×333px |
| Web Company Detail | Web | Compound | fixedCount | 3 cols | 1.1 | Variable |
| Web Compound Detail | Web | Unit | maxExtent | 400px | 0.85 | 400×470px |
| Mobile Home | Mobile | Unit | fixedCount | 2 cols | 0.63 | Variable |
| Mobile Home | Mobile | Compound | fixedCount | 2 cols | 0.63 | Variable |
| Mobile Favorites | Mobile | Unit | fixedCount | 2 cols | 0.63 | Variable |
| Mobile Favorites | Mobile | Compound | fixedCount | 2 cols | 0.63 | Variable |
| Mobile Compounds | Mobile | Unit | fixedCount | 2 cols | 0.63 | Variable |
| Mobile Unit Detail | Mobile | Similar Units | fixedCount | 2 cols | - | Variable |

---

## Recommendations

1. **Consistency**: Mobile uses 0.63 aspect ratio consistently for main content cards
2. **Web Standards**: Web favorites/history now use fixed 300px width for better UX
3. **Spacing**: Web uses 20px spacing standard, maintain this for visual consistency
4. **Aspect Ratios**:
   - 0.63 for mobile portrait cards (primary content)
   - 0.75-0.9 for web cards (balanced proportions)
   - 2.5+ for wide stat/chip cards
5. **Future Changes**: When modifying card dimensions, consider:
   - Content readability
   - Image aspect ratios
   - Text wrapping
   - Button/action placement
   - Cross-platform consistency
