# 🚀 Multi-Device Testing Guide

## Your 3 Devices
1. **Physical Phone**: Samsung SM A137F (Device ID: RF8TB02VZVH)
2. **Emulator**: Pixel 7a (Will auto-start)
3. **Web Browser**: Chrome on http://localhost:8080

---

## ⚡ Quick Start - Run All 3 Devices

### Option 1: Automatic (Easiest)
```bash
cd C:\Users\B-Smart\AndroidStudioProjects\real
run_all_3_devices.bat
```

**What happens:**
1. ✅ Emulator starts automatically
2. ✅ App launches on physical phone (SM13)
3. ✅ App launches on emulator
4. ✅ App launches on Chrome (port 8080)
5. ✅ 3 terminal windows open (one per device)

### Option 2: Manual Control
```bash
run_all_manual.bat
```

**Interactive menu:**
- Launch emulator first
- Then run apps one by one
- More control over timing

---

## 📱 Manual Commands (If Scripts Don't Work)

### Step 1: Start Emulator
```bash
flutter emulators --launch Pixel_7a
# Wait 20-30 seconds for it to fully boot
```

### Step 2: Run on Physical Phone
```bash
flutter run -d RF8TB02VZVH
```

### Step 3: Run on Emulator
```bash
flutter run -d emulator-5554
# Or check actual ID with: flutter devices
```

### Step 4: Run on Web
```bash
flutter run -d chrome --web-port 8080
```

---

## 🧪 Notification Testing Flow

### Expected Behavior
When logged in with **same account** on all 3 devices:

```
BACKEND SENDS 1 NOTIFICATION
        ↓
    ┌───┴───┬───────┬───────┐
    ↓       ↓       ↓       ↓
  Phone  Emulator  Web   (All devices receive!)
    ✅       ✅      ✅
```

### Test Steps

#### 1. Login on All 3 Devices
- **Phone**: Login with testuser@example.com
- **Emulator**: Login with testuser@example.com
- **Web**: Login with testuser@example.com

#### 2. Verify FCM Tokens Registered
Check console output on each device for:
```
✅ FCM Token registered
📱 Device token: dKxF7...
```

#### 3. Check Database (Backend)
```sql
SELECT
    id,
    user_id,
    device_type,
    LEFT(token, 20) as token_preview,
    created_at
FROM fcm_tokens
WHERE user_id = (SELECT id FROM users WHERE email = 'testuser@example.com')
ORDER BY created_at DESC;
```

**Expected result: 3 rows**
```
| id | user_id | device_type | token_preview     | created_at          |
|----|---------|-------------|-------------------|---------------------|
| 1  | 123     | android     | cY3mP... (phone)  | 2025-01-15 10:00:00 |
| 2  | 123     | android     | fT8nQ... (emu)    | 2025-01-15 10:01:00 |
| 3  | 123     | web         | dKxF7... (web)    | 2025-01-15 10:02:00 |
```

#### 4. Send Test Notification

**Via Firebase Console:**
1. Go to: https://console.firebase.google.com
2. Cloud Messaging → Send test message
3. Target: All users (or specific user)
4. Send

**Via Backend API:**
```bash
curl -X POST "https://aqar.bdcbiz.com/api/notifications/test" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 123,
    "title": "Multi-Device Test",
    "body": "You should see this on all 3 devices!"
  }'
```

#### 5. Verify Notification Received

**Physical Phone (SM13):**
- ✅ Notification in status bar
- ✅ Sound/vibration
- ✅ App shows notification

**Emulator:**
- ✅ Notification in Android notification tray
- ✅ App shows notification

**Web (Chrome):**
- ✅ Browser notification (top-right)
- ✅ App shows notification

---

## 🔍 Debugging

### Check if App is Running on All Devices
```bash
flutter devices
```
Should show:
- ✅ SM A137F (mobile) • RF8TB02VZVH
- ✅ emulator-5554 (mobile)
- ✅ Chrome (web)

### View Live Logs

**Phone:**
```bash
adb -s RF8TB02VZVH logcat | findstr "flutter"
```

**Emulator:**
```bash
adb -s emulator-5554 logcat | findstr "flutter"
```

**Web:**
- Open Chrome DevTools (F12)
- Check Console tab

### Common Issues

**❌ Emulator won't start:**
```bash
# Kill any stuck emulator processes
taskkill /F /IM qemu-system-x86_64.exe
# Try again
flutter emulators --launch Pixel_7a
```

**❌ Phone not detected:**
```bash
# Check USB debugging is enabled on phone
adb devices
# Should show: RF8TB02VZVH device
```

**❌ Port 8080 already in use:**
```bash
# Kill process on port 8080
netstat -ano | findstr :8080
taskkill /F /PID <PID_NUMBER>
# Or use different port
flutter run -d chrome --web-port 8081
```

---

## 📊 Testing Subscription on All 3 Devices

### Test Flow:
1. **Sign up** on phone → Gets Free plan
2. **Login** on all 3 devices with same account
3. **Subscribe** to Basic plan on web
4. **Check** on phone → Should show Basic plan
5. **Check** on emulator → Should show Basic plan
6. **All 3 devices** stay in sync!

### Verify Subscription Sync:
- Change subscription on ANY device
- Check on OTHER devices
- Should reflect immediately (after reload/re-login)

---

## 🎯 Notification Test Checklist

- [ ] All 3 devices running simultaneously
- [ ] Logged in with SAME account on all 3
- [ ] Database shows 3 FCM tokens for user
- [ ] Send test notification from Firebase Console
- [ ] ✅ Phone receives notification
- [ ] ✅ Emulator receives notification
- [ ] ✅ Web receives notification
- [ ] Click notification on phone → Opens app
- [ ] Click notification on emulator → Opens app
- [ ] Click notification on web → Opens app

---

## 💡 Pro Tips

1. **Keep terminals open** - Don't close terminal windows, apps will stop
2. **Hot reload works** - Press 'r' in any terminal to hot reload that device
3. **Hot restart** - Press 'R' to fully restart
4. **Quit app** - Press 'q' in terminal to stop that device
5. **View logs** - Scroll up in terminal to see past logs

---

## 🆘 Emergency Commands

**Stop all Flutter processes:**
```bash
tasklist | findstr "flutter"
taskkill /F /IM flutter.exe
```

**Stop emulator:**
```bash
taskkill /F /IM qemu-system-x86_64.exe
```

**Kill processes on port 8080:**
```bash
netstat -ano | findstr :8080
taskkill /F /PID <PID>
```

---

## 📝 Summary

**To test notifications on 3 devices:**

```bash
# 1. Run all devices
run_all_3_devices.bat

# 2. Login on all 3 with same account
testuser@example.com / password123

# 3. Send notification from Firebase Console

# 4. Verify all 3 devices receive it ✅
```

**Expected: Same notification appears on ALL 3 devices!** 🎉
