import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/core/security/input_validator.dart';
import 'package:real/core/security/rate_limiter.dart';
import 'package:real/core/security/secure_storage.dart';
import 'package:real/feature/auth/data/models/login_request.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/login_event.dart';
import 'package:real/feature/auth/presentation/bloc/login_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_event.dart';
import 'package:real/feature/auth/presentation/screen/SignupScreen.dart';
import 'package:real/feature/auth/presentation/screen/forgot_password_flow_screen.dart';
import 'package:real/feature/home/presentation/CustomNav.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_event.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_state.dart';
import 'package:real/feature/subscription/presentation/screens/subscription_plans_screen.dart';
import 'package:real/feature/auth/presentation/screen/device_management_screen.dart';
import 'package:real/feature/auth/data/web_services/auth_web_services.dart';
import 'package:intl/intl.dart';

import '../../../../core/widget/button/authButton.dart';
import '../widget/textFormField.dart';
import '../widget/authToggle.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';

class LoginScreen extends StatefulWidget {
  static String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // iOS Client ID from GoogleService-Info.plist
  static const String _iosClientId = '832433207149-nj5vittkhvrv78dhh5rtjndv5n365rud.apps.googleusercontent.com';
  // Web Client ID (also used as serverClientId for backend verification)
  static const String _webClientId = '832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com';

  static String? _getGoogleClientId() {
    if (kIsWeb) return _webClientId;
    try {
      if (Platform.isIOS) return _iosClientId;
    } catch (_) {}
    return null; // Android uses google-services.json
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _getGoogleClientId(),
    // serverClientId is needed to get an ID token that the backend can verify
    // It should be the Web Client ID since backend uses it for verification
    serverClientId: _webClientId,
    scopes: ['email', 'profile', 'openid'],
  );

  GoogleSignInAccount? _user;

  Future<void> _handleSignIn() async {
    try {
      // Sign out first to force account picker to show
      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();
      setState(() => _user = account);

      if (account != null) {
        print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
        print('GOOGLE SIGN-IN SUCCESS!');
        print('User: ${account.displayName}');
        print('Email: ${account.email}');
        print('ID: ${account.id}');
        print('Sending to backend for authentication...');

        // Send Google account info to backend and get proper token
        try {
          // Get the authentication object to extract the ID token or access token
          final GoogleSignInAuthentication auth = await account.authentication;
          final String? idToken = auth.idToken;
          final String? accessToken = auth.accessToken;

          print('ID Token obtained: ${idToken != null ? "YES" : "NO"}');
          print('Access Token obtained: ${accessToken != null ? "YES" : "NO"}');

          // On web, use access token if ID token is not available
          final String? tokenToSend = idToken ?? accessToken;

          if (tokenToSend != null) {
            print('Token length: ${tokenToSend.length}');
            print('Using ${idToken != null ? "ID Token" : "Access Token"}');
          }

          if (tokenToSend == null) {
            throw Exception('Failed to get authentication token from Google');
          }

          final repository = context.read<LoginBloc>().repository;
          final response = await repository.googleLogin(
            googleId: account.id,
            email: account.email,
            name: account.displayName ?? '',
            photoUrl: account.photoUrl,
            idToken: tokenToSend,
          );

          // Security: Validate token before saving
          final receivedToken = response.token ?? '';
          if (!SecureStorage.isValidTokenFormat(receivedToken)) {
            print('[SECURITY] Invalid token format from Google login');
            throw Exception('Invalid authentication response');
          }

          // Security: Save token securely (encrypted)
          await SecureStorage.saveToken(receivedToken);

          // Also save to old storage for backward compatibility
          await CasheNetwork.insertToCashe(
            key: "token",
            value: receivedToken,
          );

          // Save user_id
          if (response.user.id != null) {
            await SecureStorage.saveUserId(response.user.id!);
            await CasheNetwork.insertToCashe(
              key: "user_id",
              value: response.user.id.toString(),
            );
            // IMPORTANT: Update global userId variable
            userId = response.user.id.toString();
            print('User ID SAVED: ${response.user.id}');
            print('Global userId variable updated: $userId');
          }

          // IMPORTANT: Update global token variable
          token = receivedToken;

          print('🔒 Backend Token SAVED securely (encrypted)');
          print('Token length: ${receivedToken.length}');
          print('Global token variable updated');
          print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

          // SECURITY CHECKS: Only allow buyers who are verified and not banned
          final user = response.user;

          // Check 1: Only buyers allowed
          if (user.role.toLowerCase() != 'buyer') {
            MessageHelper.showError(context, 'Access denied. Only buyers can access this app.');
            await SecureStorage.clearAll();
            await CasheNetwork.deletecasheItem(key: "token");
            await CasheNetwork.deletecasheItem(key: "user_id");
            token = null;
            userId = null;
            return;
          }

          // Check 2: User must be verified
          if (!user.isVerified) {
            MessageHelper.showMessage(
              context: context,
              message: 'Please verify your email address to continue.',
              isSuccess: false,
            );
            await SecureStorage.clearAll();
            await CasheNetwork.deletecasheItem(key: "token");
            await CasheNetwork.deletecasheItem(key: "user_id");
            token = null;
            userId = null;
            return;
          }

          // Check 3: User must not be banned
          if (user.isBanned) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 28),
                    SizedBox(width: 8),
                    Text('Account Suspended'),
                  ],
                ),
                content: Text(
                  'Your account has been suspended. Please contact support for assistance.',
                  style: TextStyle(fontSize: 15),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );
            await SecureStorage.clearAll();
            await CasheNetwork.deletecasheItem(key: "token");
            await CasheNetwork.deletecasheItem(key: "user_id");
            token = null;
            userId = null;
            return;
          }

