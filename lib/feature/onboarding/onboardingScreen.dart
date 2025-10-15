import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/auth/presentation/screen/SignupScreen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../auth/presentation/screen/loginScreen.dart';
import 'onboarding.dart';

class OnboardingScreen extends StatefulWidget {
  static const String routeName = '/onboarding2';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView(
            controller: _controller,
            children: const [
              OnboardingTemplate(
                "Find Your Perfect Home",
                "assets/images/onboarding1.jpg",
                "Explore thousands of properties tailored to your lifestyle. Whether you’re buying or renting, we’ll help you find the perfect place with ease.",
              ),
              OnboardingTemplate(
                "Everything You Need in One App",
                "assets/images/onboarding2.jpg",
                "Whether you’re buying, selling, or renting, manage every step with ease — all in one place.",
              ),
              OnboardingTemplate(
                "Contact Agents Instantly",
                "assets/images/try.jpg",
                "Get in touch directly with verified agents, schedule visits, and close your deal securely — all within the app.",
              ),
            ],
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: AppColors.white,
                    dotColor: Colors.white54,
                    dotHeight: 8,
                    dotWidth: 8,
                    spacing: 6,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, SignUpScreen.routeName);
                  },
                  child: CustomText16(
                    "Skip",
                    bold: true,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
