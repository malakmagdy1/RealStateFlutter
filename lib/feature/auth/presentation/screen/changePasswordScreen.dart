import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/auth/data/models/forgot_password_request.dart';
import 'package:real/feature/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/forgot_password_event.dart';
import 'package:real/feature/auth/presentation/bloc/forgot_password_state.dart';

import '../../../../core/widget/button/authButton.dart';
import '../widget/textFormField.dart';

class ChangePasswordScreen extends StatefulWidget {
  static String routeName = '/change-password';

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText20("Change Password", color: AppColors.black, bold: true),
      ),
      resizeToAvoidBottomInset: true,
      body: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            MessageHelper.showSuccess(context, state.response.message);
            // Navigate back after successful password change
            Navigator.pop(context);
          } else if (state is ForgotPasswordError) {
            MessageHelper.showError(context, state.message);
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  CustomText16(
                    "Enter your new password to change your password",
                    color: AppColors.greyText,
                  ),
                  SizedBox(height: 30),
                  CustomText16("New Password", bold: true, color: AppColors.mainColor),
                  SizedBox(height: 8),
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
                  SizedBox(height: 16),
                  CustomText16("Confirm New Password", bold: true, color: AppColors.mainColor),
                  SizedBox(height: 8),
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
                  SizedBox(height: 30),
                  BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                    builder: (context, state) {
                      final isLoading = state is ForgotPasswordLoading;
                      return AuthButton(
                        action: () {
                          if (_formKey.currentState!.validate()) {
                            final request = ForgotPasswordRequest(
                              newPassword: newPasswordController.text,
                            );
                            context.read<ForgotPasswordBloc>().add(
                              ForgotPasswordSubmitEvent(request),
                            );
                          }
                        },
                        text: isLoading ? 'Changing...' : 'Change Password',
                        isLoading: isLoading,
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
