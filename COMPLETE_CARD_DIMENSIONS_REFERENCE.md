# Complete Card Dimensions Reference - Mobile & Web

**Last Updated**: 2025-11-23
**Version**: 2.0
**Platforms**: Mobile (Android/iOS) & Web

---

## 📱 MOBILE CARD DIMENSIONS

### 1. Mobile Unit Card

**File**: `lib/feature/compound/presentation/widget/unit_card.dart`

#### Container
- **Aspect Ratio**: `0.72` (width to height ratio)
- **Border Radius**: `24px`
- **Background**: White
- **Box Shadow**:
  - Base: `blurRadius: 4, offset: (0, 8), opacity: 0.08`
  - Pressed: `blurRadius: 12, offset: (0, 8), opacity: 0.08`
- **Scale Animation**: `1.0 → 0.98` (on press)
- **Elevation Animation**: `4.0 → 12.0`

#### Action Buttons (Top Left)
- **Position**: `top: 8, left: 8`
- **Button Size**: `28×28`
- **Icon Size**: `14`
- **Background**: `Colors.black.withOpacity(0.35)`
- **Active Note/Compare**: `AppColors.mainColor.withOpacity(0.9)`
- **Spacing**: `4px` between buttons
- **Buttons**: Favorite, Note, Share, Compare (4 total)
- **Favorite Active Color**: Red
- **Shape**: Circle

#### Sale/Update Badges
- **Sale Badge**:
  - Position: `top: 8, right: -30`
  - Rotation: `45 degrees (0.785398)`
  - Size: `120×22`
  - Padding: `left: 30, right: 8, top: 5, bottom: 5`
  - Font Size: `9`
  - Background: `#FF6B6B`

- **Update Badge**:
  - Position: `top: 40, right: -30` (if sale exists, else `top: 8`)
  - Rotation: `45 degrees`
  - Size: `120×22`
  - Padding: Same as sale badge
  - Font Size: `9`
  - Colors:
    - NEW: `#4CAF50`
    - UPDATED: `#FF9800`
    - DELETED: `#D32F2F`

#### Bottom Info Container
- **Background**: `Colors.white.withOpacity(0.90)`
- **Border Radius**: `bottomLeft: 24, bottomRight: 24`
- **Padding**: `6px all`

#### Text Elements
- **Unit Name**: `fontSize: 16, fontWeight: bold`
- **Unit Type**: `fontSize: 12, color: grey[600]`
- **Location Icon**: `size: 12`
- **Location Text**: `fontSize: 11, color: grey[700]`
- **Price**: `fontSize: 16, fontWeight: bold, color: mainColor`

#### Detail Chips
- **Padding**: `horizontal: 6, vertical: 3`
- **Border Radius**: `10`
- **Icon Size**: `12`
- **Text Size**: `fontSize: 10, fontWeight: w600`
- **Spacing**: `2px`

#### Phone Button
- **Size**: `32×32`
- **Icon Size**: `18`
- **Color**: `#26A69A`
- **Shape**: Circle

---

### 2. Mobile Compound Card

**File**: `lib/feature/home/presentation/widget/compunds_name.dart`

#### Container
- **Border Radius**: `24px`
- **Background**: White
- **Box Shadow**: `blurRadius: 4-12, offset: (0, 8), opacity: 0.08`
- **Scale Animation**: `1.0 → 0.98` (on press)
- **Elevation Animation**: `4.0 → 12.0`

#### Action Buttons (Top Left)
- **Position**: `top: 8, left: 8`
- **Button Size**: `32×32`
- **Icon Size**: `16`
- **Background**: `Colors.black.withOpacity(0.35)`
- **Spacing**: `4px`
- **Buttons**: Favorite, Share, Note, Compare

#### Updated Units Badge
- **Position**: `top: 8, left: 100`
- **Padding**: `horizontal: 8, vertical: 4`
- **Border Radius**: `12`
- **Icon Size**: `14`
- **Text Size**: `fontSize: 11, fontWeight: w800`
- **Gradient**: `#FF3B30 → #FF6B6B`

#### Bottom Info Container
- **Background**: `Colors.white.withOpacity(0.90)`
- **Border Radius**: `bottomLeft: 24, bottomRight: 24`
- **Padding**: `8px all`

#### Text Elements
- **Compound Name**: `fontSize: 16, fontWeight: bold`
- **Company Name**: `fontSize: 12, color: grey[600]`
- **Location Icon**: `size: 12`
- **Location Text**: `fontSize: 11, color: grey[700]`

#### Info Chips
- **Padding**: `horizontal: 6, vertical: 3`
- **Border Radius**: `10`
- **Icon Size**: `12`
- **Text Size**: `fontSize: 10`
- **Spacing**: `2px`

