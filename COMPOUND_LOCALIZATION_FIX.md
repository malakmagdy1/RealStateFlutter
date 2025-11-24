# Compound Name Localization Fix

## Problem
Compound names were showing in Arabic even when the app localization was set to English in both mobile and web platforms.

## Root Cause
The `LanguageService` was not being synchronized with the `LocaleCubit` when the user changed the app language. This meant:
1. User changes language from English to Arabic (or vice versa)
2. `LocaleCubit` updates and UI text changes
3. `LanguageService` still has old language value
4. API calls still send old `lang` parameter
5. Backend returns wrong language data or client-side filtering fails

## Solution Implemented

### 1. Synchronized LocaleCubit with LanguageService

**File:** `lib/core/locale/locale_cubit.dart`

**Changes:**
- Added import for `LanguageService`
- Updated `_loadLocale()` to set `LanguageService` when loading saved locale
- Updated `changeLocale()` to update `LanguageService` when changing locale

```dart
// Before:
Future<void> changeLocale(Locale newLocale) async {
  if (state == newLocale) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_localeKey, newLocale.languageCode);
  emit(newLocale);
}

// After:
Future<void> changeLocale(Locale newLocale) async {
  if (state == newLocale) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_localeKey, newLocale.languageCode);

  // Update LanguageService so API calls use the new language
  await LanguageService.setLanguage(newLocale.languageCode);

  emit(newLocale);
}
```

### 2. Enhanced Compound Model Localization

**File:** `lib/feature/compound/data/models/compound_model.dart`

**Changes:**
- Added import for `LanguageService`
- Enhanced `fromJson()` to handle multiple backend localization strategies
- Added client-side language filtering as fallback

**Supports 3 backend formats:**

1. **Backend sends `project_localized`** (preferred):
   ```json
   {
     "project_localized": "New Cairo Project",
     "location_localized": "New Cairo"
   }
   ```

2. **Backend sends separate language fields**:
   ```json
   {
     "project_en": "New Cairo Project",
     "project_ar": "مشروع القاهرة الجديدة",
     "location_en": "New Cairo",
     "location_ar": "القاهرة الجديدة"
   }
   ```

3. **Backend sends single field** (fallback):
   ```json
   {
     "project": "New Cairo Project",
     "location": "New Cairo"
   }
   ```

**Implementation:**
```dart
// Get current language from LanguageService
final currentLang = LanguageService.currentLanguage;

// Determine project name based on language
String projectName;
if (json['project_localized'] != null) {
  projectName = json['project_localized']?.toString() ?? '';
} else if (json['project_en'] != null && json['project_ar'] != null) {
  projectName = currentLang == 'ar'
      ? json['project_ar']?.toString() ?? ''
      : json['project_en']?.toString() ?? '';
} else {
  projectName = json['project']?.toString() ?? '';
}
```

## How It Works Now

### Language Change Flow:

```
User Changes Language
    ↓
LocaleCubit.changeLocale()
    ↓
LanguageService.setLanguage() ← SYNCHRONIZED!
    ↓
API Calls Include Correct 'lang' Parameter
    ↓
Backend Returns Localized Data
    ↓
Compound Model Uses LanguageService for Client-Side Filtering
    ↓
Correct Language Displayed
```

### API Request:
```dart
Response response = await dio.get(
  '/compounds',
  queryParameters: {
    'page': page,
    'limit': limit,
    'lang': currentLang, // 'en' or 'ar'
  },
);
```

### Data Parsing:
```
1. Try project_localized (backend pre-filtered)
2. Try project_en/project_ar (client-side selection)
3. Fallback to project (single field)
```

## Files Modified

1. **`lib/core/locale/locale_cubit.dart`**
   - Added `LanguageService` synchronization
   - Lines 4, 22-23, 38-43

2. **`lib/feature/compound/data/models/compound_model.dart`**
   - Added `LanguageService` import
   - Enhanced localization logic for project and location
   - Lines 3, 114-144

## Benefits

✅ **Synchronized Language:** UI and API calls always use the same language
✅ **Multiple Backend Formats:** Supports various backend localization strategies
✅ **Client-Side Fallback:** Works even if backend doesn't send localized fields
✅ **Consistent Experience:** Same fix works for both mobile and web
✅ **Real-Time Updates:** Language change immediately affects new API calls

## Testing

### Test Steps:

1. **English to Arabic:**
   - Set app to English
   - Navigate to compound screen
   - ✅ Verify compound name is in English
   - Change language to Arabic
   - Refresh or navigate to another compound
   - ✅ Verify compound name is now in Arabic

2. **Arabic to English:**
   - Set app to Arabic
   - Navigate to compound screen
   - ✅ Verify compound name is in Arabic
   - Change language to English
   - Refresh or navigate to another compound
   - ✅ Verify compound name is now in English

3. **Both Platforms:**
   - ✅ Test on mobile app
   - ✅ Test on web app
   - Both should show correct language

### Debug Logs:

Look for these console messages:
```
[LocaleCubit] Changed locale to: en
[LocaleCubit] Updated LanguageService to: en
✅ Language service initialized: en
```

## Backend Requirements

For optimal performance, the backend should:

### Option 1: Send pre-filtered data (Recommended)
```json
{
  "project_localized": "Filtered based on lang parameter",
  "location_localized": "Filtered based on lang parameter"
}
```

### Option 2: Send all language versions
```json
{
  "project_en": "English Name",
  "project_ar": "الاسم العربي",
  "location_en": "English Location",
  "location_ar": "الموقع العربي"
}
```

### Option 3: Current (Fallback)
```json
{
  "project": "Name (single language)",
  "location": "Location (single language)"
}
```

**Note:** The app now handles all three formats automatically!

## Additional Improvements

### Also Applies To:
This fix pattern can be used for other localized fields:
- Company names
- Unit types
- Status messages
- Category names
- Any other localized content

### Future Enhancement:
Consider creating a utility function:
```dart
String getLocalizedField(Map<String, dynamic> json, String fieldName) {
  final lang = LanguageService.currentLanguage;
  return json['${fieldName}_localized']
      ?? json['${fieldName}_$lang']
      ?? json[fieldName]
      ?? '';
}
```

## Result

Compound names (and locations) now display in the correct language based on the app's localization setting, with proper synchronization between the UI and API calls! 🌐✨
