# Backend Fix Request - Google Sign-In & FCM Notifications

## 🎯 Purpose
This document provides all necessary information for the backend team to fix two critical issues:
1. **Google Sign-In not working on Google Play Store** (works locally but fails in production)
2. **FCM Push Notifications implementation**

---

## ⚠️ ISSUE #1: Google Sign-In Fails on Google Play Store

### Problem Description
- Google Sign-In works perfectly when testing locally via Android Studio
- When users download from Google Play Store, Google Sign-In fails with error: `PlatformException(sign_in_failed, Q0.d:10:, null, null)`
- **Root Cause:** Backend may not be properly verifying Google ID tokens from production builds

### Current Situation
- ✅ Firebase Console configured correctly with all SHA-1 certificates
- ✅ Mobile app sends correct data to backend
- ✅ google-services.json updated with Google Play signing certificate
- ❓ Backend ID token verification may be incomplete or missing

---

## 📱 What the Mobile App Sends

### Endpoint
```
POST /api/login
```

### Request Headers
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

### Request Body (What you will receive)
```json
{
  "email": "user@gmail.com",
  "password": "107876543210987654321",
  "login_method": "google",
  "google_id": "107876543210987654321",
  "name": "John Doe",
  "photo_url": "https://lh3.googleusercontent.com/a/default-user=s96-c",
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE4MmU0NzZlZWMxZDg1YjU0NmM3NmVhOTk2YjJiNmY4ZmFhNDc3NzciLCJ0eXAiOiJKV1QifQ..."
}
```

### Field Descriptions
| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `email` | string | User's Google email | Yes |
| `password` | string | Google ID (used as password for Google users) | Yes |
| `login_method` | string | Always "google" for Google sign-in | Yes |
| `google_id` | string | Unique Google user ID (never changes) | Yes |
| `name` | string | User's display name from Google | Yes |
| `photo_url` | string | User's profile picture URL | No (can be null) |
| `id_token` | string | **CRITICAL** - Google JWT token for verification | Yes |

---

## 🔐 REQUIRED: Backend ID Token Verification

### Why ID Token Verification is Critical
The `id_token` is a JWT (JSON Web Token) issued by Google that proves the user actually authenticated with Google. **Without verifying this token, your backend is vulnerable to fake login requests.**

### What You Must Do

#### Step 1: Install Google API Client

**For Laravel/PHP:**
```bash
composer require google/apiclient
```

**For Node.js:**
```bash
npm install google-auth-library
```

**For Python:**
```bash
pip install google-auth
```

#### Step 2: Add Environment Variable

Add to your `.env` file:
```env
GOOGLE_CLIENT_ID=832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com
```

#### Step 3: Implement ID Token Verification

**Laravel/PHP Implementation:**
```php
<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Google\Client as GoogleClient;

class AuthController extends Controller
{
    public function googleLogin(Request $request)
    {
        // Validate request
        $request->validate([
            'email' => 'required|email',
            'google_id' => 'required|string',
            'name' => 'required|string',
            'id_token' => 'required|string',
            'login_method' => 'required|string',
        ]);

        // CRITICAL: Verify the ID token with Google
        $client = new GoogleClient([
            'client_id' => env('GOOGLE_CLIENT_ID')
        ]);

        try {
            // Verify the ID token
            $payload = $client->verifyIdToken($request->id_token);

            if (!$payload) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid Google ID token'
                ], 401);
            }

            // Extract verified data from token
            $googleId = $payload['sub'];           // Google user ID
            $email = $payload['email'];            // Email address
            $emailVerified = $payload['email_verified']; // Email verification status

            // IMPORTANT: Verify that the google_id matches
            if ($googleId !== $request->google_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Google ID mismatch'
                ], 401);
            }

            // Verify that the email matches
            if ($email !== $request->email) {
                return response()->json([
                    'success' => false,
                    'message' => 'Email mismatch'
                ], 401);
            }

        } catch (\Exception $e) {
            \Log::error('Google ID Token verification failed: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Token verification failed: ' . $e->getMessage()
            ], 401);
        }

        // Token is valid - Find or create user
        $user = User::where('email', $email)->first();

        if ($user) {
            // Update existing user
            $user->update([
                'google_id' => $googleId,
                'name' => $request->name,
                'photo_url' => $request->photo_url,
                'email_verified_at' => $emailVerified ? now() : $user->email_verified_at,
            ]);
        } else {
            // Create new user
            $user = User::create([
                'name' => $request->name,
                'email' => $email,
                'google_id' => $googleId,
                'password' => Hash::make($googleId), // Hash the google_id as password
                'photo_url' => $request->photo_url,
                'role' => 'buyer',
                'is_verified' => true,
                'email_verified_at' => $emailVerified ? now() : null,
            ]);
        }

        // Check if user is banned
        if ($user->is_banned) {
            return response()->json([
                'success' => false,
                'message' => 'Your account has been suspended'
            ], 403);
        }

        // Generate authentication token (using Laravel Sanctum)
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'is_verified' => $user->is_verified,
                'is_banned' => $user->is_banned,
                'photo_url' => $user->photo_url,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]
        ]);
    }
}
```

