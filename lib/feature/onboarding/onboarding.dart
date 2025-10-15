import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';

class OnboardingTemplate extends StatelessWidget {
  final String imagePath;
  final String title;
  final String textt;

  const OnboardingTemplate(
      this.title,
      this.imagePath,
      this.textt, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: const BoxDecoration(
              color: AppColors.mainColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 10,right: 10,top: 10,bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText20(
                    title,
                    bold: true,
                    color: AppColors.white,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  CustomText16(
                    textt,
                    color: AppColors.white,
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
