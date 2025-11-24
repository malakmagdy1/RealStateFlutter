# Web Notification Issues - Debug & Fix Guide

## Current Issues

1. **Notifications not appearing in web notifications screen**
2. **Toggle OFF but still receiving notifications**

## Root Causes Identified

### Issue 1: Notifications Not Showing in Screen
**Problem:** Service worker saves to `pending_web_notifications` in localStorage, but the Flutter app might not be reading it properly.

**Check:** Open browser DevTools (F12) → Application tab → Local Storage → https://aqar.bdcbiz.com
- Look for key: `pending_web_notifications`
- Check if it has notifications

### Issue 2: Toggle Not Blocking Notifications
**Problem:** The check in service worker happens BEFORE the preference is saved.

**Timeline:**
1. User toggles OFF in Flutter app
2. Flutter saves to SharedPreferences (takes time)
3. Flutter saves to localStorage via `setLocalStorageItem()`
4. **Meanwhile:** Notification arrives
5. Service worker checks localStorage (might still be old value!)
6. Notification shows

## Solutions

### Solution 1: Make localStorage Save Synchronous

The current implementation saves to SharedPreferences first, THEN to localStorage. This creates a timing issue.

**Fix:** Save to localStorage IMMEDIATELY in the toggle handler.

### Solution 2: Force Service Worker Reload

After changing the notification preference, force reload the service worker so it picks up the new value.

## Testing Steps

### Step 1: Clear Everything
```javascript
// In browser console (F12 → Console):
localStorage.clear()
```

### Step 2: Enable Notifications
1. Go to Profile
2. Turn notifications ON
3. Check console for:
```
[NotificationPreferences] ✅ Web localStorage saved: flutter.notifications_enabled = true
```

### Step 3: Verify Storage
```javascript
// In console:
localStorage.getItem('flutter.notifications_enabled')
// Should return: "true"
```

### Step 4: Disable Notifications
1. Turn toggle OFF
2. Check console for:
```
[NotificationPreferences] ✅ Web localStorage saved: flutter.notifications_enabled = false
```

3. Verify in console:
```javascript
localStorage.getItem('flutter.notifications_enabled')
// Should return: "false"
```

### Step 5: Test Service Worker
```javascript
// In console - check what service worker sees:
localStorage.getItem('flutter.notifications_enabled')
// Must be "false"
```

### Step 6: Send Test Notification
Use Firebase Console to send test notification

**Expected Result:**
- No browser notification popup
- Console shows: `🔕 Notifications are DISABLED by user. Blocking notification.`

### Step 7: Check Web Notifications Screen
1. Go to Notifications screen in app
2. Check console logs:
```
[WEB NOTIFICATIONS SCREEN] initState called
[WEB NOTIFICATIONS] Checking localStorage for pending notifications...
```

## Common Issues & Fixes

### Issue: localStorage shows "true" after turning OFF
**Cause:** Old service worker cached
**Fix:**
1. DevTools → Application → Service Workers
2. Click "Unregister" on firebase-messaging-sw.js
3. Hard refresh (Ctrl+Shift+R)
4. Try again

### Issue: Notifications not in notifications screen
**Cause 1:** Service worker blocked them (good!)
**Cause 2:** Not saving to localStorage properly
**Fix:**
```javascript
// Check what's in localStorage:
localStorage.getItem('pending_web_notifications')
// Should show array of notifications, or null if blocked
```

### Issue: Toggle switches but notifications still come
**Cause:** Service worker reading old cached value
**Fix:** Hard refresh page (Ctrl+Shift+R) to reload service worker

## Advanced Debugging

### Check Service Worker Console
1. DevTools → Application → Service Workers
2. Click "firebase-messaging-sw.js" name (blue link)
3. Opens separate console for service worker
4. Check logs there

### Monitor Service Worker Messages
```javascript
// In main console:
navigator.serviceWorker.addEventListener('message', (event) => {
  console.log('📨 Message from service worker:', event.data);
});
```

### Force Service Worker Update
```javascript
// In console:
navigator.serviceWorker.getRegistrations().then(registrations => {
  registrations.forEach(registration => {
    registration.update();
    console.log('Service worker updated');
  });
});
```

## Expected Console Flow

### When Turning OFF:
```
[NotificationPreferences] 🔄 Setting notifications to: false
[NotificationPreferences] ✅ SharedPreferences saved: notifications_enabled = false
[NotificationPreferences] ✅ Web localStorage saved: flutter.notifications_enabled = false
[NotificationPreferences] 🔍 Verification - localStorage value: false
[NotificationPreferences] ✅ Notifications disabled
🔔 [WEB PROFILE] Toggle notifications called: false
```

### When Notification Arrives (with toggle OFF):
```
[firebase-messaging-sw.js] Received background message
[firebase-messaging-sw.js] Notifications enabled preference: false
🔕 Notifications are DISABLED by user. Blocking notification.
```

### When Notification Arrives (with toggle ON):
```
[firebase-messaging-sw.js] Received background message
[firebase-messaging-sw.js] Notifications enabled preference: true
✅ Notifications are enabled. Processing notification.
✅ Background notification saved to localStorage
```

## Files Involved

1. **lib/services/notification_preferences.dart** - Saves preference
2. **lib/core/utils/web_utils_web.dart** - Sets localStorage
3. **web/firebase-messaging-sw.js** - Reads localStorage and blocks
4. **lib/feature_web/profile/presentation/web_profile_screen.dart** - Toggle UI
5. **lib/feature_web/notifications/presentation/web_notifications_screen.dart** - Shows notifications

## Quick Fix Checklist

- [ ] Clear browser cache and localStorage
- [ ] Unregister service worker
- [ ] Hard refresh page (Ctrl+Shift+R)
- [ ] Turn toggle OFF
- [ ] Verify localStorage is "false"
- [ ] Send test notification
- [ ] Check console for "🔕 Blocking notification"
- [ ] Verify NO notification popup appears
- [ ] Turn toggle ON
- [ ] Verify localStorage is "true"
- [ ] Send test notification
- [ ] Verify notification DOES appear

## If Still Not Working

The service worker might be caching aggressively. Try:

1. **Disable cache in DevTools:**
   - DevTools → Network tab
   - Check "Disable cache"
   - Keep DevTools open

2. **Clear all site data:**
   - DevTools → Application → Storage
   - Click "Clear site data"

3. **Test in Incognito mode:**
   - Opens clean slate without cache

4. **Check Firebase Console:**
   - Ensure your VAPID key is correct
   - Ensure FCM is enabled

## Backend Requirements

The backend should also check if the FCM token is active:

```php
// When sending notification
$activeTokens = FCMToken::where('is_active', true)->pluck('token');
// Only send to active tokens
```

This prevents notifications from backend side even if service worker fails.
