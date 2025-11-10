import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';

class ImageSlider extends StatefulWidget {
  final List<String> images; // you pass list of images from HomeScreen
  final bool isNetworkImage; // true for network images, false for asset images

  const ImageSlider({
    super.key,
    required this.images,
    this.isNetworkImage = false,
  });

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  final PageController _pageController = PageController();
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Automatically change image every 4 seconds (like web)
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (widget.images.isEmpty) return;

      // Go to next page sequentially (like web)
      int nextPage = (_currentPage + 1) % widget.images.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Image slider
        SizedBox(
          height: 80,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: widget.isNetworkImage
                    ? Image.network(
                  widget.images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 40,
                          color: AppColors.greyText,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                )
                    : Image.asset(
                  widget.images[index],
                  fit: BoxFit.fill,
                  width: double.infinity,
                ),
              );
            },
          ),
        ),

        // Page indicators at bottom (like web)
        if (widget.images.length > 1)
          Positioned(
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.mainColor
                        : AppColors.mainColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
