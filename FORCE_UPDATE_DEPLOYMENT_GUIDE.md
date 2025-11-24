# Force Update/Logout Feature - Deployment Guide

## 🎯 Overview
This feature forces all logged-in users to logout and re-login when a new version is deployed. This ensures all users get the latest updates, bug fixes, and features.

---

## 📋 How It Works

### Flow Diagram:
```
User Opens App (Splash Screen)
    ↓
Check if user is logged in
    ↓
YES → Check version
    ↓
Version matches?
    ↓
NO → Navigate to home + Show Force Logout Dialog
    ↓
User clicks "Logout and Update"
    ↓
Logout → Clear all data → Go to Login Screen
    ↓
User logs in again
    ↓
Save current version → User gets latest updates!
```

---

## 🚀 How to Deploy Updates

### **IMPORTANT**: Every time you deploy new changes to production:

1. **Open** `lib/core/services/version_service.dart`

2. **Change** the version number:
```dart
// ⚠️ INCREMENT THIS VERSION WHEN YOU DEPLOY NEW UPDATES ⚠️
static const String currentVersion = '1.0.5'; // ← Change this!
```

**Examples**:
- Before: `'1.0.5'`
- After: `'1.0.6'` (or `'1.1.0'`, `'2.0.0'`, etc.)

3. **Build and deploy** your app as usual

4. **Result**: All currently logged-in users will see the force logout dialog on next app open!

---

## 📁 Files Created/Modified

### New Files:
1. **`lib/core/services/version_service.dart`**
   - Tracks app version
   - Checks if update is needed
   - Manages version storage

2. **`lib/core/widgets/force_logout_dialog.dart`**
   - Beautiful dialog UI
   - Cannot be dismissed
   - Forces user to logout
   - Supports Arabic & English

### Modified Files:
1. **`lib/splash_screen.dart`**
   - Added version check on app start
   - Shows force logout dialog if version mismatch

2. **`lib/feature/auth/presentation/bloc/login_bloc.dart`**
   - Saves version on successful login
   - Clears version on logout

3. **`lib/l10n/app_en.arb`** & **`lib/l10n/app_ar.arb`**
   - Added translations for dialog

---

## 🎨 Dialog UI

### English Version:
```
┌──────────────────────────────────────┐
│   [Icon: System Update]              │
│                                      │
│   Update Available                   │
│                                      │
│   A new version of the app is        │
│   available with important           │
│   improvements and bug fixes.        │
│   Please logout and login again      │
│   to get the latest updates.         │
│                                      │
│   ℹ️ Your session will be refreshed  │
│      to apply the new changes.       │
│      You will need to login again.   │
│                                      │
│   [Logout and Update Button]         │
└──────────────────────────────────────┘
```

### Arabic Version:
```
┌──────────────────────────────────────┐
│   [أيقونة: تحديث النظام]             │
│                                      │
│   تحديث متاح                         │
│                                      │
│   يتوفر إصدار جديد من التطبيق       │
│   يحتوي على تحسينات مهمة وإصلاحات.  │
│   الرجاء تسجيل الخروج ثم تسجيل      │
│   الدخول مرة أخرى للحصول على آخر   │
│   التحديثات.                         │
│                                      │
│   ℹ️ سيتم تحديث جلستك لتطبيق        │
│      التغييرات الجديدة. ستحتاج       │
│      إلى تسجيل الدخول مرة أخرى.      │
│                                      │
│   [زر تسجيل الخروج والتحديث]        │
└──────────────────────────────────────┘
```

---

## 🔍 Version Tracking Logic

### Storage:
- Uses `SharedPreferences`
- Key: `'app_version'`
- Stored value: `'1.0.5'` (example)

### Check Points:

#### 1. **On App Start** (Splash Screen):
```dart
if (userIsLoggedIn) {
  final shouldForceLogout = await VersionService.shouldForceLogout();
  if (shouldForceLogout) {
    // Show force logout dialog
  }
}
```

#### 2. **On Login** (Login Success):
```dart
await VersionService.updateVersion(); // Save current version
```

#### 3. **On Logout** (Logout Success):
```dart
await VersionService.clearVersion(); // Clear version
```

---

## 🧪 Testing Guide

### Test Scenario 1: First Time User
1. Fresh install app
2. Login
3. **Expected**: No force logout (first time)
4. **Result**: Version `1.0.5` saved

### Test Scenario 2: Version Update
1. User already logged in (version `1.0.5`)
2. You deploy new version `1.0.6`
3. User opens app
4. **Expected**: Force logout dialog appears
5. User clicks "Logout and Update"
6. **Expected**: Logged out, redirected to login
7. User logs in again
8. **Result**: Version `1.0.6` saved

