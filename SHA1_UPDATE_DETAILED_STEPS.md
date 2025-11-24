# Step-by-Step: Update Firebase & Google Cloud with Play Store SHA-1

## PART 1: Get SHA-1 from Play Console (5 minutes)

### Step 1.1: Open Google Play Console
1. Open your browser
2. Go to: **https://play.google.com/console**
3. Sign in with your Google account (the one that manages the app)

### Step 1.2: Find Your App
1. You'll see a list of your apps
2. Click on your app: **"Aqar" or "Real Estate" app**
   - Package name: `com.realestate.aqar`

### Step 1.3: Navigate to App Signing
1. On the left sidebar, look for **"Release"**
2. Click **Release** → then click **"Setup"**
3. Click **"App Signing"**

### Step 1.4: Copy the SHA-1 Certificate
1. You'll see a section called **"App signing key certificate"**
2. Find the line that says **"SHA-1 certificate fingerprint"**
   - It looks like: `A1:B2:C3:D4:E5:F6:...` (20 groups of 2 characters)
3. Click the **Copy icon** 📋 next to it
4. **Save it in a notepad** - you'll need it in the next steps

### Step 1.5: Also Copy SHA-256 (Optional but Recommended)
1. Also copy **"SHA-256 certificate fingerprint"**
2. Save it in notepad too

---

## PART 2: Update Firebase Console (7 minutes)

### Step 2.1: Open Firebase Console
1. Open a new browser tab
2. Go to: **https://console.firebase.google.com**
3. Sign in with your Google account

### Step 2.2: Select Your Project
1. You'll see your Firebase projects
2. Click on: **"realstate-4564d"** project

### Step 2.3: Open Project Settings
1. Look at the left sidebar
2. Click the **⚙️ (gear icon)** at the bottom
3. Click **"Project settings"**

### Step 2.4: Find Your Android App
1. Scroll down to the section **"Your apps"**
2. You should see your Android app icon
3. Find the app with package name: **`com.realestate.aqar`**

### Step 2.5: Add SHA-1 Fingerprint
1. Under your Android app, you'll see **"SHA certificate fingerprints"**
2. You should already see 3 fingerprints listed:
   - `eefe4cc4ba7ede1d551a208ffe5af99b5b50e80c`
   - `957e147f42393800f4da2fc45ba99a055a9b05a9`
   - `0887540c1c5c37295c1f58ffaa26a91950d6d837`

3. Click the **"Add fingerprint"** button
4. A text box will appear
5. **Paste the SHA-1** you copied from Play Console (without colons, just the hex characters)
   - Example: If you copied `A1:B2:C3:D4:E5:F6`, paste `A1B2C3D4E5F6`
   - Or paste with colons, Firebase accepts both formats
6. Click **Save** or press Enter

### Step 2.6: Add SHA-256 (Optional)
1. Click **"Add fingerprint"** again
2. Paste the SHA-256 you copied
3. Click **Save**

### Step 2.7: Download New google-services.json
1. Still in Project Settings, scroll down a bit
2. Under your Android app section
3. Click the **"google-services.json"** download button
4. Save the file to your computer
5. **Keep this file safe** - you'll need it in Part 4

---

## PART 3: Update Google Cloud Console (10 minutes)

⚠️ **THIS IS THE MOST IMPORTANT PART** - Don't skip!

### Step 3.1: Open Google Cloud Console
1. Open a new browser tab
2. Go to: **https://console.cloud.google.com**
3. Sign in with the same Google account

### Step 3.2: Select Your Project
1. At the top of the page, you'll see a project dropdown
2. Click it and select: **"realstate-4564d"**
   - Or search for "realstate" to find it

### Step 3.3: Navigate to APIs & Services
1. Look at the left hamburger menu (☰)
2. Hover over **"APIs & Services"**
3. Click **"Credentials"**

### Step 3.4: Review Existing OAuth Clients
1. You'll see a list of **"OAuth 2.0 Client IDs"**
2. Look for Android clients with these IDs:
   - `832433207149-1ub8e95hl9ug20e3n6ch3hgk6queasu1` (SHA-1: eefe4...)
   - `832433207149-vn9r1na57p83k6kna24a1h4lq70n2ug5` (SHA-1: 957e1...)
   - `832433207149-o8754c1c5c37295c1f58ffaa26a91950d6d837` (SHA-1: 0887...)

### Step 3.5: Check if Play Store SHA-1 Already Exists
1. Click on each Android OAuth client
2. Check if any of them has the SHA-1 you copied from Play Console
3. **If you find it** - Great! Skip to Part 4
4. **If you DON'T find it** - Continue to Step 3.6

### Step 3.6: Create New OAuth Client ID
1. At the top, click **"+ CREATE CREDENTIALS"**
2. Select **"OAuth client ID"**

### Step 3.7: Configure OAuth Client
1. **Application type:** Select **"Android"**

2. **Name:** Type something like:
   - `Aqar App - Play Store Production`

3. **Package name:** Type exactly:
   - `com.realestate.aqar`

