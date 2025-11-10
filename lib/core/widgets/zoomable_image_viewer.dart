import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';

/// A full-screen zoomable image viewer with pinch-to-zoom and pan support
class ZoomableImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ZoomableImageViewer({
    Key? key,
    required this.images,
    this.initialIndex = 0,
  }) : super(key: key);

  /// Show the image viewer as an overlay
  static Future<void> show(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ZoomableImageViewer(
              images: images,
              initialIndex: initialIndex,
            ),
          );
        },
      ),
    );
  }

  @override
  State<ZoomableImageViewer> createState() => _ZoomableImageViewerState();
}

class _ZoomableImageViewerState extends State<ZoomableImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Main image viewer with swipe support
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return _ZoomableImage(
                imageUrl: widget.images[index],
                onClose: () => Navigator.of(context).pop(),
              );
            },
          ),

          // Top bar with close button and counter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Close button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.white, size: 28),
                      tooltip: 'Close',
                    ),
                    Spacer(),
                    // Image counter
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation arrows (only show if multiple images)
          if (widget.images.length > 1) ...[
            // Left arrow
            if (_currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _previousImage,
                      icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      iconSize: 28,
                      tooltip: 'Previous',
                    ),
                  ),
                ),
              ),

            // Right arrow
            if (_currentIndex < widget.images.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _nextImage,
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                      iconSize: 28,
                      tooltip: 'Next',
                    ),
                  ),
                ),
              ),
          ],

          // Bottom instruction text
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pinch to zoom • Swipe to navigate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual zoomable image widget
class _ZoomableImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onClose;

  const _ZoomableImage({
    Key? key,
    required this.imageUrl,
    required this.onClose,
  }) : super(key: key);

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  static const double _minScale = 1.0;
  static const double _maxScale = 4.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    final position = details.localPosition;

    // Get current scale
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    // If already zoomed in, zoom out
    if (currentScale > _minScale + 0.1) {
      _animateZoom(_minScale, position);
    } else {
      // Zoom in to 2x
      _animateZoom(2.0, position);
    }
  }

  void _animateZoom(double targetScale, Offset focalPoint) {
    final begin = _transformationController.value;
    final end = Matrix4.identity()
      ..translate(focalPoint.dx * (1 - targetScale), focalPoint.dy * (1 - targetScale))
      ..scale(targetScale);

    _animation = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0).then((_) {
      _transformationController.value = end;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          if (_animation != null) {
            _transformationController.value = _animation!.value;
          }
          return MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              panEnabled: true,
              scaleEnabled: true,
              child: Center(
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.mainColor,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.white, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