### Test Scenario 3: No Update Needed
1. User logged in (version `1.0.6`)
2. User opens app (version still `1.0.6`)
3. **Expected**: No force logout dialog
4. **Expected**: Normal app flow

### Test Scenario 4: Logout Manually
1. User manually logs out
2. **Expected**: Version cleared
3. User logs in again
4. **Expected**: Current version saved

---

## 📱 Platform Support

| Platform | Supported | Notes |
|----------|-----------|-------|
| Android | ✅ | Full support |
| iOS | ✅ | Full support |
| Web | ✅ | Full support |

---

## 🎯 Use Cases

### When to Deploy with Force Update:

✅ **DO** increment version for:
- Bug fixes that affect all users
- Security updates
- Breaking API changes
- Database schema changes
- Critical feature updates
- UI/UX improvements that need full refresh

❌ **DON'T** increment for:
- Minor text changes
- Small UI tweaks that don't affect functionality
- Backend-only changes
- Analytics updates
- Comment updates in code

---

## 🔐 Security Features

1. **Cannot Dismiss Dialog**:
   - `barrierDismissible: false`
   - `PopScope.canPop: false`
   - Back button disabled

2. **Data Cleanup on Logout**:
   - All secure storage cleared
   - All cache cleared
   - FCM token removed
   - Route persistence cleared
   - Version tracking cleared

3. **Automatic on First Screen**:
   - Checked immediately on splash screen
   - Before user can interact with app

---

## 🛠️ Customization

### Change Dialog Design:
Edit `lib/core/widgets/force_logout_dialog.dart`

### Change Version Format:
Edit `lib/core/services/version_service.dart`
```dart
// Examples:
static const String currentVersion = '1.0.5';     // Semantic
static const String currentVersion = '2024-11-23'; // Date
static const String currentVersion = 'build-123';  // Build number
```

### Change Translations:
Edit `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`

---

## 🐛 Troubleshooting

### Issue: Dialog not showing after version change
**Solution**:
- Check version number was actually changed
- Verify user is logged in
- Check console logs for `[VERSION]` messages

### Issue: Users keep seeing dialog on every launch
**Solution**:
- Ensure `VersionService.updateVersion()` is called after successful login
- Check SharedPreferences permissions

### Issue: Version not being saved
**Solution**:
- Check SharedPreferences access
- Verify no errors in login flow
- Check console logs

---

## 📊 Monitoring

### Console Logs to Watch:

```
[VERSION] Current version: 1.0.6
[VERSION] Saved version: 1.0.5
[VERSION] ⚠️ Version mismatch - forcing logout
```

```
[SPLASH] 🔄 Version update detected - showing force logout dialog
```

```
[VERSION] ✓ Version updated to: 1.0.6
```

```
[VERSION] Version cleared
```

---

## 🚦 Deployment Checklist

Before deploying to production:

- [ ] Update version in `version_service.dart`
- [ ] Test force logout dialog (increment to test version)
- [ ] Verify translations (English & Arabic)
- [ ] Test on all platforms (Android, iOS, Web)
- [ ] Document version change in release notes
- [ ] Inform team about force logout
- [ ] Monitor error logs after deployment

---

## 📝 Version History Format

Recommended format for tracking:

```
1.0.5 (2025-11-23)
- Added AI comparison improvements
- Fixed language detection
- Added force update feature

1.0.6 (2025-11-24)
- Fixed payment calculation bug
- Updated UI theme
- Performance improvements
```

---

## 💡 Pro Tips

1. **Increment gradually**: Use semantic versioning (1.0.5 → 1.0.6)

2. **Plan updates**: Group multiple changes into one version update

3. **Communicate**: Warn users about maintenance windows

4. **Test first**: Always test on staging before production

5. **Monitor closely**: Watch for logout issues after deployment

6. **Have rollback plan**: Keep previous version ready

---

## 🔗 Related Files

- Version Service: `lib/core/services/version_service.dart`
- Force Logout Dialog: `lib/core/widgets/force_logout_dialog.dart`
- Splash Screen: `lib/splash_screen.dart`
- Login Bloc: `lib/feature/auth/presentation/bloc/login_bloc.dart`
- English Translations: `lib/l10n/app_en.arb`
- Arabic Translations: `lib/l10n/app_ar.arb`

---

## ✅ Current Status

**Feature Status**: ✅ Complete and Ready for Production

**Current Version**: `1.0.5`

**Last Updated**: 2025-11-23

**Tested On**:
- ✅ Android
- ✅ iOS
- ✅ Web

---

## 📞 Support

If you have issues:
1. Check console logs for `[VERSION]` messages
2. Verify version number was changed
3. Test logout/login flow manually
4. Review this documentation

---

*This feature ensures all users stay up-to-date with the latest app improvements!* 🚀
