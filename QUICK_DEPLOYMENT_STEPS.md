# Quick Deployment Steps - Force User Update

## 🚀 Every Time You Deploy to Production:

### Step 1: Update Version Number
Open: `lib/core/services/version_service.dart`

Change line 15:
```dart
static const String currentVersion = '1.0.6'; // ← INCREMENT THIS!
```

**Examples**:
- `'1.0.5'` → `'1.0.6'` (minor update)
- `'1.0.9'` → `'1.1.0'` (feature update)
- `'1.9.9'` → `'2.0.0'` (major update)

### Step 2: Build & Deploy
```bash
# For Web
flutter build web --release

# For Android
flutter build apk --release

# For iOS
flutter build ios --release
```

### Step 3: Upload to Server/Store
- Deploy as usual to your server (web)
- Upload to Google Play / App Store (mobile)

### Step 4: Result 🎉
✅ All currently logged-in users will be forced to logout and re-login on next app open!
✅ Users will see a beautiful dialog explaining the update
✅ Users cannot dismiss it - they must logout
✅ Users login again and get all latest updates!

---

## 💡 What Happens to Users:

1. **User opens app** (already logged in from before)
2. **Dialog appears**: "Update Available"
3. **User clicks**: "Logout and Update"
4. **App logs out** user automatically
5. **User sees** login screen
6. **User logs in** again
7. **Done!** User now has latest version

---

## 🎯 SSH Commands for Web Deployment:

```bash
# Connect to server
ssh root@31.97.46.103

# Go to web directory
cd /var/www/aqar.bdcbiz.com

# Backup old version (optional)
cp -r build build_backup_$(date +%Y%m%d)

# Clear old build
rm -rf build

# Upload new build (from your machine)
# On your machine:
cd C:\Users\B-Smart\AndroidStudioProjects\real
tar -czf web_build.tar.gz -C build\web .
scp web_build.tar.gz root@31.97.46.103:/var/www/aqar.bdcbiz.com/

# On server:
tar -xzf web_build.tar.gz -C build
rm web_build.tar.gz

# Restart web server (if needed)
systemctl reload nginx
```

---

## ⚠️ IMPORTANT Notes:

1. **Always increment version** when deploying changes
2. **Test locally first** before deploying to production
3. **Warn users** if possible (social media, email, etc.)
4. **Monitor logs** after deployment
5. **Have rollback plan** ready

---

## 📋 Quick Checklist:

Before deploying:
- [ ] Changed version in `version_service.dart`
- [ ] Tested locally
- [ ] Built release version
- [ ] Uploaded to server/store
- [ ] Monitoring console logs
- [ ] Ready for user questions

After deploying:
- [ ] Verify users can logout/login
- [ ] Check no errors in console
- [ ] Test on different devices
- [ ] Monitor user feedback

---

## 🆘 Emergency Rollback:

If something goes wrong:

```bash
# Web Rollback
ssh root@31.97.46.103
cd /var/www/aqar.bdcbiz.com
rm -rf build
mv build_backup_YYYYMMDD build
systemctl reload nginx
```

Then:
1. Change version back to previous number
2. Rebuild and redeploy
3. Investigate issue

---

## 📱 Current Setup:

**Server**: `root@31.97.46.103`
**Web Path**: `/var/www/aqar.bdcbiz.com`
**Web URL**: `https://aqar.bdcbiz.com`
**Login URL**: `https://aqarapp.co/login`

**Current Version**: `1.0.5`
**Password**: `Iibrah@25722`

---

*Deploy with confidence!* 🚀
