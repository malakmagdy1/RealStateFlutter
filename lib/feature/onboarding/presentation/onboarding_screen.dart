import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../auth/presentation/screen/loginScreen.dart';

class OnboardingScreen extends StatefulWidget {
  static String routeName = '/onboarding';

  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/onboarding1.jpg',
      title: 'Find Your Dream Property',
      description: 'Browse through thousands of premium properties and find the perfect home for your family.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding2.jpg',
      title: 'Explore Compounds & Units',
      description: 'Discover amazing compounds with detailed information and beautiful units.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding3.jpg',
      title: 'Connect with Experts',
      description: 'Contact real estate professionals instantly for personalized help.',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Preload images silently in background (non-blocking)
    _preloadImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Preload all images to cache (non-blocking, runs in background)
  Future<void> _preloadImages() async {
    try {
      // Preload placeholder and all images in parallel
      await Future.wait([
        precacheImage(AssetImage('assets/images/placeholder.jpg'), context),
        for (final page in _pages)
          precacheImage(AssetImage(page.image), context),
      ]);
    } catch (e) {
      // Silently fail - FadeInImage will handle loading
      print('Background preload: $e');
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _skipToLogin() {
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _skipToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return FadeInImage(
                placeholder: AssetImage('assets/images/placeholder.jpg'),
                image: AssetImage(_pages[index].image),
                fit: BoxFit.cover,
                fadeInDuration: Duration(milliseconds: 150),
                fadeOutDuration: Duration(milliseconds: 100),
                placeholderFit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          // Skip button top right
          Positioned(
            top: 45,
            right: 20,
            child: TextButton(
              onPressed: _skipToLogin,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                        blurRadius: 10,
                        color: Colors.black54,
                        offset: Offset(2, 2)),
                  ],
                ),
              ),
            ),
          ),

          // Bottom semi-transparent container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 35),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    _pages[_currentPage].title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 12),

                  // Description
                  Text(
                    _pages[_currentPage].description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 20),

                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.mainColor,
                      dotColor: AppColors.mainColor.withOpacity(0.3),
                      dotHeight: 10,
                      dotWidth: 10,
                      expansionFactor: 4,
                    ),
                  ),

                  SizedBox(height: 25),

                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
