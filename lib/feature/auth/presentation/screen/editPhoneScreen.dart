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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText20("Edit Phone", color: AppColors.black, bold: true),
      ),
      resizeToAvoidBottomInset: true,
      body: BlocListener<UpdatePhoneBloc, UpdatePhoneState>(
        listener: (context, state) {
          if (state is UpdatePhoneSuccess) {
            MessageHelper.showSuccess(context, state.response.message);
            // Navigate back after successful phone update
            Navigator.pop(context);
          } else if (state is UpdatePhoneError) {
            MessageHelper.showError(context, state.message);
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  CustomText16(
                    "Enter your new phone number to update your profile",
                    color: AppColors.greyText,
                  ),
                  SizedBox(height: 30),
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
                  SizedBox(height: 30),
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
      ),
    );
  }
}