#### Phone Button
- **Size**: `32×32`
- **Icon Size**: `18`
- **Color**: `#26A69A`

---

### 3. Mobile Company Card

**File**: `lib/feature/company/presentation/widget/company_card.dart`

#### Container
- **Margin**: `horizontal: 12, vertical: 6`
- **Border Radius**: `24px`
- **Background**: White
- **Box Shadow**: `blurRadius: 8, offset: (0, 4), opacity: 0.08`

#### Logo Section
- **Height**: `120px`
- **Width**: `double.infinity`
- **Background**: `mainColor.withOpacity(0.1)`
- **Fit**: `BoxFit.cover`

#### Compare Button (on Logo)
- **Position**: `top: 8, right: 8`
- **Size**: `28×28`
- **Icon Size**: `14`
- **Background**: `Colors.black.withOpacity(0.35)`
- **Shape**: Circle

#### Info Section
- **Padding**: `10px all`

#### Text Elements
- **Company Name**:
  - Icon: `size: 16, mainColor`
  - Font: `fontSize: 14, fontWeight: bold`
  - Icon Spacing: `4px`

- **Email**:
  - Icon: `size: 12, greyText`
  - Font: `fontSize: 11, color: greyText`
  - Icon Spacing: `4px`
  - Spacing After: `6px`

#### Stats Section
- **Divider**: `height: 1, color: grey.shade200`
- **Spacing**: `6px`
- **Stat Items**:
  - Icon Size: `16`
  - Value Font: `fontSize: 13, fontWeight: w700, mainColor`
  - Label Font: `fontSize: 10, color: grey[600]`
  - Separator: `width: 1, height: 24`

---

## 🌐 WEB CARD DIMENSIONS

### 1. Web Unit Card

**File**: `lib/feature_web/widgets/web_unit_card.dart`

#### Container
- **Border Radius**: `24px`
- **Box Shadow**:
  - Base: `blurRadius: 12, offset: (0, 8), opacity: 0.08`
  - Hover: `blurRadius: 12, offset: (0, 8), opacity: 0.12`
- **Scale Animation**: `1.0 → 1.03` on hover
- **Elevation Animation**: `4.0 → 12.0`

#### Action Buttons (Top Left)
- **Position**: `top: 20, left: 12`
- **Button Size**: `32×32`
- **Icon Size**: `16`
- **Background**: `Colors.black.withOpacity(0.35)`
- **Spacing**: `4px`
- **Buttons**: Favorite, Share, Note, Compare

#### Sale/Update Badges (Top Right)
- **Sale Badge**:
  - Position: `top: 8, right: -35`
  - Rotation: `45 degrees`
  - Size: `140×25`
  - Padding: `left: 35, right: 10, top: 6, bottom: 6`
  - Font Size: `10`
  - Color: `#FF6B6B`

- **Update Badge**:
  - Position: `top: 48, right: -35` (if sale exists, else `top: 8`)
  - Size/Padding/Rotation: Same as sale badge

#### Bottom Info Container
- **Background**: `Colors.white.withOpacity(0.90)`
- **Border Radius**: `bottomLeft: 24, bottomRight: 24`
- **Padding**: `8px all`

#### Company Logo
- **Size**: `24×24` (radius: 12)
- **Right Padding**: `8px`

#### Text Elements
- **Unit Name**: `fontSize: 18, fontWeight: bold`
- **Unit Type**: `fontSize: 13, fontWeight: w500`
- **Location Icon**: `size: 14`
- **Location Text**: `fontSize: 13`
- **Price**: `fontSize: 18, fontWeight: bold`

#### Detail Chips
- **Padding**: `horizontal: 8, vertical: 4`
- **Border Radius**: `12`
- **Icon Size**: `14`
- **Text Size**: `fontSize: 12, fontWeight: w600`
- **Spacing**: `2px`

#### Phone Button
- **Size**: `35×35`
- **Icon Size**: `20`
- **Color**: `#26A69A`

---

### 2. Web Compound Card

**File**: `lib/feature_web/widgets/web_compound_card.dart`

#### Container
- **Border Radius**: `24px`
- **Box Shadow**: `blurRadius: 10-30, offset: (0, 2.68-8.04)`
- **Scale Animation**: `1.0 → 1.03`
- **Elevation Animation**: `4.0 → 12.0`

#### Action Buttons (Top Left)
- **Position**: `top: 20, left: 12`
- **Button Size**: `32×32`
- **Icon Size**: `16`
- **Background**: `Colors.black.withOpacity(0.35)`
- **Spacing**: `4px`

