# Backend Testing Guide - Google Sign-In & FCM Notifications

## 📋 Table of Contents
1. [Firebase Configuration](#firebase-configuration)
2. [Google Sign-In Integration](#google-sign-in-integration)
3. [FCM Notifications](#fcm-notifications)
4. [Testing Endpoints](#testing-endpoints)
5. [Sample Payloads](#sample-payloads)

---

## 🔥 Firebase Configuration

### Project Details
```
Project ID: realstate-4564d
Project Number: 832433207149
Storage Bucket: realstate-4564d.firebasestorage.app
```

### Firebase API Key
```
AIzaSyBrMELCDISDehQ9KVP6RVekwwRHqTrJGZQ
```

### Package Name (Android)
```
com.realestate.aqar
```

### SHA-1 Certificates (All 3 must be registered in Firebase)
```
1. Upload Key (Debug/Upload):
   ee:fe:4c:c4:ba:7e:de:1d:55:1a:20:8f:fe:5a:f9:9b:5b:50:e8:0c

2. Old Key:
   95:7e:14:7f:42:39:38:00:f4:da:2f:c4:5b:a9:9a:05:5a:9b:05:a9

3. Google Play App Signing Key (PRODUCTION):
   08:87:54:0c:1c:5c:37:29:5c:1f:58:ff:aa:26:a9:19:50:d6:d8:37
```

---

## 🔐 Google Sign-In Integration

### OAuth Client IDs

#### Web Client ID (Used by Web App):
```
832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com
```

#### Android OAuth Clients:
```
1. For SHA-1: eefe4cc4ba7ede1d551a208ffe5af99b5b50e80c
   Client ID: 832433207149-1ub8e95hl9ug20e3n6ch3hgk6queasu1.apps.googleusercontent.com

2. For SHA-1: 957e147f42393800f4da2fc45ba99a055a9b05a9
   Client ID: 832433207149-vn9r1na57p83k6kna24a1h4lq70n2ug5.apps.googleusercontent.com

3. For SHA-1: 0887540c1c5c37295c1f58ffaa26a91950d6d837 (Google Play)
   Client ID: 832433207149-o8754c1c5c37295c1f58ffaa26a91950d6d837.apps.googleusercontent.com
```

### Backend Endpoint for Google Sign-In

**Endpoint:** `POST /api/login`

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "email": "user@gmail.com",
  "password": "google_user_id_here",
  "login_method": "google",
  "google_id": "google_user_id_here",
  "name": "User Display Name",
  "photo_url": "https://lh3.googleusercontent.com/...",
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE4MmU0N..."
}
```

**Important Fields Explanation:**

1. **email**: User's Google email address
2. **password**: Use Google ID as password for Google sign-in users
3. **login_method**: Must be `"google"` to identify Google login
4. **google_id**: Unique Google user ID (never changes)
5. **name**: User's display name from Google
6. **photo_url**: User's profile picture URL (optional)
7. **id_token**: **CRITICAL** - This is the JWT token from Google that backend must verify

### Verifying Google ID Token (Backend Implementation)

**IMPORTANT:** The backend MUST verify the `id_token` to ensure security.

#### Using Google API PHP Client (Laravel Example):
```php
use Google\Client as GoogleClient;

public function googleLogin(Request $request) {
    $idToken = $request->input('id_token');

    // Initialize Google Client
    $client = new GoogleClient([
        'client_id' => env('GOOGLE_CLIENT_ID')
    ]);

    try {
        // Verify the ID token
        $payload = $client->verifyIdToken($idToken);

        if (!$payload) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid ID token'
            ], 401);
        }

        // Extract verified data
        $googleId = $payload['sub'];
        $email = $payload['email'];
        $name = $payload['name'];
        $emailVerified = $payload['email_verified'];

        // Find or create user
        $user = User::firstOrCreate(
            ['email' => $email],
            [
                'name' => $name,
                'google_id' => $googleId,
                'email_verified_at' => $emailVerified ? now() : null,
                'password' => bcrypt($googleId), // Store hashed google_id
                'role' => 'buyer',
                'is_verified' => true,
            ]
        );

        // Generate authentication token
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'token' => $token,
            'user' => $user
        ]);

    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Token verification failed: ' . $e->getMessage()
        ], 401);
    }
}
```

#### Environment Variables Needed:
```env
GOOGLE_CLIENT_ID=832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com
```

#### Install Required Package (Laravel):
```bash
composer require google/apiclient
```

### Expected Backend Response:
```json
{
  "success": true,
  "message": "Login successful",
  "token": "1|abcdefghijklmnopqrstuvwxyz...",
  "user": {
    "id": 123,
    "name": "User Name",
    "email": "user@gmail.com",
    "role": "buyer",
    "is_verified": true,
    "is_banned": false,
    "photo_url": "https://...",
    "created_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

### Mobile App Flow:

1. User taps "Sign in with Google"
2. App shows Google account picker
3. User selects account
4. App receives:
   - Google ID
   - Email
   - Display Name
   - Photo URL
   - **ID Token** (JWT)
5. App sends all data to backend `/api/login` endpoint
6. Backend verifies ID token with Google
7. Backend creates/updates user
8. Backend returns authentication token
9. App stores token and navigates to home screen

---

## 🔔 FCM Notifications

### FCM Server Key / Service Account

**Location:** Firebase Console → Project Settings → Cloud Messaging → Cloud Messaging API (Legacy)

**Note:** You need to enable **Firebase Cloud Messaging API** in Google Cloud Console.

**Get Server Key:**
1. Go to Firebase Console: https://console.firebase.google.com/project/realstate-4564d
2. Click gear icon → Project Settings
3. Go to "Cloud Messaging" tab
4. Copy "Server key" (starts with `AAAA...`)

**For HTTP v1 API (Recommended):**
- Use Service Account JSON from Firebase Console
- Enable "Firebase Cloud Messaging API" in Google Cloud Console

### Mobile App FCM Token Endpoint

**Endpoint:** `POST /api/fcm-token`

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer USER_AUTH_TOKEN_HERE",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "fcm_token": "dQw4w9WgXcQ:APA91bH..."
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "FCM token saved successfully"
}
```

### Backend Implementation for Storing FCM Token:

```php
public function storeFcmToken(Request $request) {
    $user = auth()->user();

    $request->validate([
        'fcm_token' => 'required|string'
    ]);

    // Store token in user table or separate fcm_tokens table
    $user->update([
        'fcm_token' => $request->fcm_token,
        'fcm_token_updated_at' => now()
    ]);

    return response()->json([
        'success' => true,
        'message' => 'FCM token saved successfully'
    ]);
}
```

### Sending Notifications from Backend

#### Using Firebase Admin SDK (Recommended):

```php
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

public function sendNotification($userId, $title, $body, $data = []) {
    $user = User::find($userId);

    if (!$user || !$user->fcm_token) {
        return false;
    }

    $messaging = app('firebase.messaging');

    $message = CloudMessage::withTarget('token', $user->fcm_token)
        ->withNotification(Notification::create($title, $body))
        ->withData($data);

    try {
        $messaging->send($message);
        return true;
    } catch (\Exception $e) {
        Log::error('FCM send failed: ' . $e->getMessage());
        return false;
    }
}
```

#### Install Required Package:
```bash
composer require kreait/firebase-php
```

### Notification Payload Structure:

**Notification Data Types:**
```json
{
  "type": "new_unit",
  "unit_id": "123",
  "compound_id": "456"
}
```

```json
{
  "type": "new_sale",
  "sale_id": "789",
  "discount": "20%"
}
```

```json
{
  "type": "general",
  "message": "Welcome to our app!"
}
```

### Web Push VAPID Key:
```
BKNUQN5DnmFPV9XbrqwGvuVHHSlDwq2a9PjzmcbSbrMDVJEaGk-w_5MLdkV2dOWn6RUPwPQBK_0lrz0aZemHDVI
```

---

## 🧪 Testing Endpoints

### 1. Test Google Sign-In

**Using cURL:**
```bash
curl -X POST https://aqar.bdcbiz.com/api/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "email": "test@gmail.com",
    "password": "google_id_12345",
    "login_method": "google",
    "google_id": "google_id_12345",
    "name": "Test User",
    "photo_url": "https://example.com/photo.jpg",
    "id_token": "ACTUAL_GOOGLE_ID_TOKEN_HERE"
  }'
