import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/constant.dart';

class WebSplashScreen extends StatefulWidget {
  const WebSplashScreen({Key? key}) : super(key: key);

  @override
  State<WebSplashScreen> createState() => _WebSplashScreenState();
}

class _WebSplashScreenState extends State<WebSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for splash screen duration
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is logged in using the global token
    final isLoggedIn = token != null && token!.isNotEmpty;

    // Navigate based on authentication status
    if (isLoggedIn) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 250,
          height: 250,
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A4D2E),
                Color(0xFF2D6A4F),
              ],
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logos/appIcon.png',
            width: 240,
            height: 240,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.apartment,
                size: 200,
                color: Colors.white,
              );
            },
          ),
        ),
      ),
    );
  }
}
