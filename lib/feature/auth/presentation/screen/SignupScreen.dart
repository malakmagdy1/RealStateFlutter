import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/feature/auth/data/models/register_request.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/presentation/bloc/register_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/register_event.dart';
import 'package:real/feature/auth/presentation/bloc/register_state.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';
import 'package:real/feature/auth/presentation/screen/email_verification_screen.dart';

import '../../../../core/widget/button/authButton.dart';
import '../widget/authToggle.dart';
import '../widget/textFormField.dart';

class SignUpScreen extends StatefulWidget {
  static String routeName = '/signup';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
      resizeToAvoidBottomInset: true,
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
              print('[SignupScreen] Token saved after registration');
              print('[SignupScreen] Token: ${state.response.token}');
              print('[SignupScreen] User ID: ${state.response.user?.id}');
              print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.response.message),
                backgroundColor: Colors.green,
              ),
            );

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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 40),
                  CustomText24(
                    "Get Started Now",
                    color: AppColors.black,
                    bold: true,
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
                  CustomTextField(
                    controller: phoneController,
                    hintText: 'Enter your phone number',
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                  SizedBox(height: 24),
                  BlocBuilder<RegisterBloc, RegisterState>(
                    builder: (context, state) {
                      final isLoading = state is RegisterLoading;
                      return AuthButton(
                        action: () {
                          if (_formKey.currentState!.validate()) {
                            final request = RegisterRequest(
                              name: nameController.text,
                              email: emailController.text,
                              password: passwordController.text,
                              passwordConfirmation:
                                  confirmPasswordController.text,
                              phone: phoneController.text,
                              role: 'buyer',
                            );
                            context.read<RegisterBloc>().add(
                              RegisterSubmitEvent(request),
                            );
                          }
                        },
                        text: isLoading ? 'Registering...' : 'Sign Up',
                        isLoading: isLoading,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
