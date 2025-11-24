# Web Notification Toggle Fix - Complete Guide

## What Was Wrong

The notification toggle wasn't working on web because:

1. **SharedPreferences on web** stores data in localStorage with a complex key format
2. **Service Worker** (firebase-messaging-sw.js) was checking `localStorage.getItem('flutter.notifications_enabled')`
3. **Mismatch**: SharedPreferences didn't save to that exact key name

## What Was Fixed

### 1. Updated `lib/services/notification_preferences.dart`
- Now saves to BOTH SharedPreferences AND localStorage directly
- On web, it saves to `flutter.notifications_enabled` key that service worker can read
- Added comprehensive logging to track the save/load process

### 2. Updated `lib/core/utils/web_utils_web.dart` and `web_utils_stub.dart`
- Added `setLocalStorageItem()` function to write directly to localStorage
- This ensures the service worker can read the value

## How to Test

### Step 1: Clear Cache and Rebuild
```bash
# Clean and rebuild the web app
flutter clean
flutter pub get
flutter build web --release
```

### Step 2: Deploy to Server
```bash
# Create archive
cd build
tar -czf web_build_notification_fix.tar.gz web

# Upload to server
scp web_build_notification_fix.tar.gz root@31.97.46.103:/tmp/

# Extract on server
ssh root@31.97.46.103
cd /var/www/aqar.bdcbiz.com
rm -rf *
tar -xzf /tmp/web_build_notification_fix.tar.gz --strip-components=1
```

### Step 3: Test in Browser

1. **Open website** (https://aqar.bdcbiz.com)
2. **Open DevTools** (Press F12)
3. **Go to Console tab**
4. **Clear console** (click trash icon)

5. **Navigate to Profile** → Toggle notifications OFF

6. **Check Console Output** - You should see:
```
[NotificationPreferences] 🔄 Setting notifications to: false
[NotificationPreferences] ✅ SharedPreferences saved: notifications_enabled = false
[NotificationPreferences] ✅ Web localStorage saved: flutter.notifications_enabled = false
[NotificationPreferences] 🔍 Verification - localStorage value: false
[NotificationPreferences] ✅ Notifications disabled
🔔 [WEB PROFILE] Toggle notifications called: false
```

7. **Verify localStorage** - In DevTools Console, type:
```javascript
localStorage.getItem('flutter.notifications_enabled')
```
Should return: `"false"`

8. **Check Application tab** → Storage → Local Storage → https://aqar.bdcbiz.com
Look for key `flutter.notifications_enabled` with value `"false"`

### Step 4: Test Notification Blocking

1. **With toggle OFF**, send a test notification from backend
2. **Open Console** and check for service worker logs:
```
[firebase-messaging-sw.js] Notifications enabled preference: false
🔕 Notifications are DISABLED by user. Blocking notification.
```

3. **No notification should appear** (no browser popup)

4. **Toggle ON** and send another notification
5. **Notification SHOULD appear** now

## Verification Checklist

- [ ] Console shows "✅ Web localStorage saved" when toggling
- [ ] `localStorage.getItem('flutter.notifications_enabled')` returns correct value
- [ ] Service worker logs "🔕 Notifications are DISABLED" when toggle is OFF
- [ ] No notifications appear when toggle is OFF
- [ ] Notifications appear when toggle is ON
- [ ] Preference persists after page refresh

## Troubleshooting

### Issue: Still receiving notifications when OFF
**Solution:** Hard refresh the page (Ctrl+Shift+R) to reload the service worker

### Issue: localStorage shows null
**Solution:**
1. Clear browser cache completely
2. Rebuild and redeploy the web app
3. Make sure you're testing on the deployed site, not localhost

### Issue: No console logs appearing
**Solution:**
1. Make sure you're in the Console tab of DevTools
2. Check that console filter is set to "All levels"
3. Try clicking the toggle multiple times

### Issue: Service worker not checking preference
**Solution:**
1. Unregister old service worker:
   - DevTools → Application tab → Service Workers
   - Click "Unregister" next to firebase-messaging-sw.js
   - Hard refresh page (Ctrl+Shift+R)

## Technical Details

### SharedPreferences vs localStorage on Web

- **SharedPreferences**: Flutter's cross-platform storage API
  - On web, internally uses localStorage
  - Uses prefixed keys (e.g., `flutter.preferences.KEY`)

- **localStorage**: Browser's native storage API
  - Accessible from JavaScript (service worker)
  - Simple key-value storage

### Why Dual Storage?

We save to BOTH because:
1. **SharedPreferences**: For Flutter app to read/write (Dart code)
2. **localStorage**: For service worker to check (JavaScript code)

### Service Worker Context

The service worker runs in a separate context from the Flutter app:
- Cannot access Dart code
- Cannot read SharedPreferences directly
- CAN access localStorage directly
- This is why we need to save to localStorage explicitly

## Code References

- Notification preferences: `lib/services/notification_preferences.dart:26-56`
- Web localStorage utils: `lib/core/utils/web_utils_web.dart:12-14`
- Service worker check: `web/firebase-messaging-sw.js:22-41`
- Web profile toggle: `lib/feature_web/profile/presentation/web_profile_screen.dart:74-110`

## Expected Behavior After Fix

✅ **Toggle OFF:**
- Preference saved to both SharedPreferences and localStorage
- Service worker reads `false` from localStorage
- Background notifications blocked (no popup)
- Notifications still saved to cache (can view in app later)

✅ **Toggle ON:**
- Preference saved as `true`
- Service worker allows notifications
- Background notifications show popup
- Notifications saved to cache AND displayed

✅ **Page Refresh:**
- Preference persists (loaded from SharedPreferences)
- Toggle shows correct state
- Service worker continues to respect preference
