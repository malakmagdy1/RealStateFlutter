import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';
import 'package:real/feature/home/presentation/CustomNav.dart';

class SplashScreen extends StatefulWidget {
  static String routeName = '/splash';

  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for splash screen duration
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || _hasNavigated) return;

    // Check if user is logged in
    String tokenValue = '';

    if (kIsWeb) {
      // For web, use the global token from constant.dart
      tokenValue = token ?? '';
    } else {
      // For mobile, use CasheNetwork
      tokenValue = await CasheNetwork.getCasheDataAsync(key: 'token');
    }

    final isLoggedIn = tokenValue.isNotEmpty;

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
      // Mobile: Use traditional navigation
      if (isLoggedIn) {
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
      backgroundColor: kIsWeb ? Colors.white : AppColors.mainColor,
      body: Center(
        child: SvgPicture.asset(
          // Use logo without background for web, logo with green bg for mobile
          kIsWeb
            ? 'assets/images/logos/logo.svg'
            : 'assets/images/logos/logo.svg',
          width: kIsWeb ? screenWidth * 0.4 : screenWidth * 0.6,
          height: kIsWeb ? screenHeight * 0.4 : screenHeight * 0.4,
        ),
      ),
    );
  }
}

