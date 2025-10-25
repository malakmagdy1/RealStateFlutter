import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? action;
  final bool isLoading;

  AuthButton({
    required this.action,
    required this.text,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          isLoading
              ? AppColors.mainColor.withOpacity(0.6)
              : AppColors.mainColor,
        ),
        foregroundColor: WidgetStateProperty.all(AppColors.black),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      onPressed: isLoading ? null : action,
      child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                  ),
                ),
                SizedBox(width: 8),
                CustomText16(text),
              ],
            )
          : CustomText16(text),
    );
  }
}
