import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/company/data/models/company_model.dart';

class CompanyName extends StatelessWidget {
  final Company company;
  final VoidCallback onTap;

  CompanyName({Key? key, required this.company, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasLogo = company.logo != null && company.logo!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(6.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.mainColor.withOpacity(0.1),
              backgroundImage: hasLogo ? NetworkImage(company.logo!) : null,
              child: !hasLogo
                  ? CustomText16(
                      company.name.isNotEmpty
                          ? company.name[0].toUpperCase()
                          : '?',
                      bold: true,
                      color: AppColors.mainColor,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
