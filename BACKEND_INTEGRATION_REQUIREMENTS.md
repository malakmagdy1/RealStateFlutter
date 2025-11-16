# Backend Integration Requirements for Google Sign-In & Notifications

## 📝 Overview
Your Flutter app is already configured to send data to the backend. This document explains what your **Laravel backend** needs to handle.

---

## 1️⃣ Google Sign-In Backend Requirements

### **Endpoint:** `POST /api/login`

### **What the Flutter app sends:**
```json
{
  "email": "user@gmail.com",
  "password": "google_user_id_here",
  "login_method": "google",
  "google_id": "google_user_id_here",
  "name": "John Doe",
  "photo_url": "https://lh3.googleusercontent.com/...",
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE4MmU0..."
}
```

### **What the backend should do:**

1. **Verify the ID Token (Recommended for Security):**
   ```php
   // Use Google's library to verify the ID token
   require_once 'vendor/autoload.php';

   $client = new Google_Client(['client_id' => '832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com']);
   $payload = $client->verifyIdToken($request->id_token);

   if (!$payload) {
       return response()->json(['success' => false, 'error' => 'Invalid Google token'], 401);
   }

   // Extract user info from token
   $googleId = $payload['sub'];
   $email = $payload['email'];
   ```

2. **Find or Create User:**
   ```php
   $user = User::where('google_id', $request->google_id)
               ->orWhere('email', $request->email)
               ->first();

   if (!$user) {
       // Create new user
       $user = User::create([
           'google_id' => $request->google_id,
           'email' => $request->email,
           'name' => $request->name,
           'photo_url' => $request->photo_url,
           'email_verified_at' => now(), // Google emails are pre-verified
           'is_active' => true,
       ]);
   } else {
       // Update existing user with Google info
       $user->update([
           'google_id' => $request->google_id,
           'photo_url' => $request->photo_url,
       ]);
   }
   ```

3. **Check Account Status:**
   ```php
   // Check if account is suspended
   if (!$user->is_active || $user->is_suspended) {
       return response()->json([
           'success' => false,
           'error' => 'Account is suspended'
       ], 403);
   }
   ```

4. **Generate Auth Token:**
   ```php
   // Using Laravel Sanctum
   $token = $user->createToken('google_login')->plainTextToken;

   // Or using JWT
   // $token = JWTAuth::fromUser($user);
   ```

5. **Return Success Response:**
   ```php
   return response()->json([
       'success' => true,
       'message' => 'Google login successful',
       'token' => $token,
       'user' => [
           'id' => $user->id,
           'name' => $user->name,
           'email' => $user->email,
           'phone' => $user->phone,
           'photo_url' => $user->photo_url,
           'is_email_verified' => true,
           'subscription' => [
               'is_active' => $user->subscription_active,
               'plan' => $user->subscription_plan,
               'expires_at' => $user->subscription_expires_at,
           ]
       ]
   ]);
   ```

### **Backend Response Format:**
```json
{
  "success": true,
  "message": "Google login successful",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 123,
    "name": "John Doe",
    "email": "user@gmail.com",
    "phone": "+1234567890",
    "photo_url": "https://lh3.googleusercontent.com/...",
    "is_email_verified": true,
    "subscription": {
      "is_active": true,
      "plan": "premium",
      "expires_at": "2025-12-31"
    }
  }
}
```

---

## 2️⃣ FCM Notification Token Backend Requirements

### **Endpoint:** `POST /api/fcm-token`

### **What the Flutter app sends:**
```json
{
  "fcm_token": "dXvK8j7TQqS9mL4nB2hP:APA91bF..."
}
```

