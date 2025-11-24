# Google Play Release Guide - Fix Google Sign-In Issue

## Problem Summary
Google Sign-In works in development but fails in Google Play with error: `PlatformException(sign_in_failed, Q0.d:10:, null, null)`

**Root Cause**: Missing SHA-1 certificate fingerprint for your release/production keystore in Firebase Console.

---

## Solution: 3-Step Process

### Step 1: Place Your Keystore File

1. Copy your existing `upload-keystore.jks` file
2. Place it in: `C:\Users\B-Smart\AndroidStudioProjects\real\android\upload-keystore.jks`
3. Verify the file is in the correct location

### Step 2: Get SHA-1 Fingerprint from Your Keystore

Run this command in your project root:

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload -storepass real2024app -keypass real2024app
```

**Look for these lines in the output:**
```
Certificate fingerprints:
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA256: ...
```

**Copy the SHA-1 value** (it's a 40-character hex string with colons)

### Step 3: Add SHA-1 to Firebase Console

1. Go to: https://console.firebase.google.com
2. Select project: **realstate-4564d**
3. Click the **gear icon** ⚙️ (Settings) → **Project settings**
4. Scroll to **Your apps** section
5. Find your Android app: **com.realestate.aqar**
6. Under "SHA certificate fingerprints", click **Add fingerprint**
7. Paste the SHA-1 from Step 2
8. Click **Save**

### Step 4: Download Updated google-services.json

1. In the same Firebase page, scroll down
2. Click **Download google-services.json**
3. Replace the file at: `android/app/google-services.json`
4. Commit this change to git

---

## Building Release APK/AAB

### Option 1: Build AAB (Recommended for Google Play)

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Output location: `build/app/outputs/bundle/release/app-release.aab`

### Option 2: Build APK (For testing before upload)

```bash
flutter clean
flutter pub get
flutter build apk --release
```

Output location: `build/app/outputs/flutter-apk/app-release.apk`

---

## Uploading to Google Play Console

### Method 1: Via Google Play Console Website

1. Go to: https://play.google.com/console
2. Select your app
3. Go to **Production** → **Create new release** (or Internal testing/Closed testing)
4. Upload the `app-release.aab` file
5. Fill in release notes
6. Review and roll out

### Method 2: Via Command Line (if you have fastlane setup)

```bash
# Not configured yet - use Method 1
```

---

## Testing Before Upload

### Test Release Build Locally

1. Build release APK:
   ```bash
   flutter build apk --release
   ```

2. Install on device:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

3. Test Google Sign-In to verify it works with release certificate

---

## Additional: Get SHA-1 from Google Play Console

If you're using Google Play App Signing, you also need the SHA-1 from Google Play:

1. Go to: https://play.google.com/console
2. Select your app
3. Go to **Setup** → **App signing**
4. You'll see TWO certificates:
   - **App signing key certificate** (used by Google Play)
   - **Upload key certificate** (your upload-keystore.jks)
5. Copy BOTH SHA-1 fingerprints
6. Add BOTH to Firebase (repeat Step 3 above for each)

---

## Verification Checklist

Before uploading to Google Play:

- [ ] `upload-keystore.jks` is in `android/` folder
- [ ] SHA-1 added to Firebase Console
- [ ] Downloaded updated `google-services.json`
- [ ] Replaced `android/app/google-services.json`
- [ ] Built release AAB/APK successfully
- [ ] Tested release build locally (optional but recommended)
- [ ] Version code incremented in `pubspec.yaml` (current: 1.0.0+13)

---

## Current Configuration

**Package Name**: `com.realestate.aqar`
**Firebase Project**: `realstate-4564d`
**Keystore Location**: `android/upload-keystore.jks`
**Keystore Alias**: `upload`
**Current Version**: `1.0.0+13`

**Existing SHA-1 Certificates in Firebase** (from google-services.json):
1. `eefe4cc4ba7ede1d551a208ffe5af99b5b50e80c`
2. `957e147f42393800f4da2fc45ba99a055a9b05a9`
3. `0887540c1c5c37295c1f58ffaa26a91950d6d837`

You need to add your release keystore SHA-1 to this list.

---

## Troubleshooting

### If SHA-1 extraction fails:
- Verify keystore file location
- Check password is correct: `real2024app`
- Check alias is correct: `upload`

### If Firebase doesn't update:
- Wait 5-10 minutes for changes to propagate
- Clear app data and reinstall

### If Google Sign-In still fails:
- Verify you downloaded and replaced `google-services.json`
- Check that the new SHA-1 appears in the updated `google-services.json` file
- Make sure you're testing the release build, not debug

---

## Quick Commands

```bash
# Get SHA-1 from keystore
keytool -list -v -keystore android/upload-keystore.jks -alias upload -storepass real2024app

# Clean and build release
flutter clean && flutter pub get && flutter build appbundle --release

# Install release APK for testing
flutter build apk --release && adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Next Steps

1. **First**: Place your `upload-keystore.jks` in the `android/` folder
2. **Then**: Run the keytool command to get SHA-1
3. **Then**: Add SHA-1 to Firebase
4. **Then**: Download and replace google-services.json
5. **Finally**: Build and upload to Google Play

Good luck with your release!