```

**Using Postman:**
1. Method: POST
2. URL: `https://aqar.bdcbiz.com/api/login`
3. Headers:
   - `Content-Type: application/json`
   - `Accept: application/json`
4. Body (raw JSON): Use the JSON above

### 2. Test FCM Token Storage

**Using cURL:**
```bash
curl -X POST https://aqar.bdcbiz.com/api/fcm-token \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{
    "fcm_token": "dQw4w9WgXcQ:APA91bH..."
  }'
```

### 3. Test Notification Sending

**Manual Test using Firebase Console:**
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter:
   - Notification title
   - Notification text
4. Click "Send test message"
5. Enter FCM token from app (check app logs)
6. Click "Test"

**Using HTTP v1 API:**
```bash
curl -X POST https://fcm.googleapis.com/v1/projects/realstate-4564d/messages:send \
  -H "Authorization: Bearer YOUR_SERVICE_ACCOUNT_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "FCM_TOKEN_HERE",
      "notification": {
        "title": "Test Notification",
        "body": "This is a test from backend"
      },
      "data": {
        "type": "general",
        "test": "true"
      }
    }
  }'
```

---

## 📦 Sample Payloads

### Complete Google Sign-In Test Payload

**What the mobile app sends:**
```json
{
  "email": "john.doe@gmail.com",
  "password": "107876543210987654321",
  "login_method": "google",
  "google_id": "107876543210987654321",
  "name": "John Doe",
  "photo_url": "https://lh3.googleusercontent.com/a/default-user=s96-c",
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE4MmU0NzZlZWMxZDg1YjU0NmM3NmVhOTk2YjJiNmY4ZmFhNDc3NzciLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJhY2NvdW50cy5nb29nbGUuY29tIiwiYXpwIjoiODMyNDMzMjA3MTQ5LW8yNTdjdWs5MGE5OWZnZGozYnJlcDJtdWZxYTdlNHUyLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwiYXVkIjoiODMyNDMzMjA3MTQ5LW8yNTdjdWs5MGE5OWZnZGozYnJlcDJtdWZxYTdlNHUyLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwic3ViIjoiMTA3ODc2NTQzMjEwOTg3NjU0MzIxIiwiZW1haWwiOiJqb2huLmRvZUBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6InktUW8xZDctaEU2czhRMjBkX3B3M3ciLCJuYW1lIjoiSm9obiBEb2UiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvZGVmYXVsdC11c2VyPXM5Ni1jIiwiZ2l2ZW5fbmFtZSI6IkpvaG4iLCJmYW1pbHlfbmFtZSI6IkRvZSIsImxvY2FsZSI6ImVuIiwiaWF0IjoxNzA0MDY3MjAwLCJleHAiOjE3MDQwNzA4MDB9.signature_here"
}
```

