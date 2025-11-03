import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:real/core/utils/web_utils.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/feature/auth/data/models/login_request.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/login_event.dart';
import 'package:real/feature/auth/presentation/bloc/login_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_event.dart';
import 'package:real/feature_web/auth/presentation/web_signup_screen.dart';
import 'package:real/feature_web/navigation/web_main_screen.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_event.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_state.dart';
import 'package:real/feature_web/subscription/presentation/web_subscription_plans_screen.dart';
import 'package:real/feature_web/auth/presentation/web_forgot_password_screen.dart';

import '../../../feature/auth/presentation/screen/forgetPasswordScreen.dart';

class WebLoginScreen extends StatefulWidget {
  static String routeName = '/web-login';

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  GoogleSignIn? _googleSignIn;

  @override
  void initState() {
    super.initState();
    // Initialize Google Sign-In
    // Web: Requires clientId explicitly
    // Mobile: Uses google-services.json (Android) and GoogleService-Info.plist (iOS)
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb
          ? '832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com' // Web Client ID
          : null, // Mobile gets clientId from platform-specific config files
      serverClientId: kIsWeb
          ? null // serverClientId is NOT supported on web
          : '832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com', // Required for Android to get ID tokens
      scopes: ['email', 'profile', 'openid'],
      // Force account selection on web for better UX
      forceCodeForRefreshToken: true,
    );
  }

  Future<void> _handleSignIn() async {
    if (_googleSignIn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In is not initialized. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('Starting Google Sign-In...');
      print('Platform: ${kIsWeb ? "Web" : "Mobile"}');

      GoogleSignInAccount? account;

      if (kIsWeb) {
        // For web: Use JavaScript to trigger Google Sign-In with account picker
        print('Initiating web sign-in with account picker...');

        // Inject Google Sign-In prompt parameter to force account selection
        setGoogleSignInPrompt('select_account');

        // Try silent sign-in first (will use cached credentials)
        account = await _googleSignIn!.signInSilently(suppressErrors: true);

        // If silent sign-in fails, use interactive sign-in
        if (account == null) {
          print('Silent sign-in failed, showing account picker...');
          account = await _googleSignIn!.signIn();
        }
      } else {
        // For mobile: Sign out first to force fresh login
        await _googleSignIn!.signOut();
        account = await _googleSignIn!.signIn();
      }

      if (account != null) {
        print('Sign-in successful, processing account...');
        await _processGoogleAccount(account);
      } else {
        print('Sign-in was cancelled or returned null');
      }
    } catch (error) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('GOOGLE SIGN-IN ERROR: $error');
      print('Error type: ${error.runtimeType}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      // Only show error if it's not a user cancellation
      if (!error.toString().contains('popup_closed') &&
          !error.toString().contains('popup_closed_by_user') &&
          !error.toString().contains('redirect_uri_mismatch')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (error.toString().contains('redirect_uri_mismatch')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OAuth configuration error. Please contact support.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _processGoogleAccount(GoogleSignInAccount account) async {
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

      // Save the BACKEND token (not Google ID)
      await CasheNetwork.insertToCashe(
        key: "token",
        value: response.token ?? '',
      );

      // Save user_id
      if (response.user.id != null) {
        await CasheNetwork.insertToCashe(
          key: "user_id",
          value: response.user.id.toString(),
        );
        // IMPORTANT: Update global userId variable
        userId = response.user.id.toString();
        print('User ID SAVED: ${response.user.id}');
      }

      // IMPORTANT: Update global token variable
      token = response.token ?? '';

      print('Backend Token SAVED: ${response.token}');
      print('Global token variable updated: $token');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      // SECURITY CHECKS: Only allow buyers who are verified and not banned
      final user = response.user;

      // Check 1: Only buyers allowed
      if (user.role.toLowerCase() != 'buyer') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text('Access Denied', style: TextStyle(fontSize: 22)),
              ],
            ),
            content: Container(
              width: 400,
              child: Text(
                'Only buyers can access this application. Your account type is: ${user.role}',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: Text('OK', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
        await CasheNetwork.deletecasheItem(key: "token");
        await CasheNetwork.deletecasheItem(key: "user_id");
        token = null;
        userId = null;
        return;
      }

      // Check 2: User must be verified
      if (!user.isVerified) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.email_outlined, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text('Email Verification Required', style: TextStyle(fontSize: 22)),
              ],
            ),
            content: Container(
              width: 400,
              child: Text(
                'Please verify your email address to continue. Check your inbox for the verification link.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: Text('OK', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text('Account Suspended', style: TextStyle(fontSize: 22)),
              ],
            ),
            content: Container(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your account has been suspended and you cannot access the application.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Please contact support for assistance:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  SelectableText(
                    'support@aqar.bdcbiz.com',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: Text('OK', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
        await CasheNetwork.deletecasheItem(key: "token");
        await CasheNetwork.deletecasheItem(key: "user_id");
        token = null;
        userId = null;
        return;
      }

      // All checks passed - proceed with login
      // Refresh user data with new token
      context.read<UserBloc>().add(RefreshUserEvent());

      // Reload favorites with the new token-specific key
      context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
      context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());

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
              Text('Backend Authentication Failed'),
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
                '📝 Note: The backend needs to be updated to accept access tokens from web.',
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

      // Also show SnackBar for quick reference
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backend authentication failed - see error dialog'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
    await CasheNetwork.deletecasheItem(key: "token");
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 24),
                    Text(
                      'Checking subscription...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SubscriptionStatusLoaded) {
            final status = state.status;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    status.hasActiveSubscription
                        ? Icons.check_circle
                        : Icons.card_membership,
                    color: status.hasActiveSubscription
                        ? Colors.green
                        : AppColors.mainColor,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status.hasActiveSubscription
                          ? 'Active Subscription'
                          : 'Unlock Premium Features',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Container(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (status.hasActiveSubscription) ...[
                      Text(
                        'You are subscribed to:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        status.planName ?? 'N/A',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: AppColors.mainColor, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status.isUnlimited
                                    ? 'You have unlimited searches'
                                    : 'Searches used: ${status.searchesUsed}/${status.searchesAllowed}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Choose a subscription plan to access:',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      ...[
                        'Unlimited property searches',
                        'Advanced filtering options',
                        'Priority support',
                        'Exclusive property listings',
                      ].map((benefit) => Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 22),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: TextStyle(fontSize: 15, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.pushReplacementNamed(context, WebMainScreen.routeName);
                  },
                  child: Text(
                    status.hasActiveSubscription ? 'Continue' : 'Maybe Later',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await Navigator.pushNamed(
                      context,
                      WebSubscriptionPlansScreen.routeName,
                    );
                    Navigator.pushReplacementNamed(context, WebMainScreen.routeName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    status.hasActiveSubscription ? 'Upgrade Plan' : 'View Plans',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }

          // Error or other states - just navigate to home
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Unable to load subscription info',
                style: TextStyle(fontSize: 16),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.pushReplacementNamed(context, WebMainScreen.routeName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            // SECURITY CHECKS: Only allow buyers who are verified and not banned
            final user = state.response.user;

            // Check 1: Only buyers allowed
            if (user.role.toLowerCase() != 'buyer') {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red, size: 28),
                      SizedBox(width: 12),
                      Text('Access Denied', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                  content: Container(
                    width: 400,
                    child: Text(
                      'Only buyers can access this application. Your account type is: ${user.role}',
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: Text('OK', style: TextStyle(fontSize: 16)),
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

            // Check 2: User must be verified
            if (!user.isVerified) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Icon(Icons.email_outlined, color: Colors.orange, size: 28),
                      SizedBox(width: 12),
                      Text('Email Verification Required', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                  content: Container(
                    width: 400,
                    child: Text(
                      'Please verify your email address to continue. Check your inbox for the verification link.',
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: Text('OK', style: TextStyle(fontSize: 16)),
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

            // Check 3: User must not be banned
            if (user.isBanned) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red, size: 28),
                      SizedBox(width: 12),
                      Text('Account Suspended', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                  content: Container(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your account has been suspended and you cannot access the application.',
                          style: TextStyle(fontSize: 16, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Please contact support for assistance:',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        SelectableText(
                          'support@aqar.bdcbiz.com',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.mainColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: Text('OK', style: TextStyle(fontSize: 16)),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.response.message),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh user data with new token
            context.read<UserBloc>().add(RefreshUserEvent());

            // Reload favorites with the new token-specific key
            context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
            context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());

            // Check subscription status after login
            _checkSubscriptionStatus(context);
          } else if (state is LoginError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Row(
          children: [
            // Left side - Background Image (hidden on mobile)
            if (!isMobile)
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/onboarding1.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Find your next home with us.',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'The best properties, curated just for you. Start your journey to a new beginning today.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Right side - Login Form
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.white,
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(48.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 450),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo or Brand Name
                            Center(
                              child: Icon(
                                Icons.location_city,
                                size: 48,
                                color: AppColors.mainColor,
                              ),
                            ),
                            SizedBox(height: 16),
                            Center(
                              child: Text(
                                'RealtyFind',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.mainColor,
                                ),
                              ),
                            ),
                            SizedBox(height: 40),
                            Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Sign in to continue your journey with RealtyCo',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 32),

                            // Email Address
                            Text(
                              "Email Address",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                              decoration: InputDecoration(
                                hintText: 'you@example.com',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red, width: 1),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Password
                            Text(
                              "Password",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              validator: Validators.validatePassword,
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red, width: 1),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 12),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, WebForgotPasswordScreen.routeName);
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppColors.mainColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 24),

                            // Sign In Button
                            BlocBuilder<LoginBloc, LoginState>(
                              builder: (context, state) {
                                final isLoading = state is LoginLoading;
                                return ElevatedButton(
                                  onPressed: isLoading ? null : () {
                                    if (_formKey.currentState!.validate()) {
                                      final request = LoginRequest(
                                        email: emailController.text,
                                        password: passwordController.text,
                                      );
                                      context.read<LoginBloc>().add(
                                        LoginSubmitEvent(request),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.mainColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                );
                              },
                            ),
                            SizedBox(height: 24),

                            // OR Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[300])),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR SIGN IN WITH',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey[300])),
                              ],
                            ),
                            SizedBox(height: 24),

                            // Google Sign In Button
                            OutlinedButton.icon(
                              onPressed: _handleSignIn,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: Image.asset(
                                'assets/images/google.png',
                                height: 20,
                                width: 20,
                              ),
                              label: Text(
                                'Continue with Google',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            SizedBox(height: 32),

                            // Sign Up Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      WebSignUpScreen.routeName,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Sign up',
                                    style: TextStyle(
                                      color: AppColors.mainColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
