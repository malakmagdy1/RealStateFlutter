import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';

class BlockedUserScreen extends StatelessWidget {
  static String routeName = '/blocked-user';

  final String reason;
  final String message;
  final IconData icon;
  final Color iconColor;

  const BlockedUserScreen({
    Key? key,
    required this.reason,
    required this.message,
    this.icon = Icons.block,
    this.iconColor = Colors.red,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 60,
                    color: iconColor,
                  ),
                ),
                SizedBox(height: 32),

                // Reason Title
                CustomText24(
                  reason,
                  bold: true,
                  color: AppColors.black,
                  align: TextAlign.center,
                ),
                SizedBox(height: 16),

                // Message
                CustomText16(
                  message,
                  color: AppColors.greyText,
                  align: TextAlign.center,
                ),
                SizedBox(height: 48),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Clear token and user data
                      await CasheNetwork.deletecasheItem(key: "token");
                      await CasheNetwork.deletecasheItem(key: "user_id");

                      // Navigate to login
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        LoginScreen.routeName,
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: CustomText16(
                      'Logout',
                      color: AppColors.white,
                      bold: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
