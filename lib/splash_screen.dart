import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';
import 'package:real/feature/home/presentation/CustomNav.dart';
import 'package:real/feature/onboarding/presentation/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  static String routeName = '/splash';

  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    // Scale animation: starts from 1.5 (large) and shrinks to 1.0 (normal)
    _scaleAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Fade animation: starts from 0.0 and fades to 1.0
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Start animation
    _animationController.forward();

    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for splash screen duration
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || _hasNavigated) return;

    // Check if user is logged in
    String tokenValue = '';
    String hasSeenOnboarding = '';

    if (kIsWeb) {
      // For web, use the global token from constant.dart
      tokenValue = token ?? '';
      hasSeenOnboarding = 'true'; // Web users skip onboarding
    } else {
      // For mobile, use CasheNetwork
      tokenValue = await CasheNetwork.getCasheDataAsync(key: 'token');
      hasSeenOnboarding = await CasheNetwork.getCasheDataAsync(key: 'hasSeenOnboarding');
    }

    final isLoggedIn = tokenValue.isNotEmpty;
    final shouldShowOnboarding = !kIsWeb && hasSeenOnboarding.isEmpty;

    // Mark as navigated to prevent double navigation
    _hasNavigated = true;

    // Navigate based on platform and authentication status
    if (kIsWeb) {
      // Web: Use GoRouter
      if (isLoggedIn) {
        context.go('/');
      } else {
        context.go('/login');
      }
    } else {
      // Mobile: Check onboarding first
      if (shouldShowOnboarding) {
        // Show onboarding for first-time users
        await CasheNetwork.insertToCashe(key: 'hasSeenOnboarding', value: 'true');
        Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
      } else if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, CustomNav.routeName);
      } else {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.mainColor,
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: screenWidth * 0.7,   // increase this value more if needed
                    child: SvgPicture.asset(
                      'assets/images/logos/logo.svg',
                      colorFilter: ColorFilter.mode(AppColors.logoColor, BlendMode.srcIn),
                    ),
                  ),
                ),
              );
            },
          ),
        )
    );
  }
}