### **Headers:**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: application/json
Accept: application/json
```

### **What the backend should do:**

1. **Validate Auth Token:**
   ```php
   // Laravel Sanctum
   $user = auth('sanctum')->user();

   if (!$user) {
       return response()->json([
           'success' => false,
           'error' => 'Unauthorized'
       ], 401);
   }
   ```

2. **Store/Update FCM Token:**
   ```php
   // Database schema for fcm_tokens table:
   // - id (primary key)
   // - user_id (foreign key to users table)
   // - fcm_token (text)
   // - device_type (enum: 'android', 'ios', 'web')
   // - device_name (string, optional)
   // - created_at
   // - updated_at

   use Illuminate\Support\Facades\DB;

   DB::table('fcm_tokens')->updateOrInsert(
       [
           'user_id' => $user->id,
           'fcm_token' => $request->fcm_token,
       ],
       [
           'device_type' => $request->device_type ?? 'web', // 'android', 'ios', or 'web'
           'device_name' => $request->device_name ?? null,
           'updated_at' => now(),
       ]
   );
   ```

3. **Return Success Response:**
   ```php
   return response()->json([
       'success' => true,
       'message' => 'FCM token saved successfully',
       'data' => [
           'user_id' => $user->id,
       ]
   ]);
   ```

### **Backend Response Format:**
```json
{
  "success": true,
  "message": "FCM token saved successfully",
  "data": {
    "user_id": 123
  }
}
```

---

## 3️⃣ Database Schema Requirements

### **Users Table:**
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    google_id VARCHAR(255) UNIQUE NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NULL,
    photo_url TEXT NULL,
    password VARCHAR(255) NULL, -- NULL for Google sign-in users
    email_verified_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_suspended BOOLEAN DEFAULT FALSE,
    subscription_active BOOLEAN DEFAULT FALSE,
    subscription_plan VARCHAR(50) NULL,
    subscription_expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_google_id (google_id),
    INDEX idx_email (email)
);
```

### **FCM Tokens Table:**
```sql
CREATE TABLE fcm_tokens (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    fcm_token TEXT NOT NULL,
    device_type ENUM('android', 'ios', 'web') DEFAULT 'web',
    device_name VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_token (user_id, fcm_token(255))
);
```

---

## 4️⃣ Sending Notifications from Backend

### **Send notification to a specific user:**
```php
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

function sendNotificationToUser($userId, $title, $body, $data = []) {
    // Get user's FCM tokens
    $tokens = DB::table('fcm_tokens')
        ->where('user_id', $userId)
        ->pluck('fcm_token')
        ->toArray();

    if (empty($tokens)) {
        return false; // No tokens found
    }

    // Initialize Firebase
    $factory = (new Factory)->withServiceAccount(config('firebase.credentials'));
    $messaging = $factory->createMessaging();

    // Create notification
    $notification = Notification::create($title, $body);

    // Send to each token
    foreach ($tokens as $token) {
        try {
            $message = CloudMessage::withTarget('token', $token)
                ->withNotification($notification)
                ->withData($data);

            $messaging->send($message);
        } catch (\Exception $e) {
            // Token might be invalid, remove it
            DB::table('fcm_tokens')->where('fcm_token', $token)->delete();
        }
    }

    return true;
}

// Usage example:
sendNotificationToUser(
    userId: 123,
    title: 'New Property Available!',
    body: 'A new apartment in Cairo matches your preferences',
    data: [
        'type' => 'new_property',
        'property_id' => '456',
        'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
    ]
);
```

### **Send notification to all users (broadcast):**
```php
function sendBroadcastNotification($title, $body, $data = []) {
    $tokens = DB::table('fcm_tokens')
        ->distinct()
        ->pluck('fcm_token')
        ->toArray();

    // Firebase allows sending to up to 500 tokens at once
    $chunks = array_chunk($tokens, 500);

    $factory = (new Factory)->withServiceAccount(config('firebase.credentials'));
    $messaging = $factory->createMessaging();
    $notification = Notification::create($title, $body);

    foreach ($chunks as $tokenChunk) {
        try {
            $messaging->sendMulticast(
                CloudMessage::new()
                    ->withNotification($notification)
                    ->withData($data),
                $tokenChunk
            );
        } catch (\Exception $e) {
            // Handle error
            Log::error('Broadcast notification failed: ' . $e->getMessage());
        }
    }
}
```

---

## 5️⃣ Laravel Routes Example

