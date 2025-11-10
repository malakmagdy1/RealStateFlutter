import 'package:flutter/material.dart';

/// Shows a centered message overlay on the screen
/// This replaces SnackBar with a more visible centered container
class MessageHelper {
  static void showMessage({
    required BuildContext context,
    required String message,
    bool isSuccess = true,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            margin: EdgeInsets.symmetric(horizontal: 24),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  static void showSuccess(BuildContext context, String message) {
    showMessage(context: context, message: message, isSuccess: true);
  }

  static void showError(BuildContext context, String message) {
    showMessage(context: context, message: message, isSuccess: false);
  }
}
