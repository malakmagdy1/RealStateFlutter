import 'package:flutter/material.dart';

/// Fade transition for page routes
class FadePageRoute<T> extends PageRoute<T> {
  FadePageRoute({
    required this.builder,
    RouteSettings? settings,
    this.duration = const Duration(milliseconds: 300),
  }) : super(settings: settings);

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

/// Slide transition from right to left
class SlideRightRoute<T> extends PageRoute<T> {
  SlideRightRoute({
    required this.builder,
    RouteSettings? settings,
    this.duration = const Duration(milliseconds: 300),
  }) : super(settings: settings);

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    var tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }
}

/// Scale and fade transition
class ScaleRoute<T> extends PageRoute<T> {
  ScaleRoute({
    required this.builder,
    RouteSettings? settings,
    this.duration = const Duration(milliseconds: 400),
  }) : super(settings: settings);

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.easeInOutCubic;
    var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
      CurveTween(curve: curve),
    );
    var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
      CurveTween(curve: curve),
    );

    return ScaleTransition(
      scale: animation.drive(scaleTween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }
}

/// Slide and fade transition (combined)
class SlideFadeRoute<T> extends PageRoute<T> {
  SlideFadeRoute({
    required this.builder,
    RouteSettings? settings,
    this.duration = const Duration(milliseconds: 350),
  }) : super(settings: settings);

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 0.05);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    var slideTween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );
    var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(slideTween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }
}

/// Smooth scroll animation (similar to vertical scroll with curve)
class ScrollPageRoute<T> extends PageRoute<T> {
  ScrollPageRoute({
    required this.builder,
    RouteSettings? settings,
    this.duration = const Duration(milliseconds: 400),
  }) : super(settings: settings);

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.ease;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }
}

/// Helper extension to easily navigate with animations
extension NavigationExtensions on BuildContext {
  /// Navigate with fade animation
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.push<T>(
      this,
      FadePageRoute(builder: (_) => page),
    );
  }

  /// Navigate with slide animation
  Future<T?> pushSlide<T>(Widget page) {
    return Navigator.push<T>(
      this,
      SlideRightRoute(builder: (_) => page),
    );
  }

  /// Navigate with scale animation
  Future<T?> pushScale<T>(Widget page) {
    return Navigator.push<T>(
      this,
      ScaleRoute(builder: (_) => page),
    );
  }

  /// Navigate with slide and fade animation
  Future<T?> pushSlideFade<T>(Widget page) {
    return Navigator.push<T>(
      this,
      SlideFadeRoute(builder: (_) => page),
    );
  }

  /// Navigate with smooth scroll animation (vertical scroll from bottom)
  Future<T?> pushScroll<T>(Widget page) {
    return Navigator.push<T>(
      this,
      ScrollPageRoute(builder: (_) => page),
    );
  }
}
