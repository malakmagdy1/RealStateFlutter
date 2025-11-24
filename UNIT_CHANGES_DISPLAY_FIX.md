# Unit Changes Display Fix

## Problem
When viewing updated units, the note container was:
1. **Web**: Completely missing
2. **Mobile**: Showed only "UPDATED" status, missing detailed old→new value changes

## API Data Structure
The API returns updated units with this structure:
```json
{
  "activities": [
    {
      "action": "updated",
      "properties": {
        "changes": {
          "unit_type": "Town House",
          "number_of_beds": "3"
        },
        "original": {
          "unit_type": null,
          "number_of_beds": 5
        }
      },
      "unit": {
        "id": 5508,
        "is_updated": true,
        "last_changed_at": "2025-11-17T09:43:18.000000Z",
        // ... other unit fields
      }
    }
  ]
}
```

## Solution

### 1. Data Mapping (Already Working)
Both mobile (`lib/feature/home/presentation/homeScreen.dart`) and web (`lib/feature_web/home/presentation/web_home_screen.dart`) correctly map the activity data:

```dart
// Extract unit from activity
if (activity['unit'] != null) {
  final unitJson = Map<String, dynamic>.from(activity['unit'] as Map<String, dynamic>);

  // Map action → change_type
  if (activity['action'] != null) {
    unitJson['change_type'] = activity['action'];       // "updated"
    unitJson['is_updated'] = true;
  }

  // Map properties → change_properties
  if (activity['properties'] != null) {
    unitJson['change_properties'] = activity['properties'];  // {changes: {...}, original: {...}}
  }

  return Unit.fromJson(unitJson);
}
```

### 2. Mobile Display Fix
**File:** `lib/feature/compound/presentation/screen/unit_detail_screen.dart`

**Changes:**
- Added `_buildChangesTable()` method to display old→new value table
- Added `_formatFieldName()` helper to convert snake_case to Title Case
- Updated widget to check `changeProperties` first, fallback to `changedFields`

**Display Format (Mobile - Vertical Layout):**
```
┌─────────────────────────────┐
│ 🔶 Recent Changes          │
├─────────────────────────────┤
│ Status: UPDATED            │
│ Last Updated: Nov 17, 2025  │
│                             │
│ What Changed:               │
│                             │
│ Unit Type                   │
│ ┌─────────────────────┐    │
│ │ Old: null           │ ❌ │
│ └─────────────────────┘    │
│          ↓                  │
│ ┌─────────────────────┐    │
│ │ New: Town House     │ ✅ │
│ └─────────────────────┘    │
│                             │
│ Number Of Beds              │
│ ┌─────────────────────┐    │
│ │ Old: 5              │ ❌ │
│ └─────────────────────┘    │
│          ↓                  │
│ ┌─────────────────────┐    │
│ │ New: 3              │ ✅ │
│ └─────────────────────┘    │
└─────────────────────────────┘
```

### 3. Web Display (Already Implemented)
**File:** `lib/feature_web/compound/presentation/web_unit_detail_screen.dart`

**Display Format (Web - Horizontal Table):**
```
┌──────────────────────────────────────────────┐
│ 🔶 Recent Changes                           │
├──────────────────────────────────────────────┤
│ Status: UPDATED                              │
│ Last Updated: 17/11/2025 09:43               │
│                                              │
│ What Changed:                                │
│ ┌──────────────┬────────┬───┬─────────────┐ │
│ │ Unit Type    │ null   │ → │ Town House  │ │
│ ├──────────────┼────────┼───┼─────────────┤ │
│ │ Number Of Beds│ 5      │ → │ 3           │ │
│ └──────────────┴────────┴───┴─────────────┘ │
└──────────────────────────────────────────────┘
```

## Files Modified

### 1. Unit Model - **CRITICAL FIX**
**File:** `lib/feature/compound/data/models/unit_model.dart`
**Lines:** 362-375

**Problem:** The `toJson()` method was **missing** the update tracking fields, causing them to be lost during navigation!

