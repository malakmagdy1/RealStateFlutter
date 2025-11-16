# Backend Requirements: Pre-Login Device Management

## ⚠️ STATUS: NOT IMPLEMENTED (BY DESIGN)

**Decision: Pre-login device removal is NOT recommended for security reasons.**

**Reasoning:**
- Users without authentication should NOT be able to delete devices with just email/password
- This prevents potential security issues where an attacker with stolen credentials could remove all devices
- The proper flow is: User must login from an existing device → Remove old devices → Logout → Login from new device
- This maintains better security and prevents device hijacking

**Frontend Solution: Informational Dialog**
- Shows clear instructions on how to fix the issue
- Displays list of registered devices (informational only)
- Guides user to login from existing device to manage devices
- No deletion capability without proper authentication

---

## Problem Statement

Users encounter a **catch-22 authentication loop** when their device limit is reached:

1. User attempts to login → **403 Forbidden** (device limit reached)
2. User needs to remove a device → **401 Unauthorized** (requires authentication token)
3. User cannot get token → Cannot login (device limit still exceeded)

**Result**: User is permanently locked out until they contact support or login from an existing registered device.

## Current Behavior

### Login Flow (Device Limit Reached)
```
POST /api/login
{
  "email": "user@example.com",
  "password": "password123",
  "device_id": "web_1763295914154",
  "device_name": "Web Browser",
  "device_type": "web",
  "app_version": "1.0.0",
  "os_version": "Web"
}

Response: 403 Forbidden
{
  "success": false,
  "message": "Device limit reached. You have reached the maximum number of devices (5) for your plus subscription.",
  "message_ar": "تم الوصول إلى الحد الأقصى للأجهزة. لقد وصلت إلى الحد الأقصى (5) لاشتراكك plus.",
  "data": {
    "device_limit": 5,
    "devices_used": 5,
    "subscription_type": "plus",
    "devices": [
      {
        "id": 6,
        "user_id": 33,
        "device_id": "web_1763295914154",
        "device_name": "Web Browser",
        "device_type": "web",
        "app_version": "1.0.0",
        "os_version": "Web",
        "ip_address": "156.204.230.249",
        "last_active_at": "2025-11-16T13:15:29.000000Z",
        "created_at": "2025-11-16T13:15:29.000000Z",
        "updated_at": "2025-11-16T13:15:29.000000Z"
      },
      // ... more devices
    ]
  }
}
```

### Attempted Device Removal (Fails)
```
DELETE /api/devices/6
Headers:
  Authorization: Bearer [empty or invalid token]

Response: 401 Unauthorized
{
  "message": "Unauthenticated."
}
```

## ✅ Implemented Solution

### Unauthenticated Device Removal Endpoint

This endpoint allows device removal using email/password credentials instead of a token.

#### Endpoint Specification

**URL**: `DELETE /api/devices/remove-for-login`

**Request Headers**:
```
Content-Type: application/json
Accept: application/json
```

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "device_id": "web_1763299843458"
}
```

**Success Response** (200 OK):
```json
{
  "success": true,
  "message": "Device removed successfully",
  "message_ar": "تم حذف الجهاز بنجاح",
  "data": {
    "remaining_slots": 1,
    "device_limit": 5,
    "devices_used": 4
  }
}
```

**Error Responses**:

1. **Invalid Credentials** (401 Unauthorized):
```json
{
  "success": false,
  "message": "Invalid email or password",
  "message_ar": "البريد الإلكتروني أو كلمة المرور غير صحيحة"
}
```

2. **Device Not Found** (404 Not Found):
```json
{
  "success": false,
  "message": "Device not found",
  "message_ar": "الجهاز غير موجود"
}
```

3. **Device Belongs to Another User** (403 Forbidden):
```json
{
  "success": false,
  "message": "You don't have permission to remove this device",
  "message_ar": "ليس لديك صلاحية لحذف هذا الجهاز"
}
```

4. **Validation Error** (422 Unprocessable Entity):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": ["The email field is required."],
    "password": ["The password field is required."],
    "device_id": ["The device_id field is required."]
  }
}
```

