# How to Get Google AI Studio API Key - Step by Step

## ⚠️ Important: NO FILE UPLOAD NEEDED!

You don't need to upload your Flutter app or any files to get an API key!

---

## 📝 Method 1: Quick API Key (Recommended - 1 minute)

### Step 1: Visit the API Key Page
Go to: https://aistudio.google.com/app/apikey

### Step 2: Click "Create API Key"
You'll see one of these options:

**Option A**: Blue button saying **"Get API key"** or **"Create API key"**
- Just click it!

**Option B**: Dropdown saying **"Create API key in new project"**
- Click the dropdown
- Select "Create API key in new project"
- Google will auto-create a project for you

### Step 3: Wait a Few Seconds
Google will create an API key (looks like: `AIzaSyC1234567890abcdefg...`)

### Step 4: Copy the Key
- Click the "Copy" icon next to the key
- Keep it safe - you'll need it in your app

### Step 5: Done!
You now have your API key. No project needed, no upload needed!

---

## 📝 Method 2: Create Google Cloud Project First (Optional)

If you want more control, you can create a Google Cloud project first:

### Step 1: Go to Google Cloud Console
Visit: https://console.cloud.google.com

### Step 2: Create New Project
1. Click the project dropdown (top left, near "Google Cloud")
2. Click "New Project"
3. Enter project name: "Real Estate AI" (or any name)
4. Click "Create"
5. Wait for project to be created

### Step 3: Enable Gemini API
1. Go to: https://console.cloud.google.com/apis/library
2. Search for "Generative Language API" or "Gemini API"
3. Click on it
4. Click "Enable"
5. Wait for it to enable

### Step 4: Get API Key
1. Go to: https://aistudio.google.com/app/apikey
2. Click the dropdown "Create API key in existing project"
3. Select your project "Real Estate AI"
4. Click to create key
5. Copy the generated key

---

## 🎯 What You'll See (Screenshots Description)

### On https://aistudio.google.com/app/apikey:

**Top of Page:**
```
Get an API key
────────────────────────────────────────
To call the Gemini API, you need an API key.

[Get API key] or [Create API key ▼]
```

**After Creating:**
```
Your API keys
────────────────────────────────────────
API Key 1
AIzaSyC1234567890abcdefg...  [📋 Copy] [🗑️ Delete]
Created: Jan 9, 2025
```

---

## ⚡ Quick Copy-Paste Guide

After you get your API key:

### Step 1: Copy Your Key
It looks like this: `AIzaSyC1234567890abcdefghijklmnopqrstuvwxyz`

### Step 2: Open Your App Config File
```bash
# Open this file in your code editor:
lib/feature/ai_chat/domain/config.dart
```

### Step 3: Paste Your Key
Find this line (line 2):
```dart
static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
```

Replace with your actual key:
```dart
static const String geminiApiKey = 'AIzaSyC1234567890abcdefghijklmnopqrstuvwxyz';
```

### Step 4: Save File
Press Ctrl+S (Windows) or Cmd+S (Mac)

### Step 5: Run Your App
```bash
flutter pub get
flutter run
```

---

## ❓ Common Questions

### Q: Do I need to upload my Flutter app?
**A**: No! The API key works from any app. No upload needed.

### Q: Do I need to create a project?
**A**: No! Google creates one automatically when you click "Create API key"

### Q: Where do I upload my prompts?
**A**: You don't upload prompts. They're in your app code:
- File: `lib/feature/ai_chat/data/chat_remote_data_source.dart`
- Line: 36

### Q: Can I test prompts before adding to my app?
**A**: Yes! Go to https://aistudio.google.com and click "Create new prompt"

### Q: Is the API key free?
**A**: Yes, free tier allows 60 requests per minute

### Q: What if I don't see "Create API key" button?
**A**: Try these:
1. Make sure you're signed in to Google
2. Refresh the page
3. Try incognito/private mode
4. Use Google Cloud Console method instead

---

## 🔍 Troubleshooting

### Issue: "No create button visible"

**Try This:**
1. Sign out of Google
2. Sign back in
3. Visit: https://aistudio.google.com/app/apikey
4. Should see the button now

### Issue: "API key creation failed"

**Try This:**
1. Go to: https://console.cloud.google.com
2. Create a new project manually
3. Enable "Generative Language API"
4. Then get API key

### Issue: "Don't see my project"

**Answer:**
- You don't need to see "your project" on the API key page
- Google AI Studio is separate from your Flutter app
- Just create a new API key (any project works)
- The key works with your app automatically

---

## 🎬 Video Alternative (If Needed)

If you're still confused, watch Google's official video:
https://www.youtube.com/watch?v=WmYdKOceARw

Or search YouTube for: "How to get Gemini API key"

---

## 🚫 Common Mistakes

### ❌ WRONG: Looking for "Real Estate App" project
You won't find your Flutter app in Google AI Studio. It's not uploaded there.

### ❌ WRONG: Trying to upload files
No files need to be uploaded. API key is all you need.

### ❌ WRONG: Waiting for project approval
API keys are instant. No approval needed.

### ✅ CORRECT: Just create API key
Click button → Get key → Copy to your app → Done!

---

## 🎯 What Happens After You Add Key

1. You add key to `config.dart`
2. Run `flutter pub get`
3. Run your app
4. Click "AI Assistant" button
5. Type a message
6. Your app → Sends to Google AI Studio
7. AI responds
8. Property card appears

**That's it!** No project upload, no complex setup.

---

## 📞 Still Stuck?

### Option 1: Use Test Key (Temporary)
For testing only, you can use this approach:
1. Go to: https://aistudio.google.com
2. Click "Create new prompt"
3. Look for "Get API key" in the top right
4. Click it to get a key

### Option 2: Google Cloud Console
If AI Studio isn't working:
1. https://console.cloud.google.com
2. Create project
3. Enable "Generative Language API"
4. Credentials → Create API Key

### Option 3: Check Account
Make sure:
- You're signed in to Google
- Using a personal Gmail (not restricted workspace account)
- Your Google account is active

---

## ✅ Checklist

Before asking for help, verify:

- [ ] Visited https://aistudio.google.com/app/apikey
- [ ] Signed in with Google account
- [ ] Clicked "Create API key" or "Get API key"
- [ ] Copied the generated key (starts with AIza...)
- [ ] Pasted key into `lib/feature/ai_chat/domain/config.dart`
- [ ] Saved the file
- [ ] Ran `flutter pub get`

If all checked ✅, your integration is ready!

---

**Remember: Your Flutter app never gets uploaded anywhere. The API key is just a password that lets your app talk to Google AI Studio. That's all!**