#### Updated Units Badge
- **Position**: `top: 20, left: 110`
- **Padding**: `horizontal: 8, vertical: 4`
- **Border Radius**: `12`
- **Icon Size**: `14`
- **Text Size**: `fontSize: 12, fontWeight: w800`
- **Gradient**: `#FF3B30 → #FF6B6B`

#### Bottom Info Container
- **Background**: `Colors.white.withOpacity(0.90)`
- **Border Radius**: `bottomLeft: 24, bottomRight: 24`
- **Padding**: `8px all`

#### Company Logo
- **Size**: `24×24` (radius: 12)
- **Right Padding**: `8px`

#### Text Elements
- **Compound Name**: `fontSize: 18, fontWeight: bold`
- **Company Name**: `fontSize: 13, fontWeight: w500`
- **Location Icon**: `size: 14`
- **Location Text**: `fontSize: 13`

#### Info Chips
- **Padding**: `horizontal: 8, vertical: 4`
- **Border Radius**: `12`
- **Icon Size**: `14`
- **Text Size**: `fontSize: 12, fontWeight: w500`
- **Spacing**: `2px`

#### Phone Button
- **Size**: `35×35`
- **Icon Size**: `20`
- **Color**: `#26A69A`

---

### 3. Web Company Card

**File**: `lib/feature_web/widgets/web_company_card.dart`

#### Container
- **Border Radius**: `10px`
- **Border**: `1px solid #E6E6E6`
- **Box Shadow**: `blurRadius: 4-16, offset: (0, 2-8)`
- **Scale Animation**: `1.0 → 1.03`
- **Elevation Animation**: `2.0 → 8.0`
- **Padding**: `20px all`

#### Company Logo
- **Size**: `50×50`
- **Border Radius**: `8`
- **Background**: `#F8F9FA`
- **Padding**: `6`
- **Image Size**: `38×38`
- **Right Margin**: `16px`

#### Compare Button
- **Size**: `36×36`
- **Icon Size**: `18`
- **Background**: `mainColor.withOpacity(0.1)`
- **Border**: `mainColor.withOpacity(0.3), width: 1`
- **Shape**: Circle

#### Text Elements
- **Company Name**: `fontSize: 16, fontWeight: w600`

#### Stat Containers
- **Padding**: `12px all`
- **Border Radius**: `8`
- **Background**: `#F8F9FA`
- **Spacing Between**: `16px`
- **Value Font**: `fontSize: 20, fontWeight: w700`
- **Label Font**: `fontSize: 12, fontWeight: w500`

---

## 📊 SCREEN LAYOUTS

### Mobile Screens

#### Home Screen
- **Compounds Grid**:
  - Columns: `2`
  - Aspect Ratio: `0.63`
  - Cross Spacing: `8px`
  - Main Spacing: `8px`
  - Padding: `left: 8, right: 8, bottom: 120`

#### Favorites Screen
- **Units Grid**:
  - Columns: `2`
  - Aspect Ratio: `0.72`
  - Cross Spacing: `8px`
  - Main Spacing: `8px`
- **Compounds Grid**:
  - Columns: `2`
  - Aspect Ratio: `0.63`
  - Cross Spacing: `8px`
  - Main Spacing: `8px`

#### History Screen
- **Same as Favorites**

#### Compounds Screen
- **Grid Configuration**:
  - Columns: `2`
  - Aspect Ratio: `0.63`
  - Cross Spacing: `8px`
  - Main Spacing: `8px`
  - Padding: `left: 8, right: 8, top: 8, bottom: 120`
- **Pagination**: 10 items per page
- **Scroll Trigger**: 80% scroll threshold

---

### Web Screens

#### Home Screen
- **Max Container Width**: `1400px`
- **Recommended Compounds**:
  - Card Width: `250px`
  - Spacing: `10px`
  - Scroll: 4 cards at a time
- **Units**:
  - Card Width: `260px`
  - Spacing: `10px`
  - Scroll: 4 cards at a time

#### Favorites Screen
- **Max Container Width**: `1400px`
- **Padding**: `32px all`
- **Units Grid**:
  - Max Cross Extent: `320px`
  - Aspect Ratio: `0.68`
  - Spacing: `10×10px`
- **Compounds Grid**:
  - Max Cross Extent: `380px`
  - Aspect Ratio: `0.757`
  - Spacing: `10×10px`

#### History Screen
- **Same as Favorites**

#### Compounds Screen
- **Max Container Width**: `1400px`
- **Grids**: Same as Favorites/History
- **Pagination**: 10 items per page
- **Scroll Trigger**: 200px from bottom

---

## 📏 COMPARISON TABLE

### Card Sizes

