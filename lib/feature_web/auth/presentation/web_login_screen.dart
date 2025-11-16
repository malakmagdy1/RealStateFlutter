import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:real/core/utils/web_utils.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/core/router/auth_state_notifier.dart';
import 'package:real/feature/auth/data/models/login_request.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/login_event.dart';
import 'package:real/feature/auth/presentation/bloc/login_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_event.dart';
import 'package:real/feature_web/auth/presentation/web_signup_screen.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_event.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_state.dart';
import 'package:real/feature_web/auth/presentation/web_forgot_password_screen.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';
import 'package:real/feature/auth/data/web_services/auth_web_services.dart';
import 'package:intl/intl.dart';

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
  String? _redirectUrl; // Store redirect URL from query params

  GoogleSignIn? _googleSignIn;

  @override
  void initState() {
    super.initState();

    // Capture redirect URL from query parameters early
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final from = uri.queryParameters['from'];
      if (from != null && from.isNotEmpty) {
        _redirectUrl = Uri.decodeComponent(from);
      }
    });

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
      MessageHelper.showMessage(
        context: context,
        message: 'Google Sign-In is not initialized. Please try again.',
        isSuccess: false,
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
        MessageHelper.showError(context, 'Sign-in error: $error');
      } else if (error.toString().contains('redirect_uri_mismatch')) {
        MessageHelper.showMessage(
          context: context,
          message: 'OAuth configuration error. Please contact support.',
          isSuccess: false,
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

      // Notify router that auth state has changed
      AuthStateNotifier().notifyAuthChanged();

      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      // SECURITY CHECKS: Only allow buyers who are verified and not banned
      final user = response.user;

      // Check 1: Only buyers allowed
      if (user.role.toLowerCase() != 'buyer') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                  context.pop();
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.email_outlined, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text(
                  'Email Verification Required',
                  style: TextStyle(fontSize: 22),
                ),
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
                  context.pop();
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                  context.pop();
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
              onPressed: () => context.pop(),
              child: Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );

      // Also show error message for quick reference
      MessageHelper.showError(
        context,
        'Backend authentication failed - see error dialog',
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

    // Show subscription dialog after a short delay, only if needed
    Future.delayed(Duration(milliseconds: 500), () {
      final subscriptionBloc = context.read<SubscriptionBloc>();
      final currentState = subscriptionBloc.state;

      // Only show dialog if user doesn't have active subscription
      if (currentState is SubscriptionStatusLoaded) {
        if (!currentState.status.hasActiveSubscription) {
          _showSubscriptionDialog(context);
        } else {
          // User has active subscription, just show success and navigate
          MessageHelper.showSuccess(context, 'Login successful! Welcome back.');
          Future.delayed(Duration(milliseconds: 800), () {
            if (context.mounted) {
              context.go(_getRedirectUrl());
            }
          });
        }
      } else {
        // If status isn't loaded yet, listen for state changes
        _listenForSubscriptionStatus(context);
      }
    });
  }

  void _listenForSubscriptionStatus(BuildContext context) {
    final subscription = context.read<SubscriptionBloc>().stream.listen((
      state,
    ) {
      if (state is SubscriptionStatusLoaded) {
        if (!state.status.hasActiveSubscription) {
          _showSubscriptionDialog(context);
        } else {
          // User has active subscription, just show success and navigate
          MessageHelper.showSuccess(context, 'Login successful! Welcome back.');
          Future.delayed(Duration(milliseconds: 800), () {
            if (context.mounted) {
              context.go(_getRedirectUrl());
            }
          });
        }
      }
    });

    // Cancel subscription after first event
    Future.delayed(Duration(seconds: 2), () {
      subscription.cancel();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CustomLoadingDots(size: 60),
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
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: status.hasActiveSubscription
                        ? [
                            AppColors.mainColor,
                            AppColors.mainColor.withOpacity(0.8),
                          ]
                        : [Colors.grey[800]!, Colors.grey[700]!],
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
                              status.hasActiveSubscription
                                  ? Icons.workspace_premium
                                  : Icons.rocket_launch,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: 20),

                          // Status badge
                          if (status.hasActiveSubscription)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(height: 16),

                          // Title
                          Text(
                            status.hasActiveSubscription
                                ? 'Welcome Back!'
                                : 'Unlock Premium Features',
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
                          if (status.hasActiveSubscription) ...[
                            Text(
                              status.planNameEn ??
                                  status.planName ??
                                  'Premium Plan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.95),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),

                            // Search usage info
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Search Access',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          status.isUnlimited
                                              ? 'Unlimited Searches'
                                              : '${status.searchesUsed}/${status.searchesAllowed} Used',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (status.isUnlimited)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[600],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.all_inclusive,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ] else ...[
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
                            ].map(
                              (feature) => Padding(
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
                              ),
                            ),
                          ],

                          SizedBox(height: 24),

                          // Buttons
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.of(dialogContext).pop();
                                    if (!status.hasActiveSubscription) {
                                      await context.push('/subscription');
                                    }
                                    context.go(_getRedirectUrl());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor:
                                        status.hasActiveSubscription
                                        ? AppColors.mainColor
                                        : Colors.grey[800],
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
                                        status.hasActiveSubscription
                                            ? Icons.arrow_forward
                                            : Icons.star,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        status.hasActiveSubscription
                                            ? 'Continue to App'
                                            : 'View Plans',
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
                                  context.go(_getRedirectUrl());
                                },
                                child: Text(
                                  status.hasActiveSubscription
                                      ? 'View My Plan'
                                      : 'Maybe Later',
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                  context.go(_getRedirectUrl());
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

  void _showDeviceLimitDialog(
    BuildContext context,
    String message,
    List<Map<String, dynamic>> devices,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Device Limit Reached',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'How to fix this:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildStep('1', 'Login from one of your existing devices'),
                      SizedBox(height: 8),
                      _buildStep('2', 'Go to Profile → Device Management'),
                      SizedBox(height: 8),
                      _buildStep('3', 'Remove old or unused devices'),
                      SizedBox(height: 8),
                      _buildStep('4', 'Come back and login from this device'),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                if (devices.isNotEmpty) ...[
                  Text(
                    'Your registered devices:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  ...devices.take(5).map((device) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.mainColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getDeviceIcon(device['device_type']),
                              color: AppColors.mainColor,
                              size: 22,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device['device_name'] ?? 'Unknown Device',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  device['os_version'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (device['last_active'] != null ||
                                    device['last_active_at'] != null)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Last active: ${_formatDeviceDate(device['last_active'] ?? device['last_active_at'])}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('OK', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/subscription-plans');
            },
            icon: Icon(Icons.workspace_premium, size: 20),
            label: Text('Upgrade Plan', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.blue.shade900),
          ),
        ),
      ],
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
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Get the redirect URL from stored value, or default to home
  String _getRedirectUrl() {
    return _redirectUrl ?? '/';
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: Colors.orange,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Email Verification Required',
                        style: TextStyle(fontSize: 22),
                      ),
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
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
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
            // Refresh user data with new token
            context.read<UserBloc>().add(RefreshUserEvent());

            // Reload favorites with the new token-specific key
            context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
            context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());

            // Check subscription status after login
            // (Success message will be shown based on subscription status)
            _checkSubscriptionStatus(context);
          } else if (state is LoginDeviceLimitError) {
            // Show device limit dialog for web
            _showDeviceLimitDialog(context, state.message, state.devices);
          } else if (state is LoginError) {
            MessageHelper.showError(context, state.message);
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
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Padding(
                                    padding: EdgeInsets.all(15), // optional padding to make the image smaller inside
                                    child: SvgPicture.asset(
                                      'assets/images/logos/logo.svg',
                                      colorFilter: ColorFilter.mode(AppColors.logoColor, BlendMode.srcIn),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
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
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.mainColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
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
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.mainColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
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
                                  context.go('/forgot-password');
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
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          if (_formKey.currentState!
                                              .validate()) {
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
                                      ? CustomLoadingDots(size: 20)
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
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
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
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
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
                                    context.go('/signup');
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
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
