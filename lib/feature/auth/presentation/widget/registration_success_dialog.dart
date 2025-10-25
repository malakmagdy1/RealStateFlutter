import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/button/authButton.dart';
import 'package:real/feature/auth/data/models/user_model.dart';

class RegistrationSuccessDialog extends StatelessWidget {
  final String message;
  final UserModel user;
  final bool emailSent;
  final String? verificationUrl;
  final VoidCallback onClose;

  RegistrationSuccessDialog({
    Key? key,
    required this.message,
    required this.user,
    required this.emailSent,
    this.verificationUrl,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              SizedBox(height: 20),

              // Title
              CustomText24(
                'Registration Successful!',
                color: AppColors.black,
                bold: true,
                align: TextAlign.center,
              ),
              SizedBox(height: 12),

              // Message
              CustomText16(
                message,
                color: AppColors.black,
                align: TextAlign.center,
              ),
              SizedBox(height: 24),

              // User Details Container
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText16(
                      'Account Details',
                      bold: true,
                      color: AppColors.mainColor,
                    ),
                    SizedBox(height: 12),
                    _buildDetailRow('Name', user.name),
                    SizedBox(height: 8),
                    _buildDetailRow('Email', user.email),
                    SizedBox(height: 8),
                    _buildDetailRow('Phone', user.phone),
                    SizedBox(height: 8),
                    _buildDetailRow('Role', user.role),
                    if (user.id != null) ...[
                      SizedBox(height: 8),
                      _buildDetailRow('User ID', '#${user.id}'),
                    ],
                    SizedBox(height: 8),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Email Sent Status
              if (emailSent)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: CustomText16(
                          'Verification email sent!',
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 24),

              // Close Button
              AuthButton(
                action: onClose,
                text: 'Continue to Login',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText16(
          label,
          bold: true,
          color: AppColors.mainColor,
        ),
        SizedBox(height: 4),
        CustomText16(
          value,
          color: AppColors.black,
        ),
      ],
    );
  }
}
