import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/feature/auth/data/models/forgot_password_request.dart';
import 'package:real/feature/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/forgot_password_event.dart';
import 'package:real/feature/auth/presentation/bloc/forgot_password_state.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';

import '../../../../core/widget/button/authButton.dart';
import '../widget/textFormField.dart';

class ForgetPasswordScreen extends StatefulWidget {
  static const String routeName = '/forget-password';

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.response.message),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to login screen after successful password reset
            Navigator.pushReplacementNamed(context, LoginScreen.routeName);
          } else if (state is ForgotPasswordError) {
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
            child: Form(key: _formKey,
              child: Column(
                children: [
              const SizedBox(height: 40),
              CustomText24("Reset Password", color: AppColors.black, bold: true),
              const SizedBox(height: 20),
              CustomText16("Email",bold: true,color: AppColors.mainColor,),
              const SizedBox(height: 8),
              CustomTextField(
                controller: emailController,
                hintText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              CustomText16("New Password",bold: true,color: AppColors.mainColor,),
              const SizedBox(height: 8),
              CustomTextField(
                controller: newPasswordController,
                hintText: 'Enter new password',
                obscureText: _obscureNewPassword,
                validator: Validators.validatePassword,
                suffixIcon: _obscureNewPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              const SizedBox(height: 16),
              CustomText16("Confirm New Password",bold: true,color: AppColors.mainColor,),
              const SizedBox(height: 8),
              CustomTextField(
                controller: confirmNewPasswordController,
                hintText: 'Confirm new password',
                obscureText: _obscureConfirmPassword,
                validator: (value) => Validators.validateConfirmPassword(
                  value,
                  newPasswordController.text,
                ),
                suffixIcon: _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              const SizedBox(height: 24),
              BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                builder: (context, state) {
                  final isLoading = state is ForgotPasswordLoading;
                  return AuthButton(
                    action: () {
                      if (_formKey.currentState!.validate()) {
                        final request = ForgotPasswordRequest(
                          email: emailController.text,
                          newPassword: newPasswordController.text,
                        );
                        context.read<ForgotPasswordBloc>().add(
                          ForgotPasswordSubmitEvent(request),
                        );
                      }
                    },
                    text: isLoading ? 'Resetting...' : 'Reset Password',
                    isLoading: isLoading,
                  );
                },
              )
                ],
              ),
            ),
          ),
        )
      )
    );
  }
}