#### Security Requirements

1. **Credential Validation**:
   - Verify email and password match an existing user
   - Use same password hashing as login endpoint
   - Rate limit attempts to prevent brute force attacks

2. **Authorization**:
   - Ensure the device_id belongs to the authenticated user
   - Prevent users from removing other users' devices

3. **Rate Limiting**:
   - Limit to 5 attempts per IP per 15 minutes
   - Lock account after 10 failed attempts in 1 hour

4. **Logging**:
   - Log all device removal attempts
   - Include: timestamp, IP address, email, device_id, success/failure

5. **Session Management**:
   - Do NOT create a session or return an auth token
   - This endpoint should only remove the device

#### Backend Implementation Checklist

- [x] Create new route: `DELETE /api/devices/remove-for-login` ✅
- [x] Create controller method: `DeviceController@removeForLogin` ✅
- [x] Add validation for email, password, and device_id ✅
- [x] Verify user credentials (email + password) ✅
- [x] Check device ownership (device belongs to authenticated user) ✅
- [x] Delete device from database ✅
- [x] Update device usage count ✅
- [x] Return success response with remaining slots ✅
- [ ] Add rate limiting middleware (Recommended)
- [ ] Add audit logging (Recommended)
- [ ] Add unit tests (Recommended)
- [ ] Add integration tests (Recommended)
- [ ] Update API documentation (Recommended)

---

### Option 2: Modify Login Endpoint (Alternative)

Add an optional `replace_device_id` parameter to the existing login endpoint.

#### Endpoint Specification

