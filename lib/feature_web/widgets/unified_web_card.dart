import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';

/// Unified Web Card Configuration
/// This class defines all the unified dimensions and styles for web cards
class UnifiedWebCardConfig {
  // Card Dimensions
  static const double cardWidth = 280.0;
  static const double aspectRatio = 0.68;
  static const double borderRadius = 24.0;

  // Spacing
  static const double spacing = 10.0;
  static const double innerPadding = 8.0;

  // Hover Animation
  static const double hoverScaleStart = 1.0;
  static const double hoverScaleEnd = 1.03;
  static const int hoverAnimationDuration = 200; // milliseconds

  // Logo & Icons
  static const double logoSize = 24.0;
  static const double logoRadius = 12.0;
  static const double actionButtonSize = 32.0;
  static const double actionIconSize = 16.0;
  static const double phoneButtonSize = 35.0;
  static const double phoneIconSize = 20.0;

  // Badges
  static const double badgeWidth = 140.0;
  static const double badgeHeight = 25.0;
  static const double badgeRotation = 0.785398; // 45 degrees in radians

  // Text Sizes
  static const double titleFontSize = 18.0;
  static const double subtitleFontSize = 13.0;
  static const double detailFontSize = 12.0;
  static const double priceFontSize = 18.0;

  // Elevation
  static const double elevationStart = 4.0;
  static const double elevationEnd = 12.0;

  // Bottom Info Container
  static const double bottomInfoOpacity = 0.90;

  // Detail Chip
  static const double detailChipHorizontalPadding = 8.0;
  static const double detailChipVerticalPadding = 4.0;
  static const double detailChipBorderRadius = 12.0;
  static const double detailChipIconSize = 14.0;
}

/// Base Unified Web Card Widget
/// Use this as a template for all web cards (Unit, Compound, Company, etc.)
class UnifiedWebCard extends StatefulWidget {
  // Card Content
  final String? imageUrl;
  final Widget? placeholder;
  final VoidCallback? onTap;

  // Top Action Buttons (Left side)
  final List<Widget>? topLeftActions;

  // Top Badges (Right side - rotated ribbons)
  final List<Widget>? topRightBadges;

  // Bottom Info Section
  final Widget bottomInfo;

  // Optional custom width (defaults to unified width)
  final double? customWidth;

  const UnifiedWebCard({
    Key? key,
    this.imageUrl,
    this.placeholder,
    this.onTap,
    this.topLeftActions,
    this.topRightBadges,
    required this.bottomInfo,
    this.customWidth,
  }) : super(key: key);

  @override
  State<UnifiedWebCard> createState() => _UnifiedWebCardState();
}

class _UnifiedWebCardState extends State<UnifiedWebCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(
        milliseconds: UnifiedWebCardConfig.hoverAnimationDuration,
      ),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: UnifiedWebCardConfig.hoverScaleStart,
      end: UnifiedWebCardConfig.hoverScaleEnd,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _elevationAnimation = Tween<double>(
      begin: UnifiedWebCardConfig.elevationStart,
      end: UnifiedWebCardConfig.elevationEnd,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _animationController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _animationController.reverse();
          },
          child: AspectRatio(
            aspectRatio: UnifiedWebCardConfig.aspectRatio,
            child: Container(
              width: widget.customWidth ?? UnifiedWebCardConfig.cardWidth,
              decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                UnifiedWebCardConfig.borderRadius,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    0.08 + (_isHovering ? 0.04 : 0.0),
                  ),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(
                  UnifiedWebCardConfig.borderRadius,
                ),
                hoverColor: AppColors.mainColor.withOpacity(0.03),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    UnifiedWebCardConfig.borderRadius,
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Background Image
                      Positioned.fill(
                        child: widget.imageUrl != null
                            ? Image.network(
                                widget.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    widget.placeholder ?? _buildDefaultPlaceholder(),
                              )
                            : widget.placeholder ?? _buildDefaultPlaceholder(),
                      ),

                      // Top Left Actions
                      if (widget.topLeftActions != null)
                        Positioned(
                          top: 20,
                          left: 12,
                          child: Row(
                            children: _intersperse(
                              widget.topLeftActions!,
                              SizedBox(width: 4),
                            ),
                          ),
                        ),

                      // Top Right Badges (Rotated Ribbons)
                      if (widget.topRightBadges != null)
                        ...widget.topRightBadges!.asMap().entries.map((entry) {
                          int index = entry.key;
                          Widget badge = entry.value;
                          return Positioned(
                            top: 8 + (index * 40.0), // Stack badges vertically
                            right: -35,
                            child: Transform.rotate(
                              angle: UnifiedWebCardConfig.badgeRotation,
                              child: badge,
                            ),
                          );
                        }).toList(),

                      // Bottom Info Container
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(UnifiedWebCardConfig.innerPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            UnifiedWebCardConfig.bottomInfoOpacity,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(
                              UnifiedWebCardConfig.borderRadius,
                            ),
                            bottomRight: Radius.circular(
                              UnifiedWebCardConfig.borderRadius,
                            ),
                          ),
                        ),
                        child: widget.bottomInfo,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFE9ECEF),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: AppColors.mainColor.withOpacity(0.3),
        ),
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> widgets, Widget separator) {
    if (widgets.isEmpty) return widgets;
    return widgets.fold<List<Widget>>([], (list, widget) {
      if (list.isNotEmpty) list.add(separator);
      list.add(widget);
      return list;
    });
  }
}

