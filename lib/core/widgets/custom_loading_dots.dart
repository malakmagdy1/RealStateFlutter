import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomLoadingDots extends StatefulWidget {
  final double size;

  CustomLoadingDots({Key? key, this.size = 100}) : super(key: key);

  @override
  State<CustomLoadingDots> createState() => _CustomLoadingDotsState();
}

class _CustomLoadingDotsState extends State<CustomLoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // ألوان الدوائر مستوحاة من الفيديو اللي أرسلته
  final List<Color> _dotColors = [
    const Color(0xFFC7F9CC), // فاتح مرة
    const Color(0xFF80ED99),
    const Color(0xFF57CC99),
    const Color(0xFF38A3A5),
    const Color(0xFF22577A),
    const Color(0xFF1B435D), // غامق
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    // إعداد الأنيميشن للدوران الكامل
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // سرعة الدوران
    );

    // تشغيل الأنيميشن بشكل متكرر بدون توقف
    _controller.repeat();

    // Add listener to ensure it keeps repeating
    _controller.addStatusListener(_onAnimationStatus);

    print('[LOADING DOTS] Animation initialized and started - will repeat indefinitely');
  }

  void _onAnimationStatus(AnimationStatus status) {
    // If animation somehow stops or completes, restart it
    if (status == AnimationStatus.dismissed || status == AnimationStatus.completed) {
      print('[LOADING DOTS] Animation status changed to $status - restarting repeat');
      if (mounted) {
        _controller.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(CustomLoadingDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure animation is always running when widget updates
    if (!_controller.isAnimating) {
      print('[LOADING DOTS] Animation not running after update - restarting...');
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure animation continues after dependency changes
    if (!_controller.isAnimating) {
      print('[LOADING DOTS] Dependencies changed, animation not running - restarting...');
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    print('[LOADING DOTS] Widget disposed - stopping animation');
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: child,
          );
        },
        // رسم الدوائر وترتيبها بشكل دائري
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(6, (index) {
            // حساب الزاوية لكل دائرة (60 درجة بين كل وحدة)
            final double angle = (index * 60) * (math.pi / 180);
            final double radius = widget.size / 3.5;

            return Transform.translate(
              offset: Offset(
                radius * math.cos(angle),
                radius * math.sin(angle),
              ),
              child: Container(
                width: widget.size / 6, // حجم النقطة بالنسبة للحجم الكلي
                height: widget.size / 6,
                decoration: BoxDecoration(
                  color: _dotColors[index],
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
