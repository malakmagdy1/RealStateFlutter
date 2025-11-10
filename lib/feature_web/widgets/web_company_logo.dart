import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/company/data/models/company_model.dart';

/// Web-specific company logo widget with hover animations
/// Separated from mobile version to maintain platform independence
class WebCompanyLogo extends StatefulWidget {
  final Company company;
  final VoidCallback? onTap;

  const WebCompanyLogo({
    Key? key,
    required this.company,
    this.onTap,
  }) : super(key: key);

  @override
  State<WebCompanyLogo> createState() => _WebCompanyLogoState();
}

class _WebCompanyLogoState extends State<WebCompanyLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;

    // Call onTap immediately for better responsiveness
    widget.onTap!();

    // Animate for visual feedback (non-blocking)
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLogo =
        widget.company.logo != null && widget.company.logo!.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovering = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: _isHovering
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
                            radius: 35,
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            backgroundImage: hasLogo
                                ? NetworkImage(widget.company.logo!)
                                : null,
                            child: !hasLogo
                                ? CustomText16(
                                    widget.company.name.isNotEmpty
                                        ? widget.company.name[0].toUpperCase()
                                        : '?',
                                    bold: true,
                                    color: AppColors.mainColor,
                                  )
                                : null,
                          ),
                        ),
                        // Update Badge (NEW)
                        if (widget.company.updatedUnitsCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF3B30).withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${widget.company.updatedUnitsCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
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
      ),
    );
  }
}
