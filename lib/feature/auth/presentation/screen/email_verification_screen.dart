import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/auth/presentation/bloc/verification_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/verification_event.dart';
import 'package:real/feature/auth/presentation/bloc/verification_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_event.dart';
import 'package:real/core/widget/button/authButton.dart';
import 'package:real/feature/home/presentation/CustomNav.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  static String routeName = '/email-verification';
  final String email;

  const EmailVerificationScreen({Key? key, required this.email})
      : super(key: key);

  // Static methods for managing pending verification state
  static Future<void> clearPendingVerificationState() async {
    await CasheNetwork.deletecasheItem(key: 'pending_verification_email');
    print('[EmailVerification] Cleared pending verification state');
  }

  static Future<String?> getPendingVerificationEmail() async {
    final email = await CasheNetwork.getCasheDataAsync(key: 'pending_verification_email');
    return email.isNotEmpty ? email : null;
  }

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _countdownTimer;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _startResendCountdown();

    // Save pending verification state so user returns here if app is closed
    _savePendingVerificationState();
  }

  Future<void> _savePendingVerificationState() async {
    await CasheNetwork.insertToCashe(
      key: 'pending_verification_email',
      value: widget.email,
    );
    print('[EmailVerification] Saved pending verification state for: ${widget.email}');
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String _getCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  void _clearCode() {
    for (var controller in _codeControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _verifyCode() {
    final code = _getCode();
    if (code.length == 6) {
      context.read<VerificationBloc>().add(
            VerifyEmailEvent(
              email: widget.email,
              code: code,
            ),
          );
    } else {
      MessageHelper.showError(context, 'Please enter the complete 6-digit code');
    }
  }

  void _resendCode() {
    if (_canResend) {
      context.read<VerificationBloc>().add(
            ResendVerificationCodeEvent(email: widget.email),
          );
      _startResendCountdown();
    }
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Press back again to exit',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false;
    }
    // Exit the app
    SystemNavigator.pop();
    return true;
  }

  Widget _buildCodeInput(int index) {
    return Container(
      width: kIsWeb ? 60 : 50,
      height: kIsWeb ? 60 : 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _codeControllers[index].text.isNotEmpty
              ? AppColors.mainColor
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _codeControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: kIsWeb ? 24 : 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }

          // Auto-verify when all 6 digits are entered
          if (index == 5 && value.isNotEmpty) {
            _verifyCode();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: BlocListener<VerificationBloc, VerificationState>(
        listener: (context, state) {
          if (state is VerificationSuccess) {
            MessageHelper.showSuccess(context, state.response.message);

            print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
            print('[VerificationScreen] Email verified successfully!');
            print('[VerificationScreen] User is now logged in');
            print('[VerificationScreen] Platform: ${kIsWeb ? "Web" : "Mobile"}');
            print('[VerificationScreen] Refreshing user data...');
            print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

            // Clear pending verification state
            EmailVerificationScreen.clearPendingVerificationState();

            // Refresh user data to get updated is_verified status
            context.read<UserBloc>().add(RefreshUserEvent());

            // Navigate to home screen after successful verification
            // User is already logged in (token saved during registration)
            // Use go_router for web, Navigator for mobile
            if (kIsWeb) {
              context.go('/');
            } else {
              Navigator.pushReplacementNamed(context, CustomNav.routeName);
            }
          } else if (state is VerificationError) {
            MessageHelper.showError(context, state.message);
            if (state.remainingAttempts != null) {
              MessageHelper.showMessage(
                context: context,
                message: 'Remaining attempts: ${state.remainingAttempts}',
                isSuccess: false,
              );
            }
            _clearCode();
          } else if (state is ResendCodeSuccess) {
            MessageHelper.showSuccess(context, state.response.message);
          } else if (state is ResendCodeError) {
            MessageHelper.showError(context, state.message);
          }
        },
        child: BlocBuilder<VerificationBloc, VerificationState>(
          builder: (context, state) {
            final isLoading = state is VerificationLoading ||
                state is ResendCodeLoading;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: kIsWeb ? 40 : 24,
                  vertical: 20,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: kIsWeb ? 500 : double.infinity,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: kIsWeb ? 100 : 80,
                          height: kIsWeb ? 100 : 80,
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.email_outlined,
                            size: kIsWeb ? 50 : 40,
                            color: AppColors.mainColor,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        CustomText24(
                          'Verify Your Email',
                          color: AppColors.black,
                          bold: true,
                          align: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        CustomText16(
                          'We sent a 6-digit verification code to',
                          color: Colors.grey.shade600,
                          align: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        CustomText16(
                          widget.email,
                          color: AppColors.mainColor,
                          bold: true,
                          align: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Code Input Fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            6,
                            (index) => _buildCodeInput(index),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Verify Button
                        isLoading
                            ? const CircularProgressIndicator()
                            : AuthButton(
                                text: 'Verify Email',
                                action: _verifyCode,
                              ),
                        const SizedBox(height: 24),

                        // Resend Code
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText14(
                              "Didn't receive the code? ",
                              color: Colors.grey.shade600,
                            ),
                            if (_canResend)
                              InkWell(
                                onTap: _resendCode,
                                child: CustomText14(
                                  'Resend',
                                  color: AppColors.mainColor,
                                  bold: true,
                                ),
                              )
                            else
                              CustomText14(
                                'Resend in $_resendCountdown s',
                                color: Colors.grey.shade400,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Code expiry info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              CustomText12(
                                'Code expires in 15 minutes',
                                color: Colors.blue.shade700,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }
}
