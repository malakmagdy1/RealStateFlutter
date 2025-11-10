import 'package:flutter/material.dart';

/// A widget that scales up on hover with smooth animation
/// Uses AnimatedContainer with easeOut curve and transform
class HoverScaleAnimation extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;

  const HoverScaleAnimation({
    Key? key,
    required this.child,
    this.scale = 1.03,
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<HoverScaleAnimation> createState() => _HoverScaleAnimationState();
}

class _HoverScaleAnimationState extends State<HoverScaleAnimation> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isHovered ? widget.scale : 1.0),
        child: widget.child,
      ),
    );
  }
}
