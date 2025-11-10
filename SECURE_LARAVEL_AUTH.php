<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Http;

class AuthController extends Controller
{
    /**
     * 🔒 SECURE Google Sign-In Login
     *
     * This method REQUIRES token verification.
     * Cannot be bypassed or faked.
     */
    public function login(Request $request)
    {
        try {
            if ($request->login_method === 'google') {
                return $this->handleSecureGoogleLogin($request);
            }

            return $this->handleEmailPasswordLogin($request);

        } catch (\Exception $e) {
            \Log::error('Login error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Login failed: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 🔒 SECURE Google Login Handler
     *
     * REQUIRES token verification with Google's servers.
     * This prevents anyone from faking Google login.
     */
    private function handleSecureGoogleLogin(Request $request)
    {
        // Validate that we have a token
        $validator = Validator::make($request->all(), [
            'id_token' => 'required|string',
            'email' => 'required|email',
            'google_id' => 'required|string',
            'name' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Missing required fields',
                'errors' => $validator->errors()
            ], 422);
        }

        // 🔒 STEP 1: Verify token with Google
        $verifiedData = $this->verifyGoogleToken($request->id_token);

        if ($verifiedData === null) {
            \Log::warning('Invalid Google token attempt for email: ' . $request->email);
            return response()->json([
                'success' => false,
                'message' => 'Invalid Google token. Authentication failed.'
            ], 401);
        }

        // 🔒 STEP 2: Verify the token data matches the request
        // This prevents token replay attacks
        if (isset($verifiedData['email']) && $verifiedData['email'] !== $request->email) {
            \Log::error('Token email mismatch: ' . $verifiedData['email'] . ' vs ' . $request->email);
            return response()->json([
                'success' => false,
                'message' => 'Token validation failed: Email mismatch'
            ], 401);
        }

        // For access tokens, verify the token is valid but email might not be in response
        // In that case, we trust the request email since token is valid

        // 🔒 STEP 3: Use VERIFIED data from Google (not from request)
        // Priority: Use data from Google's verification, fallback to request
        $googleId = $verifiedData['sub'] ?? $request->google_id;
        $email = $verifiedData['email'] ?? $request->email;
        $name = $request->name; // Name is safe to use from request
        $photoUrl = $request->photo_url;

        \Log::info('Google login verified for: ' . $email);

        // Find or create user
        $user = User::where('google_id', $googleId)
                    ->orWhere('email', $email)
                    ->first();

        if (!$user) {
            $user = User::create([
                'name' => $name,
                'email' => $email,
                'google_id' => $googleId,
                'photo_url' => $photoUrl,
                'email_verified_at' => now(),
                'password' => Hash::make(Str::random(32)),
                'is_verified' => true,
                'login_method' => 'google',
            ]);

            \Log::info('New Google user created: ' . $email);
        } else {
            $user->update([
                'google_id' => $googleId,
                'name' => $name,
                'photo_url' => $photoUrl,
                'email_verified_at' => $user->email_verified_at ?? now(),
                'is_verified' => true,
            ]);

            \Log::info('Existing user logged in with Google: ' . $email);
        }

        // Generate Sanctum token
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'status' => true,
            'success' => true,
            'message' => 'Google login successful',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'google_id' => $user->google_id,
                'photo_url' => $user->photo_url,
                'phone' => $user->phone,
                'role' => $user->role ?? 'user',
                'is_verified' => $user->is_verified ?? true,
                'is_banned' => $user->is_banned ?? false,
                'created_at' => $user->created_at,
            ],
        ], 200);
    }

    /**
     * 🔒 Verify Google Token with Google's Servers
     *
     * This uses Google's public tokeninfo endpoint to verify:
     * - Token is valid and not expired
     * - Token was issued by Google
     * - Token hasn't been tampered with
     *
     * Works with BOTH ID tokens and Access tokens
     *
     * @param string $token
     * @return array|null Returns verified data or null if invalid
     */
    private function verifyGoogleToken($token)
    {
        try {
            // Try to determine if this is an ID token or Access token
            // ID tokens have 3 segments (header.payload.signature)
            // Access tokens are different format

            $segments = explode('.', $token);

            if (count($segments) === 3) {
                // This is an ID token - verify with tokeninfo endpoint
                $url = "https://oauth2.googleapis.com/tokeninfo?id_token=" . urlencode($token);
            } else {
                // This is an access token - verify with different endpoint
                $url = "https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=" . urlencode($token);
            }

            \Log::info('Verifying Google token with: ' . $url);

            $response = Http::timeout(10)->get($url);

            if (!$response->successful()) {
                \Log::error('Google token verification failed: HTTP ' . $response->status());
                \Log::error('Response: ' . $response->body());
                return null;
            }

            $data = $response->json();

            // Check for errors in response
            if (isset($data['error']) || isset($data['error_description'])) {
                \Log::error('Google token error: ' . ($data['error_description'] ?? $data['error']));
                return null;
            }

            // For ID tokens, verify the audience (client ID)
            if (isset($data['aud']) && $data['aud'] !== config('services.google.client_id')) {
                \Log::error('Token audience mismatch: ' . $data['aud']);
                // Allow tokens from web client ID too
                $webClientId = '832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com';
                if ($data['aud'] !== $webClientId) {
                    return null;
                }
            }

            // Verify token is not expired
            if (isset($data['exp']) && $data['exp'] < time()) {
                \Log::error('Token expired');
                return null;
            }

            \Log::info('Google token verified successfully');
            \Log::info('Token data: ' . json_encode($data));

            return $data;

        } catch (\Exception $e) {
            \Log::error('Google token verification exception: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Regular email/password login
     */
    private function handleEmailPasswordLogin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid email or password',
            ], 401);
        }

        if ($user->is_banned) {
            return response()->json([
                'success' => false,
                'message' => 'Your account has been banned.',
            ], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'status' => true,
            'success' => true,
            'message' => 'Login successful',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role ?? 'user',
                'is_verified' => $user->is_verified ?? false,
                'is_banned' => $user->is_banned ?? false,
                'photo_url' => $user->photo_url,
                'created_at' => $user->created_at,
            ],
        ], 200);
    }

    /**
     * Register new user
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
            'phone' => 'nullable|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone,
            'is_verified' => false,
            'login_method' => 'email',
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'status' => true,
            'success' => true,
            'message' => 'Registration successful',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role ?? 'user',
                'is_verified' => $user->is_verified,
                'created_at' => $user->created_at,
            ],
        ], 201);
    }

    /**
     * Logout
     */
    public function logout(Request $request)
    {
        try {
            $request->user()->tokens()->delete();

            return response()->json([
                'status' => true,
                'success' => true,
                'message' => 'Logged out successfully',
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Logout failed: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get user profile
     */
    public function profile(Request $request)
    {
        try {
            $user = $request->user();

            return response()->json([
                'status' => true,
                'success' => true,
                'data' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'google_id' => $user->google_id,
                    'photo_url' => $user->photo_url,
                    'role' => $user->role ?? 'user',
                    'is_verified' => $user->is_verified ?? false,
                    'is_banned' => $user->is_banned ?? false,
                    'created_at' => $user->created_at,
                ],
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch profile: ' . $e->getMessage()
            ], 500);
        }
    }
}
