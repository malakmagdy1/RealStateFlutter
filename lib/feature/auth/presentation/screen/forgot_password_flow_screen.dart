import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/core/widget/button/authButton.dart';
import 'package:real/feature/auth/data/web_services/auth_web_services.dart';
import 'package:real/feature/auth/data/models/forgot_password_step1_request.dart';
import 'package:real/feature/auth/data/models/verify_reset_code_request.dart';
import 'package:real/feature/auth/data/models/reset_password_request.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';
import '../widget/textFormField.dart';
import 'dart:async';

class ForgotPasswordFlowScreen extends StatefulWidget {
  static String routeName = '/forgot-password-flow';

  const ForgotPasswordFlowScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordFlowScreen> createState() => _ForgotPasswordFlowScreenState();
}

class _ForgotPasswordFlowScreenState extends State<ForgotPasswordFlowScreen> {
  final PageController _pageController = PageController();
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
    _pageController.dispose();
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
        });
        _startResendCooldown();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          currentStep = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitStep2() async {
    final code = codeControllers.map((c) => c.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
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
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          currentStep = 2;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login or home screen
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            if (currentStep > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() {
                currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: CustomText18('Reset Password', color: AppColors.black, bold: true),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
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
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            CustomText24('Enter Your Email', color: AppColors.black, bold: true),
            const SizedBox(height: 12),
            CustomText16(
              'We will send a 6-digit verification code to your email address',
              color: Colors.grey[600]!,
            ),
            const SizedBox(height: 32),
            CustomText16('Email Address', bold: true, color: AppColors.mainColor),
            const SizedBox(height: 8),
            CustomTextField(
              controller: emailController,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 32),
            AuthButton(
              action: _submitStep1,
              text: isLoading ? 'Sending...' : 'Send Code',
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          CustomText24('Verify Code', color: AppColors.black, bold: true),
          const SizedBox(height: 12),
          CustomText16(
            'Enter the 6-digit code sent to ${emailController.text}',
            color: Colors.grey[600]!,
          ),
          const SizedBox(height: 8),
          CustomText14(
            'Code expires in $expiresInMinutes minutes',
            color: Colors.orange,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 50,
                child: TextField(
                  controller: codeControllers[index],
                  focusNode: codeFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
          Center(
            child: TextButton(
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
          ),
          const SizedBox(height: 32),
          AuthButton(
            action: _submitStep2,
            text: isLoading ? 'Verifying...' : 'Verify Code',
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            CustomText24('Create New Password', color: AppColors.black, bold: true),
            const SizedBox(height: 12),
            CustomText16(
              'Your new password must be different from previously used passwords',
              color: Colors.grey[600]!,
            ),
            const SizedBox(height: 32),
            CustomText16('New Password', bold: true, color: AppColors.mainColor),
            const SizedBox(height: 8),
            CustomTextField(
              controller: passwordController,
              hintText: 'Enter new password',
              obscureText: _obscurePassword,
              validator: Validators.validatePassword,
              suffixIcon: _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              onSuffixTap: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomText16('Confirm Password', bold: true, color: AppColors.mainColor),
            const SizedBox(height: 8),
            CustomTextField(
              controller: confirmPasswordController,
              hintText: 'Confirm new password',
              obscureText: _obscureConfirmPassword,
              validator: (value) => Validators.validateConfirmPassword(
                value,
                passwordController.text,
              ),
              suffixIcon: _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              onSuffixTap: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            const SizedBox(height: 32),
            AuthButton(
              action: _submitStep3,
              text: isLoading ? 'Resetting...' : 'Reset Password',
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
