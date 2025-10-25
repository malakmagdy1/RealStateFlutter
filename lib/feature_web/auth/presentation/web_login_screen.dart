import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/core/utils/text_style.dart';
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

import '../../../../core/widget/button/authButton.dart';
import '../../../../feature/auth/presentation/widget/textFormField.dart';
import '../../../../feature/auth/presentation/widget/authToggle.dart';

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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '641586807593-1drlkrodshb5toe1374l26m0lpmausor.apps.googleusercontent.com',
  );

  GoogleSignInAccount? _user;

  Future<void> _handleSignIn() async {
    try {
      GoogleSignInAccount? account;

      // For web, try silent sign-in first (recommended for web)
      if (kIsWeb) {
        account = await _googleSignIn.signInSilently();
        // If silent sign-in fails, use the standard sign-in
        account ??= await _googleSignIn.signIn();
      } else {
        // For mobile/desktop, use standard sign-in
        account = await _googleSignIn.signIn();
      }

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
          final repository = context.read<LoginBloc>().repository;
          final response = await repository.googleLogin(
            googleId: account.id,
            email: account.email,
            name: account.displayName ?? '',
            photoUrl: account.photoUrl,
          );

          // Save the BACKEND token (not Google ID)
          await CasheNetwork.insertToCashe(
            key: "token",
            value: response.token ?? '',
          );

          // IMPORTANT: Update global token variable
          token = response.token ?? '';

          print('Backend Token SAVED: ${response.token}');
          print('Global token variable updated: $token');
          print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

          // Refresh user data with new token
          context.read<UserBloc>().add(RefreshUserEvent());

          // Navigate to home screen after successful Google sign-in
          Navigator.pushReplacementNamed(context, WebMainScreen.routeName);
        } catch (backendError) {
          print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
          print('BACKEND ERROR: $backendError');
          print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backend authentication failed: $backendError'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('GOOGLE SIGN-IN ERROR: $error');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      // Handle specific popup_closed error
      if (error.toString().contains('popup_closed')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in cancelled. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    await CasheNetwork.deletecasheItem(key: "token");
    setState(() => _user = null);
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.response.message),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh user data with new token
            context.read<UserBloc>().add(RefreshUserEvent());

            // Navigate to home screen after successful login
            Navigator.pushReplacementNamed(context, WebMainScreen.routeName);
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
                                  // Navigator.pushNamed(context, ForgetPasswordScreen.routeName);
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

                            // Google Sign In
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
