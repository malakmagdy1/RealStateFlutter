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
import 'package:real/feature/auth/presentation/screen/SignupScreen.dart';
import 'package:real/feature/auth/presentation/screen/forgetPasswordScreen.dart';
import 'package:real/feature/home/presentation/CustomNav.dart';
import 'package:real/feature/home/presentation/homeScreen.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_event.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_event.dart';

import '../../../../core/widget/button/authButton.dart';
import '../widget/textFormField.dart';
import '../widget/authToggle.dart';

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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com' // Web Client ID
        : null, // Mobile gets clientId from google-services.json (Android) / GoogleService-Info.plist (iOS)
    serverClientId: kIsWeb
        ? null // serverClientId is NOT supported on web
        : '832433207149-vlahshba4mbt380tbjg43muqo7l6s1o9.apps.googleusercontent.com', // Required for Android to get ID tokens
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
            print('Global userId variable updated: $userId');
          }

          // IMPORTANT: Update global token variable
          token = response.token ?? '';

          print('Backend Token SAVED: ${response.token}');
          print('Global token variable updated: $token');
          print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

          // Refresh user data with new token
          context.read<UserBloc>().add(RefreshUserEvent());

          // Navigate to home screen after successful Google sign-in
          Navigator.pushReplacementNamed(context, CustomNav.routeName);
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
    } catch (error) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('GOOGLE SIGN-IN ERROR: $error');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    await CasheNetwork.deletecasheItem(key: "token");
    setState(() => _user = null);
  }

  // Temporary method to clear token for testing
  Future<void> _clearToken() async {
    print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
    // Check token before deleting
    final tokenBefore = CasheNetwork.getCasheData(key: "token");
    print('Token BEFORE clearing: $tokenBefore');

    // Delete token
    final deleted = await CasheNetwork.deletecasheItem(key: "token");
    print('Token deleted successfully: $deleted');

    // Check token after deleting
    final tokenAfter = CasheNetwork.getCasheData(key: "token");
    print('Token AFTER clearing: $tokenAfter');
    print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Token cleared! STOP the app completely and start again.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );
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

            // Reload favorites with the new token-specific key
            context.read<CompoundFavoriteBloc>().add(LoadFavoriteCompounds());
            context.read<UnitFavoriteBloc>().add(LoadFavoriteUnits());

            // Navigate to home screen after successful login
            Navigator.pushReplacementNamed(context, CustomNav.routeName);
          } else if (state is LoginError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Form(key: _formKey,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                  SizedBox(height: 40),
                  CustomText24("Welcome Back", color: AppColors.black, bold: true),
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
                    Navigator.pushNamed(context, ForgetPasswordScreen.routeName);
                  },
                  child: CustomText16(
                    'Forget Password?',
                    color: AppColors.mainColor,
                    bold: false,
                  ),
                ),
              ),
              SizedBox(height: 16),
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  final isLoading = state is LoginLoading;
                  return AuthButton(
                    action: () {
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
                    text: isLoading ? 'Logging in...' : 'Login',
                    isLoading: isLoading,
                  );
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CustomText16('OR', color: AppColors.greyText),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),
              SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _handleSignIn,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
              SizedBox(height: 20),
              // Temporary button for testing - DELETE THIS AFTER TESTING
              TextButton(
                onPressed: _clearToken,
                child: CustomText16(
                  'Clear Token (For Testing)',
                  color: Colors.red,
                ),
              ),
                    ],
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