          // All checks passed - proceed with login
          // Refresh user data with new token
          context.read<UserBloc>().add(RefreshUserEvent());

          // Check subscription status after Google login
          _checkSubscriptionStatus(context);
        } catch (backendError) {
          print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
          print('BACKEND ERROR: $backendError');
          print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

          // Show prominent error dialog on screen
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Expanded(child: Text('Backend Authentication Failed')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error Details:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: SelectableText(
                      '$backendError',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '📝 Note: The backend needs to be updated to accept ${kIsWeb ? "access tokens from web" : "ID tokens from mobile"}.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );

          // Also show error message for quick reference
          MessageHelper.showError(context, 'Backend authentication failed - see error dialog');
        }
      }
    } catch (error) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('GOOGLE SIGN-IN ERROR: $error');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      MessageHelper.showError(context, 'Sign-in error: $error');
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    await CasheNetwork.deletecasheItem(key: "token");
    setState(() => _user = null);
  }

  // Apple Sign-In Handler
  Future<void> _handleAppleSignIn() async {
    try {
      // Check if Apple Sign In is available (iOS 13+, macOS 10.15+)
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        MessageHelper.showError(
          context,
          'Apple Sign-In is not available on this device',
        );
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('APPLE SIGN-IN SUCCESS!');
      print('User ID: ${credential.userIdentifier}');
      print('Email: ${credential.email}');
      print('Name: ${credential.givenName} ${credential.familyName}');
      print('Sending to backend for authentication...');

      // Apple only returns email and name on first sign-in
      // On subsequent sign-ins, these may be null
      final String email = credential.email ?? '';
      final String name = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      final String identityToken = credential.identityToken ?? '';
      final String authorizationCode = credential.authorizationCode;
      final String appleId = credential.userIdentifier ?? '';

      if (appleId.isEmpty) {
        throw Exception('Failed to get Apple user identifier');
      }

      if (identityToken.isEmpty) {
        throw Exception('Failed to get Apple identity token');
      }

      print('Identity Token length: ${identityToken.length}');
      print('Authorization Code length: ${authorizationCode.length}');

      // Send to backend
      final repository = context.read<LoginBloc>().repository;
      final response = await repository.appleLogin(
        appleId: appleId,
        email: email,
        name: name,
        identityToken: identityToken,
        authorizationCode: authorizationCode,
      );

      // Security: Validate token before saving
      final receivedToken = response.token ?? '';
      if (!SecureStorage.isValidTokenFormat(receivedToken)) {
        print('[SECURITY] Invalid token format from Apple login');
        throw Exception('Invalid authentication response');
      }

      // Security: Save token securely (encrypted)
      await SecureStorage.saveToken(receivedToken);

      // Also save to old storage for backward compatibility
      await CasheNetwork.insertToCashe(
        key: "token",
        value: receivedToken,
      );

      // Save user_id
      if (response.user.id != null) {
        await SecureStorage.saveUserId(response.user.id!);
        await CasheNetwork.insertToCashe(
          key: "user_id",
          value: response.user.id.toString(),
        );
        // IMPORTANT: Update global userId variable
        userId = response.user.id.toString();
        print('User ID SAVED: ${response.user.id}');
        print('Global userId variable updated: $userId');
      }

      // IMPORTANT: Update global token variable
      token = receivedToken;

      print('Backend Token SAVED securely (encrypted)');
      print('Token length: ${receivedToken.length}');
      print('Global token variable updated');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      // SECURITY CHECKS: Only allow buyers who are verified and not banned
      final user = response.user;

      // Check 1: Only buyers allowed
      if (user.role.toLowerCase() != 'buyer') {
        MessageHelper.showError(context, 'Access denied. Only buyers can access this app.');
        await SecureStorage.clearAll();
        await CasheNetwork.deletecasheItem(key: "token");
        await CasheNetwork.deletecasheItem(key: "user_id");
        token = null;
        userId = null;
        return;
      }

      // Check 2: User must be verified
      if (!user.isVerified) {
        MessageHelper.showMessage(
          context: context,
          message: 'Please verify your email address to continue.',
          isSuccess: false,
        );
        await SecureStorage.clearAll();
        await CasheNetwork.deletecasheItem(key: "token");
        await CasheNetwork.deletecasheItem(key: "user_id");
        token = null;
        userId = null;
        return;
      }

      // Check 3: User must not be banned
      if (user.isBanned) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Account Suspended'),
              ],
            ),
            content: Text(
              'Your account has been suspended. Please contact support for assistance.',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
        await SecureStorage.clearAll();
        await CasheNetwork.deletecasheItem(key: "token");
        await CasheNetwork.deletecasheItem(key: "user_id");
        token = null;
        userId = null;
        return;
      }

      // All checks passed - proceed with login
      // Refresh user data with new token
      context.read<UserBloc>().add(RefreshUserEvent());

      // Check subscription status after Apple login
      _checkSubscriptionStatus(context);
    } on SignInWithAppleAuthorizationException catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('APPLE SIGN-IN AUTHORIZATION ERROR: ${e.code} - ${e.message}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      // Don't show error if user cancelled
      if (e.code == AuthorizationErrorCode.canceled) {
        return;
      }

      MessageHelper.showError(context, 'Apple Sign-In failed: ${e.message}');
    } catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('APPLE SIGN-IN ERROR: $e');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('Apple Sign-In Failed')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error Details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: SelectableText(
                  '$e',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.red[900],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    }
  }

  // Check subscription status after login
  void _checkSubscriptionStatus(BuildContext context) {
    context.read<SubscriptionBloc>().add(LoadSubscriptionStatusEvent());

    // Show subscription dialog after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      _showSubscriptionDialog(context);
    });
  }

  void _showSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) {
          if (state is SubscriptionLoading) {
            return AlertDialog(
              content: Row(
                children: [
                  CustomLoadingDots(size: 40),
                  SizedBox(width: 20),
                  Text('Checking subscription...'),
                ],
              ),
            );
          }

          if (state is SubscriptionStatusLoaded) {
            final status = state.status;

            // If user already has active subscription, just navigate to home
            if (status.hasActiveSubscription) {
              Future.microtask(() {
                Navigator.of(dialogContext).pop();
                Navigator.pushReplacementNamed(context, CustomNav.routeName);
              });
              return SizedBox.shrink();
            }
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[800]!,
                      Colors.grey[700]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(
                        Icons.stars_rounded,
                        size: 150,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.rocket_launch,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: 20),

                          // Title
                          Text(
                            'Unlock Premium Features',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 12),

                          // Subtitle/Description
                          Text(
                            'Get unlimited searches and access to exclusive property listings',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),

                          // Features list
                          ...[
                            'Unlimited property searches',
                            'Advanced filters & sorting',
                            'Priority customer support',
                            'Exclusive premium listings',
                          ].map((feature) => Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green[300],
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.95),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),

                          SizedBox(height: 24),

                          // Buttons
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.of(dialogContext).pop();
                                    await Navigator.pushNamed(
                                      context,
                                      SubscriptionPlansScreen.routeName,
                                    );
                                    Navigator.pushReplacementNamed(context, CustomNav.routeName);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.grey[800],
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'View Plans',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: 12),

                              TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  Navigator.pushReplacementNamed(context, CustomNav.routeName);
                                },
                                child: Text(
                                  'Maybe Later',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Error or other states - just navigate to home
          return AlertDialog(
            content: Text('Unable to load subscription info'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.pushReplacementNamed(context, CustomNav.routeName);
                },
                child: Text('Continue'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeviceLimitDialog(BuildContext context, String message, List<Map<String, dynamic>> devices) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Device Limit Reached',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 15, height: 1.4),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'How to fix this:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Login from one of your existing devices',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2. Go to Profile → Device Management',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '3. Remove old or unused devices',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '4. Come back and login from this device',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              if (devices.isNotEmpty) ...[
                Text(
                  'Your registered devices:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyText,
                  ),
                ),
                SizedBox(height: 12),
                ...devices.take(5).map((device) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getDeviceIcon(device['device_type']),
                          color: AppColors.mainColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device['device_name'] ?? 'Unknown Device',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                device['os_version'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyText,
                                ),
                              ),
                              if (device['last_active'] != null || device['last_active_at'] != null)
                                Text(
                                  'Last: ${_formatDeviceDate(device['last_active'] ?? device['last_active_at'])}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.greyText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('OK'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(context, SubscriptionPlansScreen.routeName);
            },
            icon: Icon(Icons.workspace_premium, size: 18),
            label: Text('Upgrade Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String? deviceType) {
    switch (deviceType?.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.web;
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.laptop_mac;
      default:
        return Icons.devices;
    }
  }

  String _formatDeviceDate(String? dateStr) {
    if (dateStr == null) return 'Never';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22.0),
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              // SECURITY CHECKS: Only allow buyers who are verified and not banned
              final user = state.response.user;

              // Check 1: Only buyers allowed
              if (user.role.toLowerCase() != 'buyer') {
                MessageHelper.showError(context, 'Access denied. Only buyers can access this app.');
                // Clear token and logout
                CasheNetwork.deletecasheItem(key: "token");
                CasheNetwork.deletecasheItem(key: "user_id");
                token = null;
                userId = null;
                return;
              }

              // Check 2: User must be verified
              if (!user.isVerified) {
                MessageHelper.showMessage(
                  context: context,
                  message: 'Please verify your email address to continue.',
                  isSuccess: false,
                );
                // Clear token and logout
                CasheNetwork.deletecasheItem(key: "token");
                CasheNetwork.deletecasheItem(key: "user_id");
                token = null;
                userId = null;
                return;
              }

              // Check 3: User must not be banned
              if (user.isBanned) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red, size: 28),
                        SizedBox(width: 8),
                        Text('Account Suspended'),
                      ],
                    ),
                    content: Text(
                      'Your account has been suspended. Please contact support for assistance.',
                      style: TextStyle(fontSize: 15),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
                // Clear token and logout
                CasheNetwork.deletecasheItem(key: "token");
                CasheNetwork.deletecasheItem(key: "user_id");
                token = null;
                userId = null;
                return;
              }

              // All checks passed - proceed with login
              MessageHelper.showSuccess(context, state.response.message);
              // Refresh user data with new token
              context.read<UserBloc>().add(RefreshUserEvent());

              // Reload favorites with the new token-specific key
              context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
              context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());

              // Check subscription status after login
              _checkSubscriptionStatus(context);
            } else if (state is LoginDeviceLimitError) {
              // Show device limit dialog
              _showDeviceLimitDialog(context, state.message, state.devices);
            } else if (state is LoginError) {
              MessageHelper.showError(context, state.message);
            }
          },
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Form(key: _formKey,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                SizedBox(height: 20),
                AuthToggle(
                  isSignUp: false,
                  onSignUpPressed: () {
                    Navigator.pushReplacementNamed(context, SignUpScreen.routeName);
                  },
                  onLoginPressed: () {},
                ),
                SizedBox(height: 20),
                CustomText16("Email",bold: true,color: AppColors.mainColor,),
                SizedBox(height: 8),
                CustomTextField(
                  controller: emailController,
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                SizedBox(height: 16),
                CustomText16("Password",bold: true,color: AppColors.mainColor,),
                SizedBox(height: 8),
                CustomTextField(
                  controller: passwordController,
                  hintText: 'Enter your password',
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onSuffixTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, ForgotPasswordFlowScreen.routeName);
                    },
                    child: CustomText16(
                      'Forget Password?',
                      color: AppColors.mainColor,
                      bold: false,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: BlocBuilder<LoginBloc, LoginState>(
                    builder: (context, state) {
                      final isLoading = state is LoginLoading;
                      return SizedBox(
                        width: 280,
                        child: AuthButton(
                          action: () async {
                            if (_formKey.currentState!.validate()) {
                              final email = emailController.text.trim();
                              final password = passwordController.text;

                              // Security: Validate email format
                              final emailError = InputValidator.validateEmail(email);
                              if (emailError != null) {
                                MessageHelper.showError(context, emailError);
                                return;
                              }

                              // Security: Validate password
                              final passwordError = InputValidator.validatePassword(password);
                              if (passwordError != null) {
                                MessageHelper.showError(context, passwordError);
                                return;
                              }

                              // Security: Check if user is blocked
                              if (RateLimiter.isLoginBlocked(email)) {
                                final remaining = RateLimiter.getRemainingBlockTime(email);
                                final minutes = remaining?.inMinutes ?? 0;
                                MessageHelper.showError(
                                  context,
                                  'Too many failed login attempts. Please try again in $minutes minutes.',
                                );
                                return;
                              }

                              // Security: Check rate limit
                              if (!RateLimiter.isRequestAllowed('login')) {
                                MessageHelper.showError(
                                  context,
                                  'Too many requests. Please wait a moment.',
                                );
                                return;
                              }

                              final request = LoginRequest(
                                email: email,
                                password: password,
                              );
                              context.read<LoginBloc>().add(
                                LoginSubmitEvent(request),
                              );
                            }
                          },
                          text: isLoading ? 'Logging in...' : 'Login',
                          isLoading: isLoading,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 280,
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: CustomText16('OR', color: AppColors.greyText),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 280,
                  child: OutlinedButton.icon(
                    onPressed: _handleSignIn,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/images/google.png',
                      height: 24,
                      width: 24,
                    ),
                    label: CustomText16(
                      'Continue with Google',
                      color: AppColors.black,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