**Changes:**
```dart
// Added to toJson() method:
'normal_price': normalPrice,
'note_id': noteId,
// Update tracking fields
'is_updated': isUpdated,
'last_changed_at': lastChangedAt,
'change_type': changeType,
'changed_fields': changedFields,
'change_properties': changeProperties,
```

**Why this matters:** When navigating to unit detail screen on web, it uses:
```dart
context.push('/unit/${unit.id}', extra: unit.toJson());
```
Without these fields in `toJson()`, the change information was lost during navigation!

### 2. Mobile Unit Detail Screen
**File:** `lib/feature/compound/presentation/screen/unit_detail_screen.dart`
**Lines:** 1837-2073

**Added Methods:**
- `_buildChangesTable()` - Displays old→new value table (vertical layout)
- `_formatFieldName()` - Converts snake_case to Title Case

**Enhanced:** Debug logging to show unit change details

### 3. Web Unit Detail Screen
**File:** `lib/feature_web/compound/presentation/web_unit_detail_screen.dart`
**Lines:** 1971-1977

**Changes:**
- Enhanced debug logging to troubleshoot display issues

### 4. Mobile Home Screen
**File:** `lib/feature/home/presentation/homeScreen.dart`
**Lines:** 1837-1843

**Changes:**
- Enhanced debug logging to troubleshoot display issues

## Debug Logging Added

Both mobile and web now log when displaying the change notes:
```
[UNIT CHANGE NOTES WEB/MOBILE] ========================================
[UNIT CHANGE NOTES WEB/MOBILE] Unit ID: 5508
[UNIT CHANGE NOTES WEB/MOBILE] isUpdated: true
[UNIT CHANGE NOTES WEB/MOBILE] changeType: updated
[UNIT CHANGE NOTES WEB/MOBILE] changeProperties: {changes: {unit_type: Town House, number_of_beds: 3}, original: {unit_type: null, number_of_beds: 5}}
[UNIT CHANGE NOTES WEB/MOBILE] lastChangedAt: 2025-11-17T09:43:18.000000Z
[UNIT CHANGE NOTES WEB/MOBILE] ========================================
```

## How It Works

### Display Logic
```dart
if (unit.changeProperties != null) {
  // Show detailed changes table with old→new values
  _buildChangesTable(unit.changeProperties);
} else if (unit.changedFields != null) {
  // Fallback: Show just field names as chips
  // (for backwards compatibility)
}
```

### Changes Table Logic
```dart
Widget _buildChangesTable(Map<String, dynamic> properties) {
  final changes = properties['changes'];    // New values
  final original = properties['original'];  // Old values

  // For each changed field, display:
  // - Field name (formatted)
  // - Old value (red, strikethrough)
  // - Arrow/indicator
  // - New value (green, bold)
}
```

### Field Name Formatting
```dart
String _formatFieldName(String fieldName) {
  // "unit_type" → "Unit Type"
  // "number_of_beds" → "Number Of Beds"
  return fieldName
      .split('_')
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
```

## Result

Users can now see:
- ✅ **Mobile**: Orange note container with detailed old→new value changes (vertical layout)
- ✅ **Web**: Orange note container with detailed old→new value changes (horizontal table)
- ✅ **Both**: Shows what fields changed and their before/after values
- ✅ **Example**: "Unit Type: null → Town House", "Number Of Beds: 5 → 3"

## Testing

### Mobile:
1. Go to Home screen
2. Scroll to "Updated Units (24h)" section
3. Tap on any updated unit
4. Verify orange note container appears with detailed changes table

### Web:
1. Go to Home screen
2. Scroll to "Updated Last 24h" section
3. Click on any updated unit
4. Verify orange note container appears in right column with changes table

## Notes

- The note container only appears if `isUpdated == true`
- If `changeProperties` is null, falls back to showing `changedFields` as chips (backwards compatibility)
- Mobile uses vertical layout (better for narrow screens)
- Web uses horizontal table layout (better for wide screens)
- Field names are automatically formatted from snake_case to Title Case
- Old values shown in red with strikethrough
- New values shown in green with bold
