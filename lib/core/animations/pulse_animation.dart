import 'package:flutter/material.dart';

/// A widget that creates a pulse animation (scale up, down, and vibrate)
/// Perfect for notification icons, favorite icons, share buttons, etc.
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration duration;

  const PulseAnimation({
    Key? key,
    required this.child,
    this.animate = false,
    this.duration = const Duration(milliseconds: 600),
  }) : super(key: key);

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Scale animation: 1.0 -> 1.3 -> 0.9 -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.9).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 34,
      ),
    ]).animate(_controller);

    // Shake animation: vibrate left-right
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 5.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 5.0, end: -5.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: -5.0, end: 5.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 5.0, end: 0.0), weight: 25),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Controller to trigger pulse animation programmatically
class PulseAnimationController extends StatefulWidget {
  final Widget Function(BuildContext context, VoidCallback pulse) builder;

  const PulseAnimationController({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  State<PulseAnimationController> createState() =>
      _PulseAnimationControllerState();
}

class _PulseAnimationControllerState extends State<PulseAnimationController>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.9).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 34,
      ),
    ]).animate(_controller);

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 5.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 5.0, end: -5.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: -5.0, end: 5.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 5.0, end: 0.0), weight: 25),
    ]).animate(_controller);
  }

  void _pulse() {
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.builder(context, _pulse),
          ),
        );
      },
    );
  }
}