### Complete Notification Payload

**FCM Message Payload:**
```json
{
  "message": {
    "token": "dQw4w9WgXcQ:APA91bHPRgkF3JUikC4ENzTgQMHUZBNWkhAwYa4wTxRyit...",
    "notification": {
      "title": "New Property Available!",
      "body": "Check out this amazing unit in Cairo Compound"
    },
    "data": {
      "type": "new_unit",
      "unit_id": "456",
      "compound_id": "123",
      "compound_name": "Cairo Compound",
      "image_url": "https://example.com/unit.jpg"
    },
    "android": {
      "priority": "high",
      "notification": {
        "sound": "default",
        "channel_id": "high_importance_channel"
      }
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "default",
          "badge": 1
        }
      }
    }
  }
}
```

---

## 🔍 Debugging Tips

### Google Sign-In Issues:

1. **"Invalid ID token"**
   - Check that backend is using correct Google Client ID
   - Ensure ID token hasn't expired (valid for 1 hour)
   - Verify SHA-1 certificates are in Firebase Console

2. **"Sign-in failed: Q0.d:10"**
   - Missing SHA-1 certificate in Firebase (SOLVED!)
   - Ensure all 3 SHA-1 certificates are added

3. **Backend receives null id_token**
   - Check app is sending `id_token` field
   - On mobile, should use `idToken` from `auth.idToken`
   - On web, might use `accessToken` instead

### FCM Notification Issues:

1. **Token not received on backend**
   - Check user is logged in when sending token
   - Verify Authorization header is present
   - Check endpoint URL is correct

2. **Notifications not showing**
   - Verify FCM token is valid (check logs)
   - Ensure notification permissions granted
   - Check Firebase Cloud Messaging API is enabled
   - Test with Firebase Console first

3. **Duplicate notifications**
   - Backend should deduplicate by notification ID
   - App implements duplicate detection (already done)

---

## 📝 Backend Checklist

Before going live:

- [ ] Google Client ID configured in backend env
- [ ] Google API client package installed
- [ ] ID token verification implemented
- [ ] `/api/login` endpoint handles `login_method: google`
- [ ] `/api/fcm-token` endpoint stores FCM tokens
- [ ] Firebase Admin SDK configured
- [ ] Notification sending functionality tested
- [ ] FCM tokens cleaned up on user logout
- [ ] All 3 SHA-1 certificates added to Firebase Console ✅
- [ ] `google-services.json` updated in mobile app ✅

---

## 🎯 Production API URL

```
https://aqar.bdcbiz.com
```

**Endpoints:**
- `POST /api/login` - Google Sign-In
- `POST /api/fcm-token` - Store FCM token
- `DELETE /api/fcm-token` - Remove FCM token on logout

---

## 📧 Support

For backend testing support, ensure you have:
1. Sample Google ID tokens for testing
2. Sample FCM tokens from mobile app logs
3. Access to Firebase Console for notification testing

**Firebase Console:** https://console.firebase.google.com/project/realstate-4564d

**Google Cloud Console:** https://console.cloud.google.com/apis/credentials?project=realstate-4564d

---

**Last Updated:** 2024 (Version 1.0.0+14)
