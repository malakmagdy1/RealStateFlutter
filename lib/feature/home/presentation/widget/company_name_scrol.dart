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

class _CompanyNameState extends State<CompanyName> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),  // Faster - was 150ms
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,  // Smaller scale - was 1.2
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,  // Snappier curve
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Vibrate on tap
    HapticFeedback.lightImpact();  // Lighter haptic

    // Execute immediately for better responsiveness
    widget.onTap();

    // Animation runs non-blocking for visual feedback
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLogo = widget.company.logo != null && widget.company.logo!.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing based on screen width - reduced size for better layout
    final double logoRadius = screenWidth * 0.08; // 8% of screen width
    final double padding = screenWidth * 0.015; // 1.5% of screen width
    final double fontSize = screenWidth * 0.04; // 4% of screen width

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _isTapped
                              ? [
                                  BoxShadow(
                                    color: AppColors.mainColor.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: CircleAvatar(
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
        },
      ),
    );
  }
}
