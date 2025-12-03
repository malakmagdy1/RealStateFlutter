import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:real/core/utils/url_helpers.dart';

import '../utils/colors.dart';

/// A robust network image widget with automatic disk and memory caching
/// Uses cached_network_image for efficient image loading and caching
class RobustNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? errorBuilder;
  final Widget Function(BuildContext)? loadingBuilder;
  final BorderRadius? borderRadius;

  const RobustNetworkImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fix the image URL for both mobile and web
    final fixedUrl = UrlHelpers.fixImageUrl(imageUrl);

    // Handle empty URLs
    if (fixedUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    // Safe conversion for memory cache - handle infinity/NaN
    int? safeCacheWidth = (width != null && width!.isFinite)
        ? width!.toInt()
        : null;
    int? safeCacheHeight = (height != null && height!.isFinite) ? height!
        .toInt() : null;

    Widget imageWidget = CachedNetworkImage(
      imageUrl: fixedUrl,
      fit: fit,
      width: width,
      height: height,
      // Memory cache optimization (only if dimensions are finite)
      memCacheWidth: safeCacheWidth,
      memCacheHeight: safeCacheHeight,
      // Fade animation
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      // Loading placeholder
      placeholder: (context, url) {
        return loadingBuilder?.call(context) ?? _buildLoadingWidget();
      },
      // Error widget
      errorWidget: (context, url, error) {
        print('[RobustNetworkImage] Error loading: $imageUrl');
        print('[RobustNetworkImage] Fixed URL: $fixedUrl');
        print('[RobustNetworkImage] Error: $error');
        return errorBuilder?.call(context, imageUrl) ??
            _buildErrorWidget(context);
      },
    );

    // Apply border radius if provided
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: Icon(
        Icons.broken_image,
        size: 50,
        color: AppColors.greyText,
      ),
    );
  }
}

/// A stateful version for cases that need retry logic
class RobustNetworkImageWithRetry extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? errorBuilder;
  final Widget Function(BuildContext)? loadingBuilder;
  final int maxRetries;

  const RobustNetworkImageWithRetry({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
    this.maxRetries = 3,
  }) : super(key: key);

  @override
  State<RobustNetworkImageWithRetry> createState() =>
      _RobustNetworkImageWithRetryState();
}

class _RobustNetworkImageWithRetryState
    extends State<RobustNetworkImageWithRetry> {
  int _retryCount = 0;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _currentUrl = UrlHelpers.fixImageUrl(widget.imageUrl);
  }

  @override
  void didUpdateWidget(RobustNetworkImageWithRetry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _currentUrl = UrlHelpers.fixImageUrl(widget.imageUrl);
      _retryCount = 0;
    }
  }

  void _retry() {
    if (_retryCount < widget.maxRetries) {
      setState(() {
        _retryCount++;
        // Add cache buster to force reload
        _currentUrl =
        '${UrlHelpers.fixImageUrl(widget.imageUrl)}?retry=$_retryCount';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUrl == null || _currentUrl!.isEmpty) {
      return _buildErrorWidget(context);
    }

    // Safe conversion for memory cache - handle infinity/NaN
    int? safeCacheWidth = (widget.width != null && widget.width!.isFinite)
        ? widget.width!.toInt()
        : null;
    int? safeCacheHeight = (widget.height != null && widget.height!.isFinite)
        ? widget.height!.toInt()
        : null;

    return CachedNetworkImage(
      imageUrl: _currentUrl!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      memCacheWidth: safeCacheWidth,
      memCacheHeight: safeCacheHeight,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) {
        return widget.loadingBuilder?.call(context) ?? _buildLoadingWidget();
      },
      errorWidget: (context, url, error) {
        print('[RobustNetworkImage] Error loading (retry $_retryCount): ${widget
            .imageUrl}');

        // Auto-retry on network errors
        if (_retryCount < widget.maxRetries) {
          Future.delayed(Duration(milliseconds: 500 * (_retryCount + 1)), () {
            if (mounted) _retry();
          });
          return _buildLoadingWidget();
        }

        return widget.errorBuilder?.call(context, widget.imageUrl) ??
            _buildErrorWidget(context);
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade300,
      child: Icon(
        Icons.broken_image,
        size: 50,
        color: AppColors.greyText,
      ),
    );
  }
}
