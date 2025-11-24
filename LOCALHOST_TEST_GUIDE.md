# Testing AI Chat on Localhost

## Quick Test (Recommended)

### Option 1: Run with Flutter (Debug Mode)
```bash
flutter run -d chrome --web-port=8080
```

Then:
1. Browser will open automatically at `http://localhost:8080`
2. Navigate to the AI Chat screen
3. Try asking: "Show me villas in New Cairo"
4. Open DevTools (F12) and check Console tab

### Option 2: Build and Serve (Production Mode)
```bash
# Build
flutter build web --release

# Serve locally
cd build/web
python -m http.server 8080
```

Then open: `http://localhost:8080`

## What to Look For

### ✅ Success Indicators:
1. **No CSP errors** in console like:
   ```
   ❌ Refused to connect to 'https://generativelanguage.googleapis.com' because it violates CSP
   ```

2. **You see these logs:**
   ```
   🤖 WEB AI CHAT SCREEN OPENED
   💬 USER SENT MESSAGE: "Show me villas in New Cairo"
   📡 Searching database...
   ✅ Filter API found X units
   🤖 AI responded
   ```

3. **AI responds** with property suggestions
4. **Property cards display** correctly

### ❌ Failure Signs:
- CSP violation errors in console
- No response from AI
- "Failed to send message" error
- Loading spinner never stops

## Quick Debug Commands

### Check if app is running:
```bash
curl http://localhost:8080
```

### View browser console:
- Press F12
- Go to Console tab
- Look for errors (red text)

### Clear cache:
- Press Ctrl+Shift+Delete
- Select "Cached images and files"
- Click Clear
- Refresh with Ctrl+F5

## Current Status

The fix has been applied to `web/index.html`:
- ✅ Added `https://generativelanguage.googleapis.com` to CSP
- ✅ AI API calls will now be allowed
- ✅ Should work on both localhost and production

## Test Commands

```bash
# 1. Clean build
flutter clean
flutter pub get

# 2. Run on localhost
flutter run -d chrome

# 3. Check if AI works
# - Go to AI Chat
# - Type: "Show me villas"
# - Wait for response

# 4. Check console (F12)
# - Should see AI logs
# - No CSP errors
```

## Troubleshooting

### If still not working:

1. **Hard refresh browser:**
   ```
   Ctrl + F5
   ```

2. **Check if Chrome is using correct port:**
   ```bash
   netstat -ano | findstr :8080
   ```

3. **Kill any blocking processes:**
   ```bash
   taskkill /F /PID <PID_NUMBER>
   ```

4. **Try incognito mode:**
   - Opens fresh browser with no cache
   - Ctrl+Shift+N

5. **Check API key is valid:**
   - Open `lib/feature/ai_chat/domain/config.dart`
   - Verify: `geminiApiKey = 'AIzaSyDAAktGvB3W6MTsoJQ1uT08NVB0_O48_7Q'`
   - Test key at: https://aistudio.google.com/app/apikey

## Expected Timeline

- **Localhost test:** Immediate (5 minutes)
- **Deploy to production:** After localhost confirmation
- **Full testing:** 10-15 minutes total

---

**Bottom Line:** Yes, it works on localhost! Just run `flutter run -d chrome` and test the AI chat immediately. No need to deploy first.