```php
// routes/api.php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\NotificationController;

// Public routes (no auth required)
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);

// Protected routes (require Bearer token)
Route::middleware('auth:sanctum')->group(function () {
    // FCM token management
    Route::post('/fcm-token', [NotificationController::class, 'saveFcmToken']);
    Route::delete('/fcm-token', [NotificationController::class, 'deleteFcmToken']);

    // Other protected endpoints
    Route::get('/user', [AuthController::class, 'getUser']);
    Route::post('/logout', [AuthController::class, 'logout']);
});
```

---

## 6️⃣ Laravel Controller Examples

### **AuthController.php:**
```php
<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        // Handle Google Sign-In
        if ($request->login_method === 'google') {
            return $this->handleGoogleLogin($request);
        }

        // Handle regular email/password login
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        if (!$user->is_active) {
            return response()->json([
                'success' => false,
                'error' => 'Account is suspended'
            ], 403);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'success' => true,
            'token' => $token,
            'user' => $user
        ]);
    }

    private function handleGoogleLogin(Request $request)
    {
        $request->validate([
            'google_id' => 'required',
            'email' => 'required|email',
            'name' => 'required',
            'id_token' => 'required',
        ]);

        // Verify Google ID token (optional but recommended)
        // ... verification code here ...

        $user = User::where('google_id', $request->google_id)
                    ->orWhere('email', $request->email)
                    ->first();

        if (!$user) {
            $user = User::create([
                'google_id' => $request->google_id,
                'email' => $request->email,
                'name' => $request->name,
                'photo_url' => $request->photo_url,
                'email_verified_at' => now(),
                'is_active' => true,
            ]);
        } else {
            $user->update([
                'google_id' => $request->google_id,
                'photo_url' => $request->photo_url,
            ]);
        }

        if (!$user->is_active) {
            return response()->json([
                'success' => false,
                'error' => 'Account is suspended'
            ], 403);
        }

        $token = $user->createToken('google_login')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Google login successful',
            'token' => $token,
            'user' => $user
        ]);
    }
}
```

### **NotificationController.php:**
```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    public function saveFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user = auth()->user();

        DB::table('fcm_tokens')->updateOrInsert(
            [
                'user_id' => $user->id,
                'fcm_token' => $request->fcm_token,
            ],
            [
                'device_type' => $request->device_type ?? 'web',
                'updated_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'FCM token saved successfully',
            'data' => [
                'user_id' => $user->id,
            ]
        ]);
    }

    public function deleteFcmToken(Request $request)
    {
        $user = auth()->user();

        DB::table('fcm_tokens')
            ->where('user_id', $user->id)
            ->delete();

        return response()->json([
            'success' => true,
            'message' => 'FCM token deleted successfully'
        ]);
    }
}
```

---

## 7️⃣ Testing the Integration

### **Test Google Sign-In:**
1. Open: https://aqar.bdcbiz.com/test_auth_notifications.html
2. Click "Sign In with Google"
3. Check your Laravel logs to see the incoming request
4. Verify the response matches the expected format

### **Test FCM Token:**
1. After signing in, the app automatically sends the FCM token
2. Check your `fcm_tokens` table in the database
3. Verify the token is stored for the user

### **Test Sending Notification:**
1. Go to Firebase Console: https://console.firebase.google.com/project/realstate-4564d/notification/compose
2. Click "Send test message"
3. Paste the FCM token from your database
4. Send the notification
5. User should receive it on their device/browser

---

## 8️⃣ Quick Checklist

- [ ] `/api/login` endpoint handles `login_method: 'google'`
- [ ] Backend verifies Google ID token (optional but recommended)
- [ ] Backend creates/updates user with Google info
- [ ] Backend returns auth token in response
- [ ] `/api/fcm-token` endpoint saves FCM tokens
- [ ] `users` table has `google_id` column
- [ ] `fcm_tokens` table exists with proper schema
- [ ] Firebase Admin SDK is installed for sending notifications
- [ ] Test both features using the test page

---

## 📞 Need Help?

If you encounter any issues, check:
1. Laravel logs: `storage/logs/laravel.log`
2. Browser console: F12 → Console tab
3. Network tab: F12 → Network → Check API requests/responses
4. Database: Check if tokens are being saved

---

**🎉 That's it! Your backend should now be ready to handle both Google Sign-In and FCM notifications!**