**Node.js/Express Implementation:**
```javascript
const { OAuth2Client } = require('google-auth-library');
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

async function googleLogin(req, res) {
    const { email, google_id, name, id_token, photo_url } = req.body;

    try {
        // Verify the ID token
        const ticket = await client.verifyIdToken({
            idToken: id_token,
            audience: process.env.GOOGLE_CLIENT_ID,
        });

        const payload = ticket.getPayload();
        const googleId = payload['sub'];
        const verifiedEmail = payload['email'];
        const emailVerified = payload['email_verified'];

        // Verify data matches
        if (googleId !== google_id || verifiedEmail !== email) {
            return res.status(401).json({
                success: false,
                message: 'Google ID or email mismatch'
            });
        }

        // Find or create user
        let user = await User.findOne({ email: verifiedEmail });

        if (!user) {
            user = await User.create({
                name,
                email: verifiedEmail,
                google_id: googleId,
                password: await bcrypt.hash(googleId, 10),
                photo_url,
                role: 'buyer',
                is_verified: true,
                email_verified_at: emailVerified ? new Date() : null
            });
        }

        // Generate token
        const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET);

        return res.json({
            success: true,
            message: 'Login successful',
            token,
            user
        });

    } catch (error) {
        console.error('Google token verification failed:', error);
        return res.status(401).json({
            success: false,
            message: 'Token verification failed'
        });
    }
}
```

---

## ⚠️ ISSUE #2: FCM Push Notifications

### What Needs to Be Implemented

#### 1. Store FCM Token Endpoint

