import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/company/data/models/company_model.dart';

class CompanyName extends StatefulWidget {
  final Company company;
  final VoidCallback onTap;

  CompanyName({Key? key, required this.company, required this.onTap})
    : super(key: key);

  @override
  State<CompanyName> createState() => _CompanyNameState();
}

class _CompanyNameState extends State<CompanyName> {
  void _handleTap() {
    // Vibrate on tap
    HapticFeedback.lightImpact();
    // Execute immediately without any animation
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLogo = widget.company.logo != null && widget.company.logo!.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing based on screen width - reduced size for better layout
    final double logoRadius = screenWidth * 0.08; // 8% of screen width
    final double padding = screenWidth * 0.015; // 1.5% of screen width
    final double fontSize = screenWidth * 0.04; // 4% of screen width

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(logoRadius),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: logoRadius,
                  backgroundColor: AppColors.mainColor.withOpacity(0.1),
                  backgroundImage: hasLogo ? NetworkImage(widget.company.logo!) : null,
                  child: !hasLogo
                      ? Text(
                          widget.company.name.isNotEmpty
                              ? widget.company.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainColor,
                          ),
                        )
                      : null,
                ),
                // Update Badge (NEW) - Positioned inside bounds
                if (widget.company.updatedUnitsCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF3B30).withOpacity(0.5),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.company.updatedUnitsCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
