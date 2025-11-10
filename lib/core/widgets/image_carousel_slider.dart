import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ImageCarouselSlider extends StatefulWidget {
  final List<String> images;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;

  const ImageCarouselSlider({
    Key? key,
    required this.images,
    this.height = 200,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlayAnimationDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<ImageCarouselSlider> createState() => _ImageCarouselSliderState();
}

class _ImageCarouselSliderState extends State<ImageCarouselSlider> {
  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext) {
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 60,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Carousel Slider
        CarouselSlider.builder(
          itemCount: widget.images.length,
          carouselController: _controller,
          options: CarouselOptions(
            autoPlay: widget.autoPlay,
            height: widget.height,
            viewportFraction: 0.85,
            enlargeCenterPage: true,
            enlargeFactor: 0.25,
            autoPlayAnimationDuration: widget.autoPlayAnimationDuration,
            autoPlayInterval: widget.autoPlayInterval,
            autoPlayCurve: Curves.easeInOutSine,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
            scrollPhysics: const BouncingScrollPhysics(),
          ),
          itemBuilder: (context, index, realIdx) {
            final isActive = index == _currentIndex;

            return Padding(
              padding: EdgeInsets.only(top: isActive ? 0 : 15),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: widget.height,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey.shade500,
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
                ),
              ),
            );
          },
        ),

        // Dot Indicator - positioned below the carousel
        SizedBox(height: 12),
        Center(
          child: AnimatedSmoothIndicator(
            activeIndex: _currentIndex,
            count: widget.images.length,
            effect: ExpandingDotsEffect(
              radius: 10,
              dotWidth: 10,
              dotHeight: 10,
              activeDotColor: Colors.grey.shade700,
              expansionFactor: 4,
              dotColor: Colors.grey.shade400,
            ),
            onDotClicked: (index) {
              _controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            },
          ),
        ),
      ],
    );
  }
}
