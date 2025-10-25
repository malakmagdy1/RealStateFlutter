import 'package:flutter/material.dart';
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

import '../../../../core/widget/button/authButton.dart';
import '../widget/textFormField.dart';
import '../widget/authToggle.dart';

class LoginScreen extends StatefulWidget {
  static String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
          Navigator.pushReplacementNamed(context, CustomNav.routeName);
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
  void dispose() {
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
      )
    );
  }
}