4. **SHA-1 certificate fingerprint:**
   - Paste the SHA-1 from Play Console
   - With or without colons (both work)
   - Example: `A1:B2:C3:D4:E5:F6:...` or `A1B2C3D4E5F6...`

5. Click **"CREATE"**

### Step 3.8: Save the Client ID
1. A popup will show your new **Client ID**
   - It looks like: `832433207149-XXXXXXXXXXXX.apps.googleusercontent.com`
2. **Copy this Client ID** and save it in notepad
3. Click **"OK"**

---

## PART 4: Update Your App (5 minutes)

### Step 4.1: Replace google-services.json
1. Open your project folder: `C:\Users\B-Smart\AndroidStudioProjects\real`
2. Navigate to: `android\app\`
3. Find the file: `google-services.json`
4. **Replace it** with the new `google-services.json` you downloaded in Step 2.7
   - Delete the old one
   - Copy the new one to the same location

### Step 4.2: Verify the File
1. Open the new `google-services.json` in a text editor
2. Check that it has your new OAuth client in the `oauth_client` section
3. You should see 4 OAuth clients now (3 old + 1 new)

### Step 4.3: Clean and Rebuild
1. Open your terminal/command prompt
2. Navigate to your project directory
3. Run these commands:

```bash
flutter clean
flutter pub get
```

### Step 4.4: Build Release Version
Build the release APK or App Bundle:

```bash
flutter build appbundle --release
```

Or if you want APK:
```bash
flutter build apk --release
```

### Step 4.5: Upload to Play Store
1. Go back to: **https://play.google.com/console**
2. Select your app
3. Go to: **Release** → **Testing** → **Internal testing** (or Production)
4. Click **"Create new release"**
5. Upload the new `.aab` file from:
   - `build\app\outputs\bundle\release\app-release.aab`
6. Complete the release process

---

## PART 5: Test (10 minutes)

### Step 5.1: Wait for Processing
1. After uploading, wait **10-15 minutes**
2. Google needs to process the new build
3. Changes to OAuth credentials also take a few minutes to propagate

### Step 5.2: Install from Play Store
1. On your test device, go to Play Store
2. Find your app (from internal test track or production)
3. Install or update the app

### Step 5.3: Test Google Sign-In
1. Open the app
2. Click "Sign in with Google"
3. Select your Google account
4. **It should work now!** ✅

---

## Troubleshooting

### If Google Sign-In Still Doesn't Work:

#### Check 1: OAuth Consent Screen
1. Go to: https://console.cloud.google.com
2. Navigate to: **APIs & Services** → **OAuth consent screen**
3. Make sure:
   - App status is **"In Production"** (not Testing)
   - OR add your test email to the test users list

#### Check 2: Google Sign-In Enabled in Firebase
1. Go to: https://console.firebase.google.com
2. Select project: `realstate-4564d`
3. Go to: **Authentication** → **Sign-in method**
4. Make sure **"Google"** provider is **Enabled**
5. Check the **Web SDK configuration** section
6. The Web client ID should be: `832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com`

#### Check 3: Package Name
1. Open: `android/app/build.gradle`
2. Find `applicationId`
3. Make sure it's exactly: `com.realestate.aqar`

#### Check 4: Wait Longer
- Sometimes changes take up to **24 hours** to fully propagate
- Be patient and try again later

#### Check 5: Clear App Data
1. On your device: Settings → Apps → Your App
2. Clear Storage and Cache
3. Try signing in again

---

## Quick Checklist ✅

Before you finish, make sure you did ALL of these:

- [ ] Copied SHA-1 from Play Console (App Signing page)
- [ ] Added SHA-1 to Firebase Console (Project Settings → Your app)
- [ ] Downloaded new google-services.json from Firebase
- [ ] Added SHA-1 to Google Cloud Console (Created new OAuth Client)
- [ ] Replaced android/app/google-services.json with new file
- [ ] Ran `flutter clean` and `flutter pub get`
- [ ] Built new release: `flutter build appbundle --release`
- [ ] Uploaded new .aab to Play Store
- [ ] Waited 10-15 minutes for changes to propagate
- [ ] Tested on device from Play Store

---

## Important Notes

⚠️ **Common Mistakes:**
- Forgetting to update Google Cloud Console (Firebase alone is NOT enough)
- Using SHA-1 from wrong source (debug instead of Play Store)
- Not downloading new google-services.json after adding SHA-1
- Not rebuilding the app after updating google-services.json
- Testing too soon (changes need time to propagate)

💡 **Pro Tips:**
- Keep all your SHA-1 certificates in a safe document for future reference
- Add both SHA-1 and SHA-256 for extra compatibility
- Test on internal test track before releasing to production
- If you change signing keys in future, repeat this process

---

## Contact Information

**Your Current Configuration:**
- **Firebase Project ID:** realstate-4564d
- **Package Name:** com.realestate.aqar
- **Project Number:** 832433207149

**Useful Links:**
- Play Console: https://play.google.com/console
- Firebase Console: https://console.firebase.google.com
- Google Cloud Console: https://console.cloud.google.com

---

**Last Updated:** 2025-11-18
**Status:** Ready to follow
