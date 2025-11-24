import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';
import 'package:real/feature/home/presentation/CustomNav.dart';
import 'package:real/feature/onboarding/presentation/onboarding_screen.dart';
import 'package:real/core/services/version_service.dart';
import 'package:real/core/widgets/force_logout_dialog.dart';

class SplashScreen extends StatefulWidget {
  static String routeName = '/splash';

  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || _hasNavigated) return;

    String tokenValue = '';
    String hasSeenOnboarding = '';

    if (kIsWeb) {
      tokenValue = token ?? '';
      hasSeenOnboarding = 'true';
    } else {
      tokenValue = await CasheNetwork.getCasheDataAsync(key: 'token');
      hasSeenOnboarding =
      await CasheNetwork.getCasheDataAsync(key: 'hasSeenOnboarding');
    }

    final isLoggedIn = tokenValue.isNotEmpty;
    final shouldShowOnboarding = !kIsWeb && hasSeenOnboarding.isEmpty;

    // ⚠️ CHECK FOR VERSION UPDATE - FORCE LOGOUT IF NEEDED
    if (isLoggedIn) {
      final shouldForceLogout = await VersionService.shouldForceLogout();
      if (shouldForceLogout && mounted) {
        print('[SPLASH] 🔄 Version update detected - showing force logout dialog');
        _hasNavigated = true;

        // Navigate to appropriate screen first
        if (kIsWeb) {
          context.go('/');
        } else {
          if (shouldShowOnboarding) {
            await CasheNetwork.insertToCashe(key: 'hasSeenOnboarding', value: 'true');
            Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
          } else {
            Navigator.pushReplacementNamed(context, CustomNav.routeName);
          }
        }

        // Show force logout dialog after navigation
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await ForceLogoutDialog.show(context);
        }
        return;
      }
    }

    _hasNavigated = true;

    if (kIsWeb) {
      if (isLoggedIn) {
        context.go('/');
      } else {
        context.go('/login');
      }
    } else {
      if (shouldShowOnboarding) {
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
                child: Image.asset(
                  'assets/images/logos/appIcon.png',
                  width: 500,
                  height: 500,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.apartment,
                      size: 150,
                      color: AppColors.mainColor,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
