import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A cached network image widget with loading and error states
/// Uses cached_network_image for automatic disk and memory caching
class CachedImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const CachedImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle null or empty URL
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    // Normalize URL
    String normalizedUrl = imageUrl!;
    if (!normalizedUrl.startsWith('http')) {
      normalizedUrl = 'https://aqar.bdcbiz.com$normalizedUrl';
    }

    // Safe conversion for memory cache - handle infinity/NaN
    int? safeCacheWidth = (width != null && width!.isFinite) ? width!.toInt() : null;
    int? safeCacheHeight = (height != null && height!.isFinite) ? height!.toInt() : null;

    Widget imageWidget = CachedNetworkImage(
      imageUrl: normalizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      memCacheWidth: safeCacheWidth,
      memCacheHeight: safeCacheHeight,
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

/// A circular cached avatar image
class CachedAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedAvatarWidget({
    Key? key,
    required this.imageUrl,
    this.radius = 24,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    String normalizedUrl = imageUrl!;
    if (!normalizedUrl.startsWith('http')) {
      normalizedUrl = 'https://aqar.bdcbiz.com$normalizedUrl';
    }

    return CachedNetworkImage(
      imageUrl: normalizedUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
    );
  }

  Widget _buildPlaceholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: SizedBox(
        width: radius,
        height: radius,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: Icon(
        Icons.business,
        size: radius,
        color: Colors.grey[400],
      ),
    );
  }
}

/// A cached background image with gradient overlay
class CachedBackgroundImage extends StatelessWidget {
  final String? imageUrl;
  final Widget child;
  final BoxFit fit;
  final List<Color>? gradientColors;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;

  const CachedBackgroundImage({
    Key? key,
    required this.imageUrl,
    required this.child,
    this.fit = BoxFit.cover,
    this.gradientColors,
    this.gradientBegin = Alignment.topCenter,
    this.gradientEnd = Alignment.bottomCenter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: child,
      );
    }

    String normalizedUrl = imageUrl!;
    if (!normalizedUrl.startsWith('http')) {
      normalizedUrl = 'https://aqar.bdcbiz.com$normalizedUrl';
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: normalizedUrl,
          fit: fit,
          placeholder: (context, url) => Container(color: Colors.grey[300]),
          errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
        ),
        if (gradientColors != null)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: gradientBegin,
                end: gradientEnd,
                colors: gradientColors!,
              ),
            ),
          ),
        child,
      ],
    );
  }
}
