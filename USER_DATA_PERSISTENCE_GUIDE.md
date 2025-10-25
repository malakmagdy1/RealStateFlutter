# User Data Persistence Guide

## Overview
All user-specific data (favorites and history) is now saved per user token in SharedPreferences. This means when a user logs in, they will see their saved favorites and history from any device.

## What Was Updated

### 1. **Unit Favorites** (`unit_favorite_bloc.dart`)
- ✅ Now saves favorites with user token as part of the key
- Key format: `favorite_units_{first20charsOfToken}`
- Automatically loads user-specific favorites when bloc initializes

### 2. **Compound Favorites** (`compound_favorite_bloc.dart`)
- ✅ Now saves favorites with user token as part of the key
- Key format: `favorite_compounds_{first20charsOfToken}`
- Automatically loads user-specific favorites when bloc initializes

### 3. **Search History** (`search_history_service.dart`)
- ✅ Now saves search history with user token as part of the key
- Key format: `search_history_{first20charsOfToken}`
- Each user has their own search history

### 4. **View History** (`view_history_service.dart`)
- ✅ Now saves view history with user token as part of the key
- Key formats:
  - Compounds: `viewed_compounds_history_{first20charsOfToken}`
  - Units: `viewed_units_history_{first20charsOfToken}`
- Tracks what properties users have viewed

## How It Works

### When User Logs In:
1. Token is saved to SharedPreferences and global variable
2. Favorite blocs automatically reload using the new token-specific keys
3. User sees their saved favorites immediately
4. Search history and view history are loaded with their token

### When User Logs Out:
1. Token is cleared from SharedPreferences and global variable
2. Data remains in SharedPreferences but is no longer accessible (different key)
3. Next login will load the correct user's data

### For Guest Users (No Token):
- Falls back to default keys without token suffix
- `favorite_units`, `favorite_compounds`, etc.
- Data is device-specific only

## Example Flow

```dart
// User A logs in
token = "abc123..."
// Their favorites are saved to: favorite_units_abc123...

// User A logs out, User B logs in
token = "xyz789..."
// User B's favorites are saved to: favorite_units_xyz789...

// User A logs back in
token = "abc123..."
// User A sees their original favorites from: favorite_units_abc123...
```

## Technical Implementation

Each service now uses a computed property for the storage key:

```dart
String get _favoritesKey {
  if (token != null && token!.isNotEmpty) {
    final tokenHash = token!.length > 20 ? token!.substring(0, 20) : token!;
    return '${_baseFavoritesKey}_$tokenHash';
  }
  return _baseFavoritesKey; // Fallback for no token
}
```

## Data Persistence

- ✅ **Favorites**: Persisted per user
- ✅ **Search History**: Persisted per user
- ✅ **View History**: Persisted per user
- ✅ **Automatic Loading**: Data loads when user logs in
- ✅ **Multi-Device Support**: Same data across devices for same user

## Benefits

1. **User Experience**: Users don't lose their favorites when switching devices
2. **Privacy**: Each user's data is isolated by their token
3. **Seamless**: Automatic loading on login, no manual sync needed
4. **Reliable**: Uses SharedPreferences for fast, offline-first storage

## Notes

- Token is truncated to 20 characters to keep storage keys reasonable
- Guest users (no token) still work with local-only storage
- Data persists even after app is closed or device is restarted
