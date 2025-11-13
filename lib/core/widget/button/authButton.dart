import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';

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
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      onPressed: isLoading ? null : action,
      child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomLoadingDots(size: 30),
                SizedBox(width: 8),
                CustomText16(text),
              ],
            )
          : CustomText16(text),
    );
  }
}