**URL**: `POST /api/login`

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "device_id": "web_1763295914154",
  "device_name": "Web Browser",
  "device_type": "web",
  "app_version": "1.0.0",
  "os_version": "Web",
  "replace_device_id": "6"  // Optional: auto-remove this device before login
}
```

**Success Response** (200 OK):
```json
{
  "success": true,
  "message": "Login successful. Old device removed.",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": { /* user object */ },
  "data": {
    "device_replaced": true,
    "old_device_id": "6",
    "new_device_id": "web_1763295914154"
  }
}
```

#### Backend Logic

1. Validate credentials
2. If `replace_device_id` is provided:
   - Verify it belongs to the user
   - Remove the old device
   - Register new device
   - Continue with normal login
3. If no `replace_device_id` and limit reached:
   - Return 403 with device list (current behavior)

---

## ✅ Frontend Changes (Implemented)

### Added Method: `removeDeviceWithCredentials`

Location: `lib/feature/auth/data/web_services/auth_web_services.dart`

```dart
Future<void> removeDeviceWithCredentials({
  required String email,
  required String password,
  required String deviceId,
}) async {
  // Calls: DELETE /devices/remove-for-login
  Response response = await dio.delete(
    '/devices/remove-for-login',
    data: {
      'email': email,
      'password': password,
      'device_id': deviceId,
    },
  );
}
```

### Updated Dialog: Device Limit Error

Location: `lib/feature/auth/presentation/screen/loginScreen.dart`

- Shows list of registered devices from 403 error response
- Allows user to select and remove a device
- Uses `removeDeviceWithCredentials` with login credentials
- Automatically retries login after successful removal
- Shows helpful error if endpoint not implemented (404)

---

## Testing Scenarios

### Test Case 1: Successful Device Removal
1. User has 5/5 devices registered
2. Attempts to login from new device → 403
3. Dialog shows 5 registered devices
4. User clicks delete on device #2
5. Backend validates credentials and removes device
6. User is shown success message
7. Login is automatically retried
8. User successfully logs in

### Test Case 2: Invalid Credentials
1. User attempts device removal
2. Email or password is incorrect
3. Backend returns 401
4. User sees error message
5. Device is NOT removed

### Test Case 3: Device Belongs to Another User
1. Attacker tries to remove victim's device
2. Provides valid credentials for own account
3. Provides device_id belonging to victim
4. Backend returns 403
5. Device is NOT removed

### Test Case 4: Rate Limiting
1. Attacker makes 10 removal attempts with wrong password
2. Backend blocks further attempts
3. Returns 429 Too Many Requests
4. Account is temporarily locked

---

## Migration Path

1. **Phase 1**: Implement backend endpoint (Option 1 recommended)
2. **Phase 2**: Test with frontend (already implemented)
3. **Phase 3**: Deploy to staging environment
4. **Phase 4**: Conduct security audit
5. **Phase 5**: Deploy to production
6. **Phase 6**: Monitor logs for abuse

---

## Security Considerations

⚠️ **Critical Security Notes**:

1. **Password Exposure Risk**: This endpoint accepts passwords in plain text over HTTPS. Ensure:
   - HTTPS is enforced (no HTTP)
   - TLS 1.2 or higher
   - Strong password hashing (bcrypt, argon2)

2. **Brute Force Protection**:
   - Rate limit per IP address
   - Rate limit per email address
   - Implement CAPTCHA after 3 failed attempts
   - Lock account after 10 failed attempts

3. **Audit Trail**:
   - Log all device removal attempts
   - Include: IP, email, device_id, timestamp, result
   - Alert on suspicious patterns

4. **Device Ownership**:
   - ALWAYS verify device belongs to requesting user
   - Never trust device_id from client without verification

---

## API Documentation Template

### POST /devices/remove-for-login

Remove a device using email/password credentials (pre-login).

**Authentication**: None (uses email/password in body)

**Rate Limiting**: 5 requests per 15 minutes per IP

**Request**:
```json
{
  "email": "string (required, email format)",
  "password": "string (required, min 6 chars)",
  "device_id": "string (required)"
}
```

**Responses**:
- `200 OK`: Device removed successfully
- `401 Unauthorized`: Invalid credentials
- `403 Forbidden`: Device belongs to another user
- `404 Not Found`: Device not found
- `422 Unprocessable Entity`: Validation error
- `429 Too Many Requests`: Rate limit exceeded

---

---

## ✅ Final Solution Implemented

### Decision: Informational Dialog Only

After careful consideration, we decided **NOT** to implement pre-login device removal for the following security reasons:

#### Security Concerns:
1. **Credential Theft Risk**: An attacker with stolen email/password could remove all legitimate devices
2. **Session Hijacking**: Allows unauthorized device management without proper authentication
3. **Account Takeover**: Makes it easier for attackers to lock out legitimate users

#### User Experience Solution:
Instead of allowing pre-login deletion, we implemented an **informational dialog** that:

1. ✅ Clearly explains the situation
2. ✅ Shows step-by-step instructions:
   - Login from one of your existing devices
   - Go to Profile → Device Management
   - Remove old or unused devices
   - Come back and login from this device
3. ✅ Displays list of registered devices (read-only)
4. ✅ Provides "Upgrade Plan" button for premium tiers

### Implementation Details:

**Files Modified:**
- `lib/feature/auth/presentation/screen/loginScreen.dart` - Mobile login dialog
- `lib/feature_web/auth/presentation/web_login_screen.dart` - Web login dialog
- Removed: `removeDeviceWithCredentials()` method (not needed)

**User Flow:**
```
1. User attempts login from new device
   ↓
2. Backend returns 403 with device list
   ↓
3. Frontend shows informational dialog:
   - Error message explaining device limit
   - List of registered devices (informational)
   - Clear instructions on how to fix
   - Upgrade button
   ↓
4. User must:
   a. Login from existing device
   b. Remove old devices in Profile
   c. Return and login from new device
```

### Benefits:
- ✅ **Better Security**: Requires proper authentication for device management
- ✅ **Clear UX**: Step-by-step instructions guide the user
- ✅ **Prevents Abuse**: Can't delete devices without being logged in
- ✅ **Transparency**: Shows which devices are registered
- ✅ **Upsell Opportunity**: Promotes premium plans with more device slots

---

## Conclusion

No backend changes required. The current implementation is secure and user-friendly. Device management requires proper authentication via the existing endpoints:
- `GET /api/devices` - View devices (requires token)
- `DELETE /api/devices/{device_id}` - Remove device (requires token)
