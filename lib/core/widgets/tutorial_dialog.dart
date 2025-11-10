import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';

class TutorialDialog {
  /// Show a tutorial dialog with blurred background
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    List<TutorialStep>? steps,
    VoidCallback? onFinish,
    bool barrierDismissible = false,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: _TutorialDialogContent(
            title: title,
            message: message,
            steps: steps,
            onFinish: onFinish,
          ),
        ),
      ),
    );
  }

  /// Show a simple welcome dialog
  static Future<void> showWelcome({
    required BuildContext context,
    required String screenName,
    required String description,
    VoidCallback? onFinish,
  }) async {
    await show(
      context: context,
      title: 'Welcome to $screenName!',
      message: description,
      onFinish: onFinish,
    );
  }

  /// Show a tutorial with multiple steps
  static Future<void> showMultiStep({
    required BuildContext context,
    required String title,
    required List<TutorialStep> steps,
    VoidCallback? onFinish,
  }) async {
    await show(
      context: context,
      title: title,
      message: '',
      steps: steps,
      onFinish: onFinish,
    );
  }
}

class TutorialStep {
  final IconData icon;
  final String title;
  final String description;

  TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _TutorialDialogContent extends StatefulWidget {
  final String title;
  final String message;
  final List<TutorialStep>? steps;
  final VoidCallback? onFinish;

  const _TutorialDialogContent({
    required this.title,
    required this.message,
    this.steps,
    this.onFinish,
  });

  @override
  State<_TutorialDialogContent> createState() => _TutorialDialogContentState();
}

class _TutorialDialogContentState extends State<_TutorialDialogContent> {
  int currentStep = 0;

  bool get hasSteps => widget.steps != null && widget.steps!.isNotEmpty;
  bool get isLastStep => hasSteps && currentStep == widget.steps!.length - 1;

  void nextStep() {
    if (isLastStep) {
      finish();
    } else {
      setState(() {
        currentStep++;
      });
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  void finish() {
    Navigator.of(context).pop();
    widget.onFinish?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 400),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSteps ? widget.steps![currentStep].icon : Icons.lightbulb_outline,
              size: 48,
              color: AppColors.mainColor,
            ),
          ),
          SizedBox(height: 20),

          // Title
          Text(
            hasSteps ? widget.steps![currentStep].title : widget.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),

          // Message/Description
          Text(
            hasSteps ? widget.steps![currentStep].description : widget.message,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),

          // Progress indicator for multi-step
          if (hasSteps) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.steps!.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == currentStep
                        ? AppColors.mainColor
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
          ],

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasSteps && currentStep > 0)
                TextButton(
                  onPressed: previousStep,
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
              if (hasSteps && currentStep > 0) SizedBox(width: 8),
              TextButton(
                onPressed: finish,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLastStep ? 'Got it!' : (hasSteps ? 'Next' : 'Got it!'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
