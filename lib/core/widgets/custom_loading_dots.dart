import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomLoadingDots extends StatefulWidget {
  final double size;

  const CustomLoadingDots({Key? key, this.size = 100}) : super(key: key);

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
    // إعداد الأنيميشن للدوران الكامل
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // سرعة الدوران
    );
    // تشغيل الأنيميشن بشكل متكرر
    _controller.repeat();
    print('[LOADING DOTS] Animation started - should repeat continuously');
  }

  @override
  void didUpdateWidget(CustomLoadingDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure animation is running when widget updates
    if (!_controller.isAnimating) {
      print('[LOADING DOTS] Animation stopped, restarting...');
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    print('[LOADING DOTS] Widget disposed - animation will stop');
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
