import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/auth/data/models/register_request.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/presentation/bloc/register_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/register_event.dart';
import 'package:real/feature/auth/presentation/bloc/register_state.dart';
import 'package:real/feature/auth/presentation/screen/email_verification_screen.dart';
import 'package:real/feature_web/auth/presentation/web_login_screen.dart';

class WebSignUpScreen extends StatefulWidget {
  static String routeName = '/web-signup';

  @override
  State<WebSignUpScreen> createState() => _WebSignUpScreenState();
}

class _WebSignUpScreenState extends State<WebSignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _passwordStrength = '';
  Color _passwordStrengthColor = Colors.grey;

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = '';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    setState(() {
      if (strength <= 1) {
        _passwordStrength = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (strength == 2) {
        _passwordStrength = 'Fair';
        _passwordStrengthColor = Colors.orange;
      } else if (strength == 3) {
        _passwordStrength = 'Good';
        _passwordStrengthColor = Colors.blue;
      } else {
        _passwordStrength = 'Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) async {
          if (state is RegisterSuccess) {
            // Save token and user data from registration
            if (state.response.token != null) {
              await CasheNetwork.insertToCashe(
                key: "token",
                value: state.response.token!
              );

              // Update global token variable
              token = state.response.token!;

              // Save user ID if available
              if (state.response.user?.id != null) {
                await CasheNetwork.insertToCashe(
                  key: "user_id",
                  value: state.response.user!.id.toString()
                );
                userId = state.response.user!.id.toString();
              }

              print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
              print('[WebSignupScreen] Token saved after registration');
              print('[WebSignupScreen] Token: ${state.response.token}');
              print('[WebSignupScreen] User ID: ${state.response.user?.id}');
              print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
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
            padding: EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - PropSpace branding
                if (MediaQuery.of(context).size.width > 1200)
                  Padding(
                    padding: EdgeInsets.only(right: 64),
                    child: Container(
                      width: 400,
                      padding: EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: Color(0xFF2C3E50),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.apartment, size: 48, color: Colors.white),
                          SizedBox(height: 24),
                          Text(
                            'PropSpace',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Find Your Perfect Space',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Create an account to save properties, get market updates, and connect with agents.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Right side - Registration Form
                Container(
                  width: 550,
                  padding: EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Get Started for Free',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 32),

                        // Social Sign Up Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Handle Google sign up
                                },
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
                                  'Sign up with Google',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Handle Apple sign up
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: Icon(Icons.apple, size: 24, color: Colors.black87),
                                label: Text(
                                  'Sign up with Apple',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),

                        // Step indicator
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Step 1 of 2: Create Your Account',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Full Name
                        Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: nameController,
                          validator: Validators.validateName,
                          decoration: InputDecoration(
                            hintText: 'John Doe',
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

                        // Email Address
                        Text(
                          'Email Address',
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
                            hintText: 'john.doe@example.com',
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
                          'Password',
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
                          onChanged: _checkPasswordStrength,
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
                        if (_passwordStrength.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _passwordStrengthColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                _passwordStrength,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _passwordStrengthColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 20),

                        // Confirm Password
                        Text(
                          'Confirm Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          validator: (value) => Validators.validateConfirmPassword(
                            value,
                            passwordController.text,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Confirm your password',
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
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Phone Number
                        Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          validator: Validators.validatePhone,
                          decoration: InputDecoration(
                            hintText: '+20 123 456 7890',
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
                            prefixIcon: Icon(Icons.phone, color: Colors.grey[600]),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Terms and Conditions Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                              activeColor: AppColors.mainColor,
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                    children: [
                                      TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: AppColors.mainColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: AppColors.mainColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Create Account Button
                        BlocBuilder<RegisterBloc, RegisterState>(
                          builder: (context, state) {
                            final isLoading = state is RegisterLoading;
                            return ElevatedButton(
                              onPressed: (!_acceptTerms || isLoading) ? null : () {
                                if (_formKey.currentState!.validate()) {
                                  final request = RegisterRequest(
                                    name: nameController.text,
                                    email: emailController.text,
                                    password: passwordController.text,
                                    passwordConfirmation: confirmPasswordController.text,
                                    phone: phoneController.text,
                                    role: 'buyer',
                                  );
                                  context.read<RegisterBloc>().add(
                                    RegisterSubmitEvent(request),
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
                                disabledBackgroundColor: Colors.grey[300],
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
                                    'Create My Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                            );
                          },
                        ),
                        SizedBox(height: 24),

                        // Log In Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  WebLoginScreen.routeName,
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Log In',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
