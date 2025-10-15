import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';

class CustomListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final double screenWidth;

  const CustomListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.grey,
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenWidth * 0.01,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.mainColor,
          size: screenWidth * 0.06,
        ),
        title: CustomText16(title, color: AppColors.black),
        subtitle: subtitle != null
            ? CustomText16(
                subtitle!,
                color: AppColors.grey,
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: screenWidth * 0.04,
          color: AppColors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
