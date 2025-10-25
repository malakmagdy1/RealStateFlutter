import 'package:flutter/material.dart';
import 'package:real/feature/onboarding/onboardingScreen.dart';

class SplashScreen extends StatefulWidget {
  static String routeName='/splash';
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate a time-consuming task (e.g., loading data) for the splash screen.
    // Replace this with your actual data loading logic.
    Future.delayed(
      Duration(seconds: 2),
          () {
        Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Image.asset("assets/images/splash.png")],
        ),
      ),
    );
  }
}