**Endpoint:** `POST /api/fcm-token`

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer USER_AUTH_TOKEN",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "fcm_token": "dQw4w9WgXcQ:APA91bHPRgkF3JUikC4ENzTgQMHUZBNWkhAwYa4wTx..."
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "FCM token saved successfully"
}
```

**Implementation Example (Laravel):**
```php
public function storeFcmToken(Request $request)
{
    $user = auth()->user();

    $request->validate([
        'fcm_token' => 'required|string|max:500'
    ]);

    // Store in users table or create separate fcm_tokens table
    $user->update([
        'fcm_token' => $request->fcm_token,
        'fcm_token_updated_at' => now(),
    ]);

    return response()->json([
        'success' => true,
        'message' => 'FCM token saved successfully'
    ]);
}
```

#### 2. Delete FCM Token Endpoint (on Logout)

**Endpoint:** `DELETE /api/fcm-token`

**Request Headers:**
```json
{
  "Authorization": "Bearer USER_AUTH_TOKEN",
  "Accept": "application/json"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "FCM token removed successfully"
}
```

**Implementation Example:**
```php
public function deleteFcmToken(Request $request)
{
    $user = auth()->user();

    $user->update([
        'fcm_token' => null,
        'fcm_token_updated_at' => null,
    ]);

    return response()->json([
        'success' => true,
        'message' => 'FCM token removed successfully'
    ]);
}
```

#### 3. Send Push Notifications

**Install Firebase Admin SDK:**
```bash
composer require kreait/firebase-php
```

**Configure Firebase:**
1. Download Service Account JSON from Firebase Console
2. Save to `storage/app/firebase/credentials.json`
3. Add to `.env`:
```env
FIREBASE_CREDENTIALS=storage/app/firebase/credentials.json
```

**Create Firebase Service:**
```php
<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class FirebaseService
{
    protected $messaging;

    public function __construct()
    {
        $factory = (new Factory)->withServiceAccount(storage_path('app/firebase/credentials.json'));
        $this->messaging = $factory->createMessaging();
    }

    public function sendNotification($fcmToken, $title, $body, $data = [])
    {
        $message = CloudMessage::withTarget('token', $fcmToken)
            ->withNotification(Notification::create($title, $body))
            ->withData($data);

        try {
            $this->messaging->send($message);
            return true;
        } catch (\Exception $e) {
            \Log::error('FCM send failed: ' . $e->getMessage());
            return false;
        }
    }

    public function sendToUser($userId, $title, $body, $data = [])
    {
        $user = \App\Models\User::find($userId);

        if (!$user || !$user->fcm_token) {
            return false;
        }

        return $this->sendNotification($user->fcm_token, $title, $body, $data);
    }

    public function sendToMultipleUsers($userIds, $title, $body, $data = [])
    {
        $users = \App\Models\User::whereIn('id', $userIds)
            ->whereNotNull('fcm_token')
            ->get();

        $tokens = $users->pluck('fcm_token')->toArray();

        if (empty($tokens)) {
            return false;
        }

        $message = CloudMessage::new()
            ->withNotification(Notification::create($title, $body))
            ->withData($data);

        try {
            $this->messaging->sendMulticast($message, $tokens);
            return true;
        } catch (\Exception $e) {
            \Log::error('FCM multicast send failed: ' . $e->getMessage());
            return false;
        }
    }
}
```

**Usage Example:**
```php
// In your controller or event listener
use App\Services\FirebaseService;

$firebase = new FirebaseService();

// Send to single user
$firebase->sendToUser(123, 'New Unit Available', 'Check out this amazing property!', [
    'type' => 'new_unit',
    'unit_id' => '456',
    'compound_id' => '789'
]);

// Send to multiple users
$firebase->sendToMultipleUsers([1, 2, 3], 'Special Offer', '20% discount on all units!', [
    'type' => 'promotion',
    'discount' => '20%'
]);
```

---

## 🗄️ Database Schema

### Add to Users Table:
```sql
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(500) NULL;
ALTER TABLE users ADD COLUMN fcm_token_updated_at TIMESTAMP NULL;
ALTER TABLE users ADD COLUMN google_id VARCHAR(100) NULL;
ALTER TABLE users ADD COLUMN photo_url TEXT NULL;

-- Add index for faster lookups
CREATE INDEX idx_users_google_id ON users(google_id);
CREATE INDEX idx_users_fcm_token ON users(fcm_token);
```

---

## 🔑 Required Configuration Data

### Environment Variables (.env)
```env
# Google Sign-In
GOOGLE_CLIENT_ID=832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com

# Firebase (for FCM)
FIREBASE_CREDENTIALS=storage/app/firebase/credentials.json
```

### Firebase Project Details
```
Project ID: realstate-4564d
Project Number: 832433207149
Storage Bucket: realstate-4564d.firebasestorage.app
```

### Where to Get Firebase Credentials
1. Go to: https://console.firebase.google.com/project/realstate-4564d/settings/serviceaccounts/adminsdk
2. Click "Generate new private key"
3. Download the JSON file
4. Save it to `storage/app/firebase/credentials.json`

---

## 🧪 Testing Instructions

### Test Google Sign-In

**Step 1:** Use this cURL command to test:
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
    "id_token": "GET_REAL_TOKEN_FROM_MOBILE_APP_LOGS"
  }'
```

**Step 2:** Get a real ID token from mobile app
- Run the mobile app
- Attempt Google Sign-In
- Check app logs (console output)
- Copy the `id_token` value
- Use it in the cURL command above

**Expected Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "1|abc123...",
  "user": {
    "id": 1,
    "name": "Test User",
    "email": "test@gmail.com",
    "role": "buyer",
    "is_verified": true,
    "is_banned": false
  }
}
```

### Test FCM Token Storage

```bash
curl -X POST https://aqar.bdcbiz.com/api/fcm-token \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN_HERE" \
  -d '{
    "fcm_token": "dQw4w9WgXcQ:APA91bH..."
  }'
