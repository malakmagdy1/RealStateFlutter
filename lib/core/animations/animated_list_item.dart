import 'package:flutter/material.dart';

/// Animated list item that fades in and slides up
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const AnimatedListItem({
    Key? key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animation with delay based on index
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Smooth scroll physics for better scrolling experience
class SmoothScrollPhysics extends ScrollPhysics {
  const SmoothScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 50,
        stiffness: 100,
        damping: 1,
      );
}

/// Animated scroll view with smooth physics
class AnimatedScrollView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool animateItems;

  const AnimatedScrollView({
    Key? key,
    required this.children,
    this.padding,
    this.physics,
    this.animateItems = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: children.length,
      itemBuilder: (context, index) {
        if (animateItems) {
          return AnimatedListItem(
            index: index,
            child: children[index],
          );
        }
        return children[index];
      },
    );
  }
}

/// Staggered animation for grid items
class StaggeredGridAnimation extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delay;

  const StaggeredGridAnimation({
    Key? key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedListItem(
      index: index,
      delay: delay,
      child: child,
    );
  }
}
