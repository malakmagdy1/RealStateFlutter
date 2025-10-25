import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';


class CustomTextField extends StatelessWidget {
  CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false, // Default to false (more convenient)
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      cursorColor: Colors.black,
      style: TextStyle(color: Colors.black, fontSize: 16),

      // Use custom validator if provided, otherwise use default
      validator: validator ?? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },

      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixTap,
              )
            : null,
        fillColor: AppColors.white,
        filled: true,
        prefixIconColor: Colors.black,
        suffixIconColor: Colors.black,

        // Border styles
        enabledBorder: _borderStyle(Colors.blueGrey),
        focusedBorder: _borderStyle(Colors.blueGrey),
        errorBorder: _borderStyle(Colors.red),
        focusedErrorBorder: _borderStyle(Colors.red),
        disabledBorder: _borderStyle(Colors.white38),
      ),
    );
  }

  OutlineInputBorder _borderStyle(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1.2),
    );
  }
}