| Platform | Card Type | Aspect Ratio | Border Radius | Hover/Press Scale |
|----------|-----------|--------------|---------------|-------------------|
| Mobile   | Unit      | 0.72         | 24px          | 1.0 → 0.98 (press)|
| Mobile   | Compound  | 0.63         | 24px          | 1.0 → 0.98 (press)|
| Mobile   | Company   | Variable     | 24px          | HoverScale        |
| Web      | Unit      | 0.68         | 24px          | 1.0 → 1.03 (hover)|
| Web      | Compound  | 0.757        | 24px          | 1.0 → 1.03 (hover)|
| Web      | Company   | Variable     | 10px          | 1.0 → 1.03 (hover)|

### Button Sizes

| Platform | Button Type          | Size  | Icon Size |
|----------|---------------------|-------|-----------|
| Mobile   | Action Buttons      | 28×28 | 14        |
| Mobile   | Compound Actions    | 32×32 | 16        |
| Mobile   | Phone Button        | 32×32 | 18        |
| Mobile   | Company Compare     | 28×28 | 14        |
| Web      | Action Buttons      | 32×32 | 16        |
| Web      | Phone Button        | 35×35 | 20        |
| Web      | Company Compare     | 36×36 | 18        |

### Spacing Values

| Platform | Type              | Value     |
|----------|-------------------|-----------|
| Mobile   | Grid Cross        | 8px       |
| Mobile   | Grid Main         | 8px       |
| Mobile   | Button Spacing    | 4px       |
| Mobile   | Info Padding      | 6-8px     |
| Web      | Grid Cross        | 10px      |
| Web      | Grid Main         | 10px      |
| Web      | Button Spacing    | 4px       |
| Web      | Info Padding      | 8px       |
| Web      | Section Padding   | 32px      |

### Text Sizes

| Platform | Element       | Mobile | Web |
|----------|---------------|--------|-----|
| Card Title | Unit/Compound | 16     | 18  |
| Subtitle   | Type/Company  | 12     | 13  |
| Location   | Text          | 11     | 13  |
| Price      | Amount        | 16     | 18  |
| Chip Text  | Details       | 10     | 12  |
| Chip Icon  | Details       | 12     | 14  |

---

## 🎨 COLOR REFERENCE

| Element               | Color Code    |
|----------------------|---------------|
| Main Color           | `AppColors.mainColor` |
| Background           | `#F8F9FA`     |
| Card Background      | `#FFFFFF`     |
| Text Primary         | `#333333`     |
| Text Secondary       | `#666666`     |
| Grey Text            | `#999999`     |
| Border               | `#E6E6E6`     |
| Phone Button         | `#26A69A`     |
| Sale Badge           | `#FF6B6B`     |
| New Badge            | `#4CAF50`     |
| Updated Badge        | `#FF9800`     |
| Deleted Badge        | `#D32F2F`     |
| Active Note/Compare  | `mainColor @ 90%` |
| Button Background    | `black @ 35%` |

---

## 🔄 ANIMATION DETAILS

### Mobile
- **Scale**: `1.0 → 0.98` (press down)
- **Elevation**: `4 → 12` (dynamic)
- **Duration**: `200ms`
- **Curve**: `Curves.easeOut`

### Web
- **Scale**: `1.0 → 1.03` (hover)
- **Elevation**: `4 → 12` (dynamic)
- **Duration**: `200ms`
- **Curve**: `Curves.easeOut`

### Shared
- **Pulse Animation**: `600ms` duration
- **Favorite/Compare**: Pulse effect on tap
- **Badge Rotation**: `45 degrees (0.785398 radians)`

---

## 📱 RESPONSIVE BEHAVIOR

### Mobile
- Fixed 2-column grid
- Consistent 8px spacing
- Bottom padding: 120px (for floating buttons)
- ClampingScrollPhysics for smooth scrolling

### Web
- `maxCrossAxisExtent` for responsive columns
- Maximum container width: 1400px
- Hover states with scale/shadow effects
- Horizontal scrolling with arrow navigation
- Pagination with auto-load on scroll

---

## 🚀 PERFORMANCE NOTES

### Mobile
- **Pagination**: 10 items per page
- **Scroll Trigger**: 80% scroll threshold
- **Grid Physics**: `AlwaysScrollableScrollPhysics`
- **Loading Indicator**: 2 grid cells (40px dots)

### Web
- **Pagination**: 10 items per page
- **Scroll Trigger**: 200px from bottom (or 80%)
- **Grid Physics**: `NeverScrollableScrollPhysics` (in SingleChildScrollView)
- **Card Hover**: Preload next page when near bottom

---

**Generated By**: Claude Code
**Project**: Real Estate App
**Documentation**: Complete Card Dimensions Reference
