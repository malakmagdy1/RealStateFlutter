import 'package:flutter/material.dart';

/// Responsive utilities for making dimensions adaptive across different screen sizes
/// while maintaining the same proportions
class ResponsiveUtils {
  static late double _designWidth;
  static late double _designHeight;
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _widthRatio;
  static late double _heightRatio;

  /// Initialize with design dimensions (the dimensions you designed for)
  /// Default: 375x812 (iPhone X/11 Pro size)
  static void init(BuildContext context, {double designWidth = 375, double designHeight = 812}) {
    _designWidth = designWidth;
    _designHeight = designHeight;
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    _widthRatio = _screenWidth / _designWidth;
    _heightRatio = _screenHeight / _designHeight;
  }

  /// Get responsive width
  /// Example: rw(100) returns 100 scaled to screen width
  static double rw(double width) {
    return width * _widthRatio;
  }

  /// Get responsive height
  /// Example: rh(50) returns 50 scaled to screen height
  static double rh(double height) {
    return height * _heightRatio;
  }

  /// Get responsive font size
  /// Example: rfs(16) returns 16 scaled appropriately
  static double rfs(double fontSize) {
    // Use average of width and height ratios for font scaling
    return fontSize * ((_widthRatio + _heightRatio) / 2);
  }

  /// Get responsive size (uses width ratio by default)
  /// Example: rs(20) returns 20 scaled to screen width
  static double rs(double size) {
    return size * _widthRatio;
  }

  /// Get screen width
  static double get screenWidth => _screenWidth;

  /// Get screen height
  static double get screenHeight => _screenHeight;

  /// Check if device is tablet (width > 600)
  static bool get isTablet => _screenWidth > 600;

  /// Check if device is mobile
  static bool get isMobile => _screenWidth <= 600;
}

/// Extension on BuildContext for easy access
extension ResponsiveExtension on BuildContext {
  /// Responsive width
  double rw(double width) => ResponsiveUtils.rw(width);

  /// Responsive height
  double rh(double height) => ResponsiveUtils.rh(height);

  /// Responsive font size
  double rfs(double fontSize) => ResponsiveUtils.rfs(fontSize);

  /// Responsive size
  double rs(double size) => ResponsiveUtils.rs(size);

  /// Screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Is tablet
  bool get isTablet => screenWidth > 600;

  /// Is mobile
  bool get isMobile => screenWidth <= 600;
}
