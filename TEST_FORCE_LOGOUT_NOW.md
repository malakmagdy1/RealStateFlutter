# 🧪 Test Force Logout - RIGHT NOW

## Quick Test Steps:

### Step 1: Change Version (DO THIS NOW)
Open: `lib/core/services/version_service.dart`

Change line 15 to:
```dart
static const String currentVersion = '1.0.6'; // Changed from 1.0.5
```

### Step 2: Rebuild Web
```bash
flutter build web --release
```

### Step 3: Check Browser Console
Open browser console (F12) and look for these messages:

**If first time visiting (no saved version):**
```
[VERSION] Current version: 1.0.6
[VERSION] Saved version: null
[VERSION] First launch - saved version
[WEB MAIN] ✅ Version check passed - no logout needed
```

**If already logged in (has old version 1.0.5):**
```
[VERSION] Current version: 1.0.6
[VERSION] Saved version: 1.0.5
[VERSION] ⚠️ Version mismatch - forcing logout
[WEB MAIN] ⚠️ Version mismatch detected - showing force logout dialog
```

### Step 4: Simulate Already Logged In User

1. **Open Developer Tools** (F12)
2. **Go to Application tab** → Storage → Local Storage
3. **Add this manually**:
   - Key: `flutter.app_version`
   - Value: `1.0.5`

4. **Refresh page**
5. **BOOM!** Force logout dialog should appear! 🎉

---

## Alternative Test (Easier):

### Test on Live Site:

1. Go to: `https://aqarapp.co/login`
2. Login normally
3. Open Developer Tools (F12)
4. Console → Type:
```javascript
localStorage.setItem('flutter.app_version', '1.0.5');
```
5. Refresh page
6. Dialog should appear!

---

## What You Should See:

```
┌────────────────────────────────────┐
│                                    │
│    [Update Icon]                   │
│                                    │
│    Update Available                │
│                                    │
│    A new version of the app is     │
│    available with important...     │
│                                    │
│    ℹ️  Your session will be        │
│       refreshed...                 │
│                                    │
│  [Logout and Update Button]        │
│                                    │
└────────────────────────────────────┘
```

---

## Current Status:

✅ Version check added to **Web Main Screen**
✅ Version check added to **Mobile Main Screen**
✅ Version check added to **Splash Screen**
✅ Force logout dialog created
✅ Translations added (Arabic & English)

**Now deployed version**: Should force ALL logged-in users to logout when they open the app!

---

## Console Logs to Watch:

```
[VERSION] Current version: 1.0.6
[VERSION] Saved version: 1.0.5
[VERSION] ⚠️ Version mismatch - forcing logout
[WEB MAIN] 🔍 Checking version for force logout...
[WEB MAIN] ⚠️ Version mismatch detected - showing force logout dialog
```

---

## ⚠️ IMPORTANT:

After testing, if everything works:
1. Keep version at `1.0.6`
2. Build and deploy to server
3. All real users will be forced to logout!

OR

If you want to wait:
1. Change version back to `1.0.5`
2. Rebuild
3. No one will be forced to logout yet
4. When ready to deploy for real, change to `1.0.6`

---

*Test it now to see it in action!* 🚀
