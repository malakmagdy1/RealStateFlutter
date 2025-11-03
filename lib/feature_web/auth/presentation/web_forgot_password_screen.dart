import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/feature/auth/data/web_services/auth_web_services.dart';
import 'package:real/feature/auth/data/models/forgot_password_step1_request.dart';
import 'package:real/feature/auth/data/models/verify_reset_code_request.dart';
import 'package:real/feature/auth/data/models/reset_password_request.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'dart:async';

class WebForgotPasswordScreen extends StatefulWidget {
  static String routeName = '/web-forgot-password';

  const WebForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<WebForgotPasswordScreen> createState() => _WebForgotPasswordScreenState();
}

class _WebForgotPasswordScreenState extends State<WebForgotPasswordScreen> {
  final AuthWebServices _authWebServices = AuthWebServices();

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final List<TextEditingController> codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> codeFocusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Form keys
  final GlobalKey<FormState> step1FormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> step3FormKey = GlobalKey<FormState>();

  // State variables
  int currentStep = 0;
  bool isLoading = false;
  String? resetToken;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int expiresInMinutes = 15;
  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void dispose() {
    emailController.dispose();
    for (var controller in codeControllers) {
      controller.dispose();
    }
    for (var node in codeFocusNodes) {
      node.dispose();
    }
    passwordController.dispose();
    confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    setState(() {
      _resendCooldown = 60;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _submitStep1() async {
    if (!step1FormKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final request = ForgotPasswordStep1Request(email: emailController.text.trim());
      final response = await _authWebServices.requestPasswordReset(request);

      if (response.success) {
        setState(() {
          expiresInMinutes = response.expiresInMinutes ?? 15;
          currentStep = 1;
        });
        _startResendCooldown();
        _showSnackBar(response.message, Colors.green);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitStep2() async {
    final code = codeControllers.map((c) => c.text).join();
    if (code.length != 6) {
      _showSnackBar('Please enter the complete 6-digit code', Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final request = VerifyResetCodeRequest(
        email: emailController.text.trim(),
        code: code,
      );
      final response = await _authWebServices.verifyResetCode(request);

      if (response.success && response.resetToken != null) {
        setState(() {
          resetToken = response.resetToken;
          currentStep = 2;
        });
        _showSnackBar(response.message, Colors.green);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitStep3() async {
    if (!step3FormKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final request = ResetPasswordRequest(
        email: emailController.text.trim(),
        resetToken: resetToken!,
        password: passwordController.text,
        passwordConfirmation: confirmPasswordController.text,
      );
      final response = await _authWebServices.resetPassword(request);

      if (response.success && response.token != null) {
        // Auto-login: Save token
        await CasheNetwork.insertToCashe(key: 'token', value: response.token!);

        _showSnackBar(response.message, Colors.green);

        // Navigate back to login
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0) return;

    setState(() {
      isLoading = true;
    });

    try {
      final request = ForgotPasswordStep1Request(email: emailController.text.trim());
      final response = await _authWebServices.requestPasswordReset(request);

      if (response.success) {
        _startResendCooldown();
        // Clear code fields
        for (var controller in codeControllers) {
          controller.clear();
        }
        codeFocusNodes[0].requestFocus();

        _showSnackBar('Verification code sent successfully', Colors.green);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    if (currentStep > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            currentStep--;
                          });
                        },
                      ),
                    const Expanded(
                      child: Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (currentStep > 0) const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Indicator
                Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= currentStep ? AppColors.mainColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Step Content
                if (currentStep == 0) _buildStep1(),
                if (currentStep == 1) _buildStep2(),
                if (currentStep == 2) _buildStep3(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter Your Email',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We will send a 6-digit verification code to your email address',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.mainColor, width: 2),
              ),
            ),
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submitStep1,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verify Code',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the 6-digit code sent to ${emailController.text}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Code expires in $expiresInMinutes minutes',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 60,
              child: TextFormField(
                controller: codeControllers[index],
                focusNode: codeFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.length == 1 && index < 5) {
                    codeFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    codeFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _resendCooldown > 0 ? null : _resendCode,
          child: Text(
            _resendCooldown > 0
                ? 'Resend code in ${_resendCooldown}s'
                : 'Resend Code',
            style: TextStyle(
              color: _resendCooldown > 0 ? Colors.grey : AppColors.mainColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitStep2,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Form(
      key: step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create New Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your new password must be different from previously used passwords',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: 'Enter new password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.mainColor, width: 2),
              ),
            ),
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Confirm new password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.mainColor, width: 2),
              ),
            ),
            validator: (value) => Validators.validateConfirmPassword(
              value,
              passwordController.text,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submitStep3,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