```

### Test Notification Sending

**From Laravel Tinker:**
```php
php artisan tinker

$firebase = new App\Services\FirebaseService();
$firebase->sendToUser(1, 'Test Notification', 'This is a test from backend!', ['type' => 'test']);
```

**Or create a test route:**
```php
Route::get('/test-notification', function() {
    $firebase = new App\Services\FirebaseService();
    $result = $firebase->sendToUser(1, 'Test', 'Testing notifications!', ['type' => 'test']);
    return response()->json(['sent' => $result]);
})->middleware('auth:sanctum');
```

---

## 📋 Backend Checklist

Please complete these tasks:

### Google Sign-In:
- [ ] Install `google/apiclient` package
- [ ] Add `GOOGLE_CLIENT_ID` to `.env`
- [ ] Implement ID token verification in login endpoint
- [ ] Verify `google_id` and `email` match token payload
- [ ] Add `google_id` and `photo_url` columns to users table
- [ ] Test with real ID token from mobile app
- [ ] Return proper error messages for invalid tokens

### FCM Notifications:
- [ ] Install `kreait/firebase-php` package
- [ ] Download Firebase service account credentials
- [ ] Save credentials to `storage/app/firebase/credentials.json`
- [ ] Add `fcm_token` and `fcm_token_updated_at` columns to users table
- [ ] Create `POST /api/fcm-token` endpoint
- [ ] Create `DELETE /api/fcm-token` endpoint
- [ ] Create `FirebaseService` class
- [ ] Test sending notifications to single user
- [ ] Test sending notifications to multiple users

---

## ❓ Questions for Backend Team

### Question 1: Current Google Sign-In Implementation
**Does your current `/api/login` endpoint:**
- A) Verify the Google ID token using Google API? (Required!)
- B) Only check if `login_method === "google"` without verification? (Not secure!)

**If B, please implement Option A using the code provided above.**

### Question 2: ID Token Verification Issues
**Have you encountered any of these when verifying ID tokens:**
- Token verification always fails?
- "Invalid value" errors from Google API?
- Certificate validation errors?

**If yes, please share the error messages so we can help troubleshoot.**

### Question 3: FCM Current Status
**Do you currently have:**
- A) No FCM implementation at all?
- B) FCM endpoints but notifications not working?
- C) FCM working but tokens not saved properly?

### Question 4: Database Schema
**Can you modify the users table to add:**
- `google_id` (VARCHAR 100, nullable, indexed)
- `photo_url` (TEXT, nullable)
- `fcm_token` (VARCHAR 500, nullable, indexed)
- `fcm_token_updated_at` (TIMESTAMP, nullable)

**Or should we create a separate `fcm_tokens` table?**

### Question 5: Firebase Admin SDK
**Do you have experience with:**
- Firebase Admin SDK?
- Downloading service account credentials from Firebase Console?

**If no, we can provide step-by-step instructions.**

---

## 📞 Next Steps

1. **Read this document carefully**
2. **Answer the 5 questions above**
3. **Implement the code provided**
4. **Test using the testing instructions**
5. **Share any errors or issues you encounter**

---

## 📧 Support Files

Additional files provided:
- `BACKEND_TESTING_GUIDE.md` - Detailed testing guide
- `GOOGLE_PLAY_RELEASE_GUIDE.md` - Mobile app release info

---

## 🎯 Success Criteria

**Google Sign-In is fixed when:**
- ✅ Users can sign in with Google from Google Play Store builds
- ✅ Backend verifies Google ID tokens properly
- ✅ Invalid tokens are rejected with error messages
- ✅ User accounts are created/updated correctly

**FCM is working when:**
- ✅ Mobile app can send FCM tokens to backend
- ✅ Backend stores FCM tokens for logged-in users
- ✅ Backend can send test notifications successfully
- ✅ Notifications appear on mobile devices

---

**Priority:** 🔴 HIGH - Critical for production release

**Estimated Implementation Time:** 2-4 hours

**Contact:** [Your contact information]

**Last Updated:** 2024-01-18
