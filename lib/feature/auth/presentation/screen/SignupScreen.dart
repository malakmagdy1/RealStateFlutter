import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/feature/auth/data/models/register_request.dart';
import 'package:real/feature/auth/presentation/bloc/register_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/register_event.dart';
import 'package:real/feature/auth/presentation/bloc/register_state.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';

import '../../../../core/widget/button/authButton.dart';
import '../widget/authToggle.dart';
import '../widget/textFormField.dart';

class SignUpScreen extends StatefulWidget {
  static const String routeName = '/signup';

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
        listener: (context, state) {
          if (state is RegisterSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.response.message),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to login screen after successful registration
            // Navigator.pushReplacementNamed(context, LoginScreen.routeName);
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
            padding: const EdgeInsets.all(10.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  CustomText24(
                    "Get Started Now",
                    color: AppColors.black,
                    bold: true,
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 20),
                  CustomText16(
                    "Enter your Full name",
                    bold: true,
                    color: AppColors.mainColor,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: nameController,
                    hintText: 'Enter your full name',
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 16),
                  CustomText16("Email", bold: true, color: AppColors.mainColor),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: emailController,
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  CustomText16(
                    "Password",
                    bold: true,
                    color: AppColors.mainColor,
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  CustomText16(
                    "Confirm Password",
                    bold: true,
                    color: AppColors.mainColor,
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  CustomText16(
                    "Phone Number",
                    bold: true,
                    color: AppColors.mainColor,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: phoneController,
                    hintText: 'Enter your phone number',
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 24),
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
