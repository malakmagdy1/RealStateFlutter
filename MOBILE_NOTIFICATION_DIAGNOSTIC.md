# Mobile Push Notification Diagnostic Guide

## Issue: Notifications work on Web but NOT on Mobile (Android/iOS)

---

## ✅ Configuration Status

### Firebase Configuration
- ✅ Firebase initialized in `main.dart`
- ✅ `google-services.json` exists for Android
- ✅ Background message handler registered
- ✅ FCM service properly implemented
- ✅ Android manifest has notification permissions
- ⚠️ **iOS Info.plist MISSING notification keys**

---

## 🔍 Root Cause Analysis

### Most Likely Issues:

### **1. iOS Configuration Incomplete** ⚠️ HIGH PRIORITY
**Problem:** `ios/Runner/Info.plist` is missing critical notification keys

**Required Additions:**
```xml
<!-- Add these to ios/Runner/Info.plist before </dict> -->

<!-- Enable Firebase Cloud Messaging -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>

<!-- Enable background modes for notifications -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>fetch</string>
</array>
```

**iOS also needs:**
1. APNs (Apple Push Notification service) certificate in Firebase Console
2. Push notification capability enabled in Xcode

---

### **2. Runtime Permission Not Requested (Android 13+)** ⚠️ HIGH PRIORITY
**Problem:** While `POST_NOTIFICATIONS` is in AndroidManifest, runtime permission may not be requested

**Check in Code:**
The FCM service requests permissions in `fcm_service.dart:76-88`:
```dart
NotificationSettings settings = await _firebaseMessaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
  provisional: false,
);
```

**Verify:**
1. Run the app on physical Android device (Android 13+)
2. Check if notification permission dialog appears
3. Check app settings → permissions → notifications is enabled

**Test on device:**
```bash
# Check notification permission status
adb shell dumpsys package com.realestate.aqar | grep -A 3 "runtime permissions"
```

---

### **3. FCM Token Not Generated on Mobile** ⚠️ MEDIUM PRIORITY
**Problem:** Token might not be generating or not being sent to backend

**Debug Steps:**

#### A. Check if token is generated:
Run your app on a physical device and check logs for:
```
✅ FCM TOKEN GENERATED
Token: [long token string]
```

If you see `❌ User denied notification permission`, permissions were denied.

#### B. Check if token is sent to backend:
Look for:
```
✅ FCM TOKEN SAVED TO BACKEND SUCCESSFULLY!
```

If you see `❌ Failed to send FCM token: [status code]`, backend integration failed.

#### C. Manual token check:
Add this to your app (temporarily) and run on mobile:
```dart
// In HomeScreen or any screen after login
@override
void initState() {
  super.initState();
  _checkFCMToken();
}

Future<void> _checkFCMToken() async {
  final fcmService = FCMService();
  final token = fcmService.fcmToken;
  print('═══════════════════════════════════════');
  print('Current FCM Token: $token');
  print('═══════════════════════════════════════');

  // Show dialog to see token on screen
  if (token != null) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('FCM Token'),
        content: SelectableText(token),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

---

### **4. Firebase Project Configuration** ⚠️ MEDIUM PRIORITY
**Problem:** Firebase project might not have correct Android/iOS app configuration

**Check Firebase Console:**
1. Go to https://console.firebase.google.com
2. Select project: `realstate-4564d`
3. Go to Project Settings → Your apps
4. Verify you have BOTH:
   - Android app: `com.realestate.aqar` ✅ (Found in google-services.json)
   - iOS app: `com.realestate.aqar` ❓ (Need to verify)

**For iOS:**
1. Check if iOS app is registered in Firebase
2. Verify APNs authentication key is uploaded
3. Download and verify `GoogleService-Info.plist` is in `ios/Runner/`

---

### **5. Message Payload Format** ⚠️ LOW PRIORITY
**Problem:** Backend might be sending wrong format for mobile vs web

**Mobile requires both `notification` and `data` payloads:**

**Correct format for mobile:**
```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "New Unit Available",
    "body": "Check out the latest listings!",
    "sound": "default"
  },
  "data": {
    "type": "new_unit",
    "unit_id": "123",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  },
  "priority": "high",
  "content_available": true
}
```

**For iOS specifically, add:**
```json
{
  "apns": {
    "payload": {
      "aps": {
        "alert": {
          "title": "New Unit Available",
          "body": "Check out the latest listings!"
        },
        "sound": "default",
        "badge": 1,
        "content-available": 1
      }
    }
  }
}
```

---

## 📋 Step-by-Step Testing Checklist

### Phase 1: Verify Configuration

- [ ] **Android**
  - [ ] `google-services.json` exists in `android/app/`
  - [ ] Package name matches: `com.realestate.aqar`
  - [ ] `POST_NOTIFICATIONS` permission in AndroidManifest
  - [ ] Google Services plugin applied in `build.gradle.kts`

- [ ] **iOS**
  - [ ] `GoogleService-Info.plist` exists in `ios/Runner/`
  - [ ] Bundle ID matches: `com.realestate.aqar`
  - [ ] Add `UIBackgroundModes` to Info.plist ⚠️ **MISSING**
  - [ ] Add `FirebaseAppDelegateProxyEnabled` to Info.plist ⚠️ **MISSING**
  - [ ] Push notification capability enabled in Xcode
  - [ ] APNs key uploaded to Firebase Console

### Phase 2: Test on Physical Device

**IMPORTANT:** Push notifications don't work reliably on emulators/simulators!

- [ ] **Android Physical Device (Android 13+)**
  1. [ ] Install app on physical device
  2. [ ] Grant notification permission when prompted
  3. [ ] Log in to app
  4. [ ] Check logs for "FCM TOKEN GENERATED"
  5. [ ] Check logs for "FCM TOKEN SAVED TO BACKEND"
  6. [ ] Send test notification from Firebase Console
  7. [ ] Verify notification received in 3 states:
     - [ ] App in foreground
     - [ ] App in background
     - [ ] App killed/closed

- [ ] **iOS Physical Device**
  1. [ ] Fix Info.plist (add missing keys)
  2. [ ] Build with Xcode and deploy to physical device
  3. [ ] Grant notification permission when prompted
  4. [ ] Log in to app
  5. [ ] Check logs for "FCM TOKEN GENERATED"
  6. [ ] Send test notification from Firebase Console
  7. [ ] Verify notification received in 3 states:
     - [ ] App in foreground
     - [ ] App in background
     - [ ] App killed/closed

### Phase 3: Backend Verification

- [ ] **Check Laravel Backend**
  1. [ ] Verify FCM token is stored in database
     ```sql
     SELECT id, name, fcm_token FROM users WHERE fcm_token IS NOT NULL;
     ```
  2. [ ] Check if backend is using correct FCM token for mobile vs web
  3. [ ] Verify notification payload format (see section 5 above)
  4. [ ] Test sending notification from backend
  5. [ ] Check Laravel logs for FCM errors

---

## 🧪 Quick Test Commands

### Test Notification from Firebase Console:
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter title and body
4. Click "Send test message"
5. Paste your FCM token (from app logs)
6. Click "Test"

### Test from Command Line (using FCM token):
```bash
# Get your Server Key from Firebase Console → Project Settings → Cloud Messaging

curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "Testing mobile push notifications",
      "sound": "default"
    },
    "data": {
      "type": "test",
      "test_id": "123"
    },
    "priority": "high"
  }'
```

---

## 🔧 Common Fixes

### Fix 1: iOS Info.plist Update
```xml
<!-- Add to ios/Runner/Info.plist before </dict> -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>fetch</string>
</array>
```

### Fix 2: Request Runtime Permission Early
In `main.dart` or `HomeScreen`, ensure permission is requested:
```dart
// After login, explicitly request permission
final fcmService = FCMService();
await fcmService.initialize();
```

### Fix 3: Enable Xcode Push Capability
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Click "+ Capability"
4. Add "Push Notifications"
5. Add "Background Modes" → Check "Remote notifications"

### Fix 4: Upload APNs Key to Firebase
1. Go to https://developer.apple.com/account/resources/authkeys/list
2. Create new key with "Apple Push Notifications service (APNs)"
3. Download .p8 file
4. Go to Firebase Console → Project Settings → Cloud Messaging
5. Upload APNs Authentication Key

---

## 📊 Debug Logs to Look For

### ✅ Success Indicators:
```
✅ Firebase initialized
✅ Background message handler registered
✅ User granted notification permission
✅ FCM TOKEN GENERATED
✅ FCM TOKEN SAVED TO BACKEND SUCCESSFULLY!
✅ FCM Service initialized successfully
```

### ❌ Error Indicators:
```
❌ User denied notification permission
❌ Failed to send FCM token: [status code]
❌ Error sending FCM token to backend: [error]
❌ No auth token found. User not logged in.
```

### 📬 Notification Received:
```
📬 Background Message: [title]
📨 FOREGROUND MESSAGE RECEIVED
💾 Notification saved to cache
```

---

## 🎯 Most Likely Solution

Based on the code analysis, the **most likely issues** are:

1. **iOS missing Info.plist keys** (100% certain issue)
2. **iOS missing APNs setup** (very likely if not configured)
3. **Android 13+ runtime permission denied** (possible)
4. **Testing on emulator instead of physical device** (common mistake)

---

## 📞 Next Steps

1. **Fix iOS Info.plist** (add missing keys)
2. **Test on PHYSICAL devices** (not emulators)
3. **Check logs** for FCM token generation
4. **Verify backend** is receiving and storing tokens
5. **Send test notification** from Firebase Console

If notifications still don't work after these fixes, check:
- Firebase Console app configuration
- APNs certificate/key for iOS
- Backend notification payload format
- Network connectivity on mobile device

---

## 📚 Reference Files

- FCM Service: `lib/services/fcm_service.dart`
- Main initialization: `lib/main.dart:86-94`
- Android Manifest: `android/app/src/main/AndroidManifest.xml`
- iOS Info.plist: `ios/Runner/Info.plist` ⚠️ **NEEDS UPDATE**
- Google Services (Android): `android/app/google-services.json`
- Notification Model: `lib/feature/notifications/data/models/notification_model.dart`

---

**Created:** 2025-11-23
**Status:** Diagnostic Guide - Action Required