/// Unified Action Button (for favorite, share, note, compare, etc.)
class UnifiedActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const UnifiedActionButton({
    Key? key,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: UnifiedWebCardConfig.actionButtonSize,
          width: UnifiedWebCardConfig.actionButtonSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.black.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: UnifiedWebCardConfig.actionIconSize,
            color: iconColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Unified Phone Button
class UnifiedPhoneButton extends StatelessWidget {
  final VoidCallback onTap;

  const UnifiedPhoneButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: UnifiedWebCardConfig.phoneButtonSize,
          height: UnifiedWebCardConfig.phoneButtonSize,
          decoration: BoxDecoration(
            color: Color(0xFF26A69A),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFF26A69A).withOpacity(0.4),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.phone,
            color: Colors.white,
            size: UnifiedWebCardConfig.phoneIconSize,
          ),
        ),
      ),
    );
  }
}

/// Unified Badge (for sale, update, etc. - rotated ribbon style)
class UnifiedBadge extends StatelessWidget {
  final String text;
  final Color color;

  const UnifiedBadge({
    Key? key,
    required this.text,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: UnifiedWebCardConfig.badgeWidth,
      height: UnifiedWebCardConfig.badgeHeight,
      padding: EdgeInsets.only(
        left: 35,
        right: 10,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Unified Detail Chip (for bedrooms, bathrooms, area, etc.)
class UnifiedDetailChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;

  const UnifiedDetailChip({
    Key? key,
    required this.icon,
    required this.value,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.grey[700]!;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: UnifiedWebCardConfig.detailChipHorizontalPadding,
        vertical: UnifiedWebCardConfig.detailChipVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: color != null
            ? color!.withOpacity(0.1)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(
          UnifiedWebCardConfig.detailChipBorderRadius,
        ),
        border: color != null
            ? Border.all(
                color: color!.withOpacity(0.3),
                width: 1,
              )
            : null,
        boxShadow: color == null
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: UnifiedWebCardConfig.detailChipIconSize,
            color: chipColor,
          ),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: UnifiedWebCardConfig.detailFontSize,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Unified Company Logo
class UnifiedCompanyLogo extends StatelessWidget {
  final String? logoUrl;
  final double? customSize;

  const UnifiedCompanyLogo({
    Key? key,
    this.logoUrl,
    this.customSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = customSize ?? UnifiedWebCardConfig.logoSize;
    final radius = size / 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      backgroundImage: logoUrl != null && logoUrl!.isNotEmpty
          ? NetworkImage(logoUrl!)
          : null,
      child: logoUrl == null || logoUrl!.isEmpty
          ? Icon(
              Icons.business,
              size: size * 0.6,
              color: Colors.grey[600],
            )
          : null,
    );
  }
}
