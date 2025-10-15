import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';

class AuthToggle extends StatelessWidget {
  final bool isSignUp;
  final VoidCallback onSignUpPressed;
  final VoidCallback onLoginPressed;

  const AuthToggle({
    Key? key,
    required this.isSignUp,
    required this.onSignUpPressed,
    required this.onLoginPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: AppColors.grey,
      ),
      child: Row(
        children: [
          // Sign Up button
          Expanded(
            child: ElevatedButton(
              onPressed: onSignUpPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSignUp
                    ? AppColors.mainColor
                    : Colors.transparent,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: CustomText16(
                'Sign Up',
                bold: isSignUp,
                color: isSignUp ? AppColors.white : AppColors.black,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Log In button
          Expanded(
            child: ElevatedButton(
              onPressed: onLoginPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: !isSignUp
                    ? AppColors.mainColor
                    : Colors.transparent,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: CustomText16(
                'Log In',
                bold: !isSignUp,
                color: !isSignUp ? AppColors.white : AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
