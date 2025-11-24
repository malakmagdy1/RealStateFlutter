# Google Sign-In Not Working on Play Store - FIX GUIDE

## Problem
Google Sign-In works in Android Studio (local device) but **fails after uploading to Play Store**.

## Root Cause
Play Store re-signs your app with a **different certificate**. Your Firebase/Google Cloud project doesn't have this certificate's SHA-1 fingerprint registered.

---

## SOLUTION - Step by Step

### Step 1: Get Play Store SHA-1 Certificate

1. **Go to Google Play Console:**
   - Visit: https://play.google.com/console
   - Select your app (`com.realestate.aqar`)

2. **Navigate to App Signing:**
   - Click: **Release** → **Setup** → **App Signing**

3. **Copy SHA-1 Certificate:**
   - Under **"App signing key certificate"** section
   - Find the line that says **SHA-1 certificate fingerprint**
   - Copy this value (format: `XX:XX:XX:XX:XX:XX...`)

4. **Also copy SHA-256:**
   - Copy the **SHA-256 certificate fingerprint** as well (just in case)

---

### Step 2: Add SHA-1 to Firebase Console

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com
   - Select project: `realstate-4564d`

2. **Open Project Settings:**
   - Click the ⚙️ (gear icon) → **Project settings**

3. **Find Your Android App:**
   - Scroll down to **"Your apps"** section
   - Find: `com.realestate.aqar` (Android)

4. **Add SHA-1 Fingerprint:**
   - Click **"Add fingerprint"** button
   - Paste the SHA-1 from Play Console
   - Click **Save**

5. **Add SHA-256 (optional but recommended):**
   - Click **"Add fingerprint"** again
   - Paste the SHA-256 from Play Console
   - Click **Save**

---

### Step 3: Update Google Cloud Console OAuth Credentials

⚠️ **THIS IS CRITICAL - Don't skip this step!**

1. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com
   - Select project: `realstate-4564d`

2. **Navigate to Credentials:**
   - Left menu: **APIs & Services** → **Credentials**

3. **Find Android OAuth Client:**
   - Look for OAuth 2.0 Client IDs
   - Find the one for Android (package: `com.realestate.aqar`)
   - You should see existing entries like:
     - `832433207149-1ub8e95hl9ug20e3n6ch3hgk6queasu1.apps.googleusercontent.com`
     - `832433207149-vn9r1na57p83k6kna24a1h4lq70n2ug5.apps.googleusercontent.com`

4. **Create New OAuth Client (if needed) or Update Existing:**
   - Click **"+ CREATE CREDENTIALS"** → **OAuth client ID**
   - Application type: **Android**
   - Name: `Aqar App - Play Store`
   - Package name: `com.realestate.aqar`
   - SHA-1 certificate fingerprint: **[Paste from Play Console]**
   - Click **Create**

---

### Step 4: Download New google-services.json

1. **Back in Firebase Console:**
   - Project settings → Your apps → `com.realestate.aqar`
   - Scroll down
   - Click **"Download google-services.json"**

2. **Replace the file:**
   - Replace: `android/app/google-services.json`
   - With the newly downloaded file

---

### Step 5: Rebuild and Upload

1. **Clean build:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Build release APK/AAB:**
   ```bash
   flutter build appbundle --release
   ```

3. **Upload to Play Store:**
   - Upload the new `.aab` file to Play Console
   - Promote to production/internal testing

---

## Verification

After uploading, test the app from Play Store (internal test track):

1. Download app from Play Store
2. Try Google Sign-In
3. Should work now! ✅

---

## Current Certificate Hashes in Your Project

Your `google-services.json` currently has these SHA-1 hashes:
- `eefe4cc4ba7ede1d551a208ffe5af99b5b50e80c`
- `957e147f42393800f4da2fc45ba99a055a9b05a9`
- `0887540c1c5c37295c1f58ffaa26a91950d6d837`

**You need to add the Play Store SHA-1** to this list.

---

## Common Mistakes to Avoid

❌ **Don't use debug SHA-1** - Only works locally
❌ **Don't forget Google Cloud Console** - Firebase alone is not enough
❌ **Don't use wrong package name** - Must be `com.realestate.aqar`
❌ **Don't forget to download new google-services.json** - Must update after adding SHA-1

---

## Still Not Working?

If Google Sign-In still doesn't work after following these steps:

1. **Check OAuth Consent Screen:**
   - Google Cloud Console → OAuth consent screen
   - Make sure app is published (not in testing mode)
   - Or add your test users to the testing list

2. **Check Google Sign-In is enabled:**
   - Firebase Console → Authentication → Sign-in method
   - Make sure "Google" is enabled

3. **Wait 10-15 minutes:**
   - Changes can take a few minutes to propagate

4. **Check package name:**
   - Make sure `applicationId` in `android/app/build.gradle` is `com.realestate.aqar`

---

## Quick Reference Links

- **Play Console:** https://play.google.com/console
- **Firebase Console:** https://console.firebase.google.com
- **Google Cloud Console:** https://console.cloud.google.com
- **Project ID:** `realstate-4564d`
- **Package Name:** `com.realestate.aqar`

---

**Last Updated:** 2025-11-18
