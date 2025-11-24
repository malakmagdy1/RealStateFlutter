# Security Implementation Guide

This document outlines the security measures implemented in the Real Estate application to protect against common web vulnerabilities and attacks.

## 🔒 Security Features Implemented

### 1. Content Security Policy (CSP)

**Location**: `web/index.html`

The application implements strict CSP headers to prevent XSS attacks:

```html
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self' 'unsafe-inline' 'unsafe-eval' https://accounts.google.com ...;
  style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
  img-src 'self' https: data: blob:;
  connect-src 'self' https://api.aqarapp.co ...;
  object-src 'none';
  frame-ancestors 'none';
  upgrade-insecure-requests;
">
```

**Protection Against**:
- Cross-Site Scripting (XSS)
- Code injection attacks
- Unauthorized resource loading
- Clickjacking

### 2. Security Headers

**Location**: `web/index.html`

Additional security headers implemented:

- `X-Content-Type-Options: nosniff` - Prevents MIME type sniffing
- `X-Frame-Options: DENY` - Prevents clickjacking
- `X-XSS-Protection: 1; mode=block` - Enables browser XSS filter
- `Referrer-Policy: strict-origin-when-cross-origin` - Controls referrer information
- `Permissions-Policy` - Restricts browser features

### 3. Secure Token Storage

**Location**: `lib/core/security/secure_storage.dart`

Implements encrypted storage for sensitive data:

```dart
// Save token securely
await SecureStorage.saveToken(token);

// Retrieve token
final token = await SecureStorage.getToken();

// Clear all secure data on logout
await SecureStorage.clearAll();
```

**Features**:
- SHA-256 based encryption
- Data integrity verification
- Token validation
- Secure cleanup on logout

**Usage Example**:
```dart
// In your authentication service
class AuthService {
  Future<void> login(String email, String password) async {
    final response = await api.login(email, password);

    // Save token securely
    await SecureStorage.saveToken(response.token);
    await SecureStorage.saveRefreshToken(response.refreshToken);
    await SecureStorage.saveUserId(response.userId);
  }

  Future<void> logout() async {
    // Clear all secure data
    await SecureStorage.clearAll();
  }
}
```

### 4. Input Validation & Sanitization

**Location**: `lib/core/security/input_validator.dart`

Comprehensive input validation to prevent injection attacks:

```dart
// Email validation
final error = InputValidator.validateEmail(email);
if (error != null) {
  // Handle validation error
}

// Sanitize text input
final safe = InputValidator.sanitizeText(userInput);

// Validate search queries
final searchError = InputValidator.validateSearchQuery(searchTerm);

// Sanitize API payload
final safePayload = InputValidator.sanitizeApiPayload(data);
```

**Protection Against**:
- SQL Injection
- XSS attacks
- Command injection
- Path traversal
- HTML injection

**Usage Example**:
```dart
class LoginScreen extends StatelessWidget {
  void _handleLogin() {
    // Validate inputs
    final emailError = InputValidator.validateEmail(_emailController.text);
    final passwordError = InputValidator.validatePassword(_passwordController.text);

    if (emailError != null || passwordError != null) {
      // Show validation errors
      return;
    }

    // Proceed with login
    authService.login(_emailController.text, _passwordController.text);
  }
}
```

### 5. Rate Limiting

**Location**: `lib/core/security/rate_limiter.dart`

Prevents abuse and DOS attacks:

```dart
// Check if request is allowed
if (!RateLimiter.isRequestAllowed('search')) {
  // Show rate limit error
  return;
}

// Record failed login
RateLimiter.recordFailedLogin(email);

// Check if user is blocked
if (RateLimiter.isLoginBlocked(email)) {
  final remaining = RateLimiter.getRemainingBlockTime(email);
  // Show block message
}

// Record successful login
RateLimiter.recordSuccessfulLogin(email);
```

**Features**:
- Per-endpoint rate limiting
- Failed login attempt tracking
- Automatic user blocking
- Configurable limits

**Limits**:
- 60 requests per minute per endpoint
- 15 requests per 10 seconds per endpoint
- 5 failed login attempts before blocking
- 15-minute block duration

**Usage Example**:
```dart
class SearchService {
  Future<List<Property>> search(String query) async {
    // Check rate limit
    if (!RateLimiter.isRequestAllowed('search')) {
      throw Exception('Too many search requests. Please wait a moment.');
    }

    // Proceed with search
    return await api.search(query);
  }
}

class AuthService {
  Future<void> login(String email, String password) async {
    // Check if user is blocked
    if (RateLimiter.isLoginBlocked(email)) {
      final remaining = RateLimiter.getRemainingBlockTime(email);
      throw Exception('Too many failed login attempts. Try again in ${remaining?.inMinutes} minutes.');
    }

    try {
      final response = await api.login(email, password);
      // Success - clear failed attempts
      RateLimiter.recordSuccessfulLogin(email);
    } catch (e) {
      // Failed - record attempt
      RateLimiter.recordFailedLogin(email);
      rethrow;
    }
  }
}
```

### 6. HTTPS Enforcement

**Location**: `lib/core/security/security_config.dart`

Enforces secure connections in production:

```dart
// Initialize security
SecurityConfig.enforceHttps();

// Get secure headers
final headers = SecurityConfig.getSecureHeaders(token: authToken);

// Validate URL
if (!SecurityConfig.isSecureUrl(apiUrl)) {
  // Block insecure request
}
```

