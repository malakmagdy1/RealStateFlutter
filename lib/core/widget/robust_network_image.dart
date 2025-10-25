import 'package:flutter/material.dart';
import 'package:real/core/utils/url_helpers.dart';

import '../utils/colors.dart';

class RobustNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? errorBuilder;
  final Widget Function(BuildContext)? loadingBuilder;

  RobustNetworkImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  State<RobustNetworkImage> createState() => _RobustNetworkImageState();
}

class _RobustNetworkImageState extends State<RobustNetworkImage> {
  bool _hasError = false;
  int _retryCount = 0;
  final int _maxRetries = 3;

  @override
  Widget build(BuildContext context) {
    // Fix the image URL for both mobile and web
    final fixedUrl = UrlHelpers.fixImageUrl(widget.imageUrl);

    if (_hasError && _retryCount >= _maxRetries) {
      return widget.errorBuilder?.call(context, widget.imageUrl) ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.shade300,
            child: Icon(Icons.broken_image, size: 50, color: AppColors.greyText),
          );
    }

    return Image.network(
      fixedUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      // Increase timeout for slow connections
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Schedule state update after build completes
          if (_hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = false;
                });
              }
            });
          }
          return child;
        }
        return widget.loadingBuilder?.call(context) ??
            Container(
              width: widget.width,
              height: widget.height,
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
      errorBuilder: (context, error, stackTrace) {
        print('[RobustNetworkImage] Error loading: ${widget.imageUrl}');
        print('[RobustNetworkImage] Error: $error');

        // Retry on connection errors (simplified for web compatibility)
        if (error.toString().contains('Connection') ||
            error.toString().contains('Failed') ||
            error.toString().contains('NetworkImage')) {
          if (_retryCount < _maxRetries) {
            // Schedule retry after build completes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _retryCount++;
              // Retry after a short delay
              Future.delayed(Duration(milliseconds: 500 * _retryCount), () {
                if (mounted) {
                  setState(() {
                    _hasError = false;
                  });
                }
              });
            });
            return widget.loadingBuilder?.call(context) ??
                Container(
                  width: widget.width,
                  height: widget.height,
                  color: Colors.grey.shade200,
                  child: Center(child: CircularProgressIndicator()),
                );
          }
        }

        // Schedule state update after build completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });

        return widget.errorBuilder?.call(context, widget.imageUrl) ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey.shade300,
              child: Icon(
                Icons.broken_image,
                size: 50,
                color: AppColors.greyText,
              ),
            );
      },
    );
  }
}
