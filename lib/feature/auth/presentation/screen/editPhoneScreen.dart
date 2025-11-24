import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/auth/data/models/update_phone_request.dart';
import 'package:real/feature/auth/presentation/bloc/update_phone_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/update_phone_event.dart';
import 'package:real/feature/auth/presentation/bloc/update_phone_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_event.dart';

import '../../../../core/widget/button/authButton.dart';
import '../widget/textFormField.dart';

class EditPhoneScreen extends StatefulWidget {
  static String routeName = '/edit-phone';

  @override
  State<EditPhoneScreen> createState() => _EditPhoneScreenState();
}

class _EditPhoneScreenState extends State<EditPhoneScreen> {
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdatePhoneBloc, UpdatePhoneState>(
      listener: (context, state) {
        if (state is UpdatePhoneSuccess) {
          MessageHelper.showSuccess(context, state.response.message);
          context.read<UserBloc>().add(FetchUserEvent());
          Navigator.pop(context); // Close bottom sheet
        } else if (state is UpdatePhoneError) {
          MessageHelper.showError(context, state.message);
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_outlined,
                      size: 48,
                      color: AppColors.mainColor,
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Title
                Center(
                  child: CustomText20(
                    "Update Phone Number",
                    bold: true,
                    color: AppColors.mainColor,
                  ),
                ),

                SizedBox(height: 12),

                Center(
                  child: CustomText16(
                    "Enter your new phone number to update your profile",
                    color: AppColors.greyText,
                  ),
                ),

                SizedBox(height: 32),

                CustomText16(
                  "Phone Number",
                  bold: true,
                  color: AppColors.mainColor,
                ),

                SizedBox(height: 8),

                CustomTextField(
                  controller: phoneController,
                  hintText: 'Enter your phone number',
                  validator: Validators.validatePhone,
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 32),

                BlocBuilder<UpdatePhoneBloc, UpdatePhoneState>(
                  builder: (context, state) {
                    final isLoading = state is UpdatePhoneLoading;
                    return AuthButton(
                      action: () {
                        if (_formKey.currentState!.validate()) {
                          final request = UpdatePhoneRequest(
                            phone: phoneController.text,
                          );
                          context.read<UpdatePhoneBloc>().add(
                            UpdatePhoneSubmitEvent(request),
                          );
                        }
                      },
                      text: isLoading ? 'Updating...' : 'Update Phone',
                      isLoading: isLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
