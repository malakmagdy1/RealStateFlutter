import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/auth/data/models/register_request.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/presentation/bloc/register_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/register_event.dart';
import 'package:real/feature/auth/presentation/bloc/register_state.dart';
import 'package:real/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_event.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';
import 'package:real/feature/auth/presentation/screen/email_verification_screen.dart';
import 'package:real/core/security/input_validator.dart';
import 'package:real/core/security/rate_limiter.dart';
import 'package:real/core/security/secure_storage.dart';
import 'package:real/core/models/country_code.dart';
import 'package:real/core/widgets/phone_input_field.dart';
import 'package:real/feature/home/presentation/CustomNav.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_state.dart';
import 'package:real/feature/subscription/presentation/screens/subscription_plans_screen.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';

import '../../../../core/widget/button/authButton.dart';
import '../widget/authToggle.dart';
import '../widget/textFormField.dart';

class SignUpScreen extends StatefulWidget {
  static String routeName = '/signup';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  CountryCode _selectedCountry = CountryCode.getDefault();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22.0),
        child: BlocListener<RegisterBloc, RegisterState>(
          listener: (context, state) async {
            if (state is RegisterSuccess) {
              // Security: Save token and user data securely
              if (state.response.token != null) {
                final receivedToken = state.response.token!;

                // Security: Validate token format before storing
                if (!SecureStorage.isValidTokenFormat(receivedToken)) {
                  print('[SECURITY] Invalid token format received from registration');
                  MessageHelper.showError(
                    context,
                    'Invalid authentication response. Please try again.',
                  );
                  return;
                }

                // Security: Store token securely (encrypted)
                await SecureStorage.saveToken(receivedToken);

                // Also save to old storage for backward compatibility
                await CasheNetwork.insertToCashe(
                  key: "token",
                  value: receivedToken
                );

                // Update global token variable
                token = receivedToken;

                // Save user ID if available
                if (state.response.user?.id != null) {
                  await SecureStorage.saveUserId(state.response.user!.id!);
                  await CasheNetwork.insertToCashe(
                    key: "user_id",
                    value: state.response.user!.id.toString()
                  );
                  userId = state.response.user!.id.toString();
                }

                print('[SignupScreen] 🔒 Token saved securely (encrypted) after registration');
                print('[SignupScreen] Token length: ${receivedToken.length}');
                print('[SignupScreen] User ID: ${state.response.user?.id}');
              }

              MessageHelper.showSuccess(context, state.response.message);

              // Navigate to email verification screen after successful registration
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EmailVerificationScreen(
                    email: emailController.text,
                  ),
                ),
              );
            } else if (state is RegisterError) {
              MessageHelper.showError(context, state.message);
            }
          },
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Form(
                  key: _formKey,
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
                      child: CustomText24(
                        "Get Started Now",
                        color: AppColors.black,
                        bold: true,
                      ),
                    ),
                    SizedBox(height: 20),
                    AuthToggle(
                      isSignUp: true,
                      onSignUpPressed: () {},
                      onLoginPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          LoginScreen.routeName,
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    CustomText16(
                      "Enter your Full name",
                      bold: true,
                      color: AppColors.mainColor,
                    ),
                    SizedBox(height: 8),
                    CustomTextField(
                      controller: nameController,
                      hintText: 'Enter your full name',
                      validator: Validators.validateName,
                    ),
                    SizedBox(height: 16),
                    CustomText16("Email", bold: true, color: AppColors.mainColor),
                    SizedBox(height: 8),
                    CustomTextField(
                      controller: emailController,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),
                    SizedBox(height: 16),
                    CustomText16(
                      "Password",
                      bold: true,
                      color: AppColors.mainColor,
                    ),
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
                    SizedBox(height: 16),
                    CustomText16(
                      "Confirm Password",
                      bold: true,
                      color: AppColors.mainColor,
                    ),
                    SizedBox(height: 8),
                    CustomTextField(
                      controller: confirmPasswordController,
                      hintText: 'Confirm your password',
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      onSuffixTap: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      validator: (value) => Validators.validateConfirmPassword(
                        value,
                        passwordController.text,
                      ),
                    ),
                    SizedBox(height: 16),
                    CustomText16(
                      "Phone Number",
                      bold: true,
                      color: AppColors.mainColor,
                    ),
                    SizedBox(height: 8),
                    PhoneInputField(
                      controller: phoneController,
                      initialCountry: _selectedCountry,
                      hintText: 'e.g. 1012345678',
                      onCountryChanged: (country) {
                        setState(() {
                          _selectedCountry = country;
                        });
                      },
                    ),
                    SizedBox(height: 24),
                    Center(
                      child: BlocBuilder<RegisterBloc, RegisterState>(
                        builder: (context, state) {
                          final isLoading = state is RegisterLoading;
                          return SizedBox(
                            width: 280,
                            child: AuthButton(
                              action: () async {
                                if (_formKey.currentState!.validate()) {
                                  final name = nameController.text.trim();
                                  final email = emailController.text.trim();
                                  final password = passwordController.text;
                                  final confirmPassword = confirmPasswordController.text;

                                  // Security: Check rate limit for registration
                                  if (!RateLimiter.isRequestAllowed('register')) {
                                    MessageHelper.showError(
                                      context,
                                      'Too many registration requests. Please wait a moment.',
                                    );
                                    return;
                                  }

                                  // Security: Validate name
                                  final nameError = InputValidator.validateName(name);
                                  if (nameError != null) {
                                    MessageHelper.showError(context, nameError);
                                    return;
                                  }

                                  // Security: Validate email format
                                  final emailError = InputValidator.validateEmail(email);
                                  if (emailError != null) {
                                    MessageHelper.showError(context, emailError);
                                    return;
                                  }

                                  // Security: Validate password strength
                                  final passwordError = InputValidator.validatePassword(password);
                                  if (passwordError != null) {
                                    MessageHelper.showError(context, passwordError);
                                    return;
                                  }

                                  // Security: Validate password confirmation
                                  if (password != confirmPassword) {
                                    MessageHelper.showError(
                                      context,
                                      'Passwords do not match',
                                    );
                                    return;
                                  }

                                  // Build full phone number with country code
                                  final phone = phoneController.text.trim();
                                  final fullPhone = phone.isNotEmpty
                                      ? '${_selectedCountry.dialCode}$phone'
                                      : '';

                                  final request = RegisterRequest(
                                    name: name,
                                    email: email,
                                    password: password,
                                    passwordConfirmation: confirmPassword,
                                    phone: fullPhone,
                                    role: 'buyer',
                                  );
                                  context.read<RegisterBloc>().add(
                                    RegisterSubmitEvent(request),
                                  );
                                }
                              },
                              text: isLoading ? 'Registering...' : 'Sign Up',
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
                    // Show Apple Sign-In button only on iOS/macOS
                    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
                      SizedBox(
                        width: 280,
                        child: OutlinedButton.icon(
                          onPressed: _handleAppleSignIn,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            side: BorderSide(color: Colors.grey[400]!),
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            Icons.apple,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: CustomText16(
                            'Continue with Apple',
                            color: Colors.white,
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