**Features**:
- HTTPS enforcement in production
- Secure header generation
- URL validation
- CORS configuration
- Session management

### 7. SQL Injection Prevention

**Built into Input Validator**

All database queries use parameterized statements and input validation:

- Detects SQL keywords and patterns
- Sanitizes all user input
- Validates data types
- Prevents command injection

### 8. CORS Configuration

**Location**: `lib/core/security/security_config.dart`

Proper CORS configuration for API calls:

```dart
final corsHeaders = SecurityConfig.getCorsHeaders();
```

## 📋 Implementation Checklist

### Frontend Security (Completed ✅)

- [x] Content Security Policy headers
- [x] XSS protection headers
- [x] Clickjacking prevention (X-Frame-Options)
- [x] MIME type sniffing prevention
- [x] Input validation and sanitization
- [x] Rate limiting
- [x] Secure token storage
- [x] HTTPS enforcement
- [x] SQL injection prevention
- [x] CORS configuration

### Backend Requirements (For Backend Team)

Backend developers should implement:

1. **Server-Side Validation**
   - Validate all inputs on the server
   - Don't trust client-side validation alone

2. **Rate Limiting**
   - Implement server-side rate limiting
   - Use tools like Nginx or middleware

3. **Authentication & Authorization**
   - Use JWT with short expiration times
   - Implement refresh token rotation
   - Validate tokens on every request

4. **Database Security**
   - Use parameterized queries
   - Implement proper access controls
   - Regular security audits

5. **HTTPS/TLS**
   - Enforce HTTPS for all endpoints
   - Use valid SSL certificates
   - Implement HSTS headers

6. **Logging & Monitoring**
   - Log security events
   - Monitor for suspicious activity
   - Set up alerts for security incidents

7. **API Security**
   - Implement API key rotation
   - Use CORS properly
   - Rate limit API endpoints

## 🚀 Usage Guidelines

### For Developers

1. **Always Validate Input**
   ```dart
   // Bad ❌
   final result = await api.search(userInput);

   // Good ✅
   final error = InputValidator.validateSearchQuery(userInput);
   if (error != null) return;
   final safe = InputValidator.sanitizeText(userInput);
   final result = await api.search(safe);
   ```

2. **Use Secure Storage**
   ```dart
   // Bad ❌
   await prefs.setString('token', token);

   // Good ✅
   await SecureStorage.saveToken(token);
   ```

3. **Check Rate Limits**
   ```dart
   // Good ✅
   if (!RateLimiter.isRequestAllowed(endpoint)) {
     showError('Too many requests');
     return;
   }
   ```

4. **Sanitize API Payloads**
   ```dart
   // Good ✅
   final safeData = InputValidator.sanitizeApiPayload(formData);
   await api.post(endpoint, safeData);
   ```

## 🔍 Security Testing

### Manual Testing

1. **XSS Testing**
   - Try entering `<script>alert('XSS')</script>` in input fields
   - Should be sanitized and not execute

2. **SQL Injection Testing**
   - Try entering `' OR '1'='1` in search
   - Should be blocked by validator

3. **Rate Limiting Testing**
   - Make rapid requests to an endpoint
   - Should be blocked after limits

4. **HTTPS Testing**
   - Try accessing via HTTP in production
   - Should redirect to HTTPS

### Automated Testing

```dart
void main() {
  group('Security Tests', () {
    test('Email validation blocks XSS', () {
      final result = InputValidator.validateEmail('<script>alert(1)</script>@test.com');
      expect(result, isNotNull);
    });

    test('Rate limiter blocks excessive requests', () {
      for (int i = 0; i < 61; i++) {
        RateLimiter.isRequestAllowed('test');
      }
      expect(RateLimiter.isRequestAllowed('test'), false);
    });

    test('Token validation detects suspicious tokens', () {
      expect(SecureStorage.isValidTokenFormat('<script>'), false);
    });
  });
}
```

## 📊 Security Monitoring

Monitor these metrics:

1. **Failed Login Attempts**
   - Track using `RateLimiter.getFailedLoginAttempts()`
   - Alert on suspicious patterns

2. **Rate Limit Violations**
   - Monitor using `RateLimiter.getStatistics()`
   - Identify potential DOS attacks

3. **Validation Failures**
   - Log validation errors
   - Identify attack patterns

4. **Security Events**
   - Use `SecurityConfig.logSecurityEvent()`
   - Track security incidents

## ⚠️ Important Notes

1. **Never Store Sensitive Data in localStorage without encryption**
2. **Always validate input on both client and server**
3. **Keep security packages updated**
4. **Regular security audits**
5. **Follow OWASP security guidelines**

## 🔄 Regular Maintenance

- [ ] Update CSP headers when adding new domains
- [ ] Review rate limiting thresholds
- [ ] Update security packages regularly
- [ ] Audit third-party dependencies
- [ ] Review and update validation rules
- [ ] Monitor security logs

## 📚 Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Flutter Security Best Practices](https://flutter.dev/docs/deployment/web)
- [CSP Guide](https://content-security-policy.com/)
- [Web Security Cheat Sheet](https://cheatsheetseries.owasp.org/)

## 🆘 Security Incident Response

If you discover a security vulnerability:

1. **Do NOT** disclose publicly
2. Document the issue in detail
3. Report to security team immediately
4. Follow responsible disclosure practices

---

**Last Updated**: 2025-01-20
**Version**: 1.0.0
**Status**: Production Ready ✅
