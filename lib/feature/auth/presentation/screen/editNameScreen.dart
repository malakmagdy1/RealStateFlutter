import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/auth/data/models/update_name_request.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_event.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_event.dart';

import '../../../../core/widget/button/authButton.dart';
import '../widget/textFormField.dart';

class EditNameScreen extends StatefulWidget {
  static String routeName = '/edit-name';

  @override
  State<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends State<EditNameScreen> {
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdateNameBloc, UpdateNameState>(
      listener: (context, state) {
        if (state is UpdateNameSuccess) {
          MessageHelper.showSuccess(context, state.response.message);
          context.read<UserBloc>().add(FetchUserEvent());
          Navigator.pop(context); // Close bottom sheet
        } else if (state is UpdateNameError) {
          MessageHelper.showError(context, state.message);
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
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
                // ===== Header Icon =====
                Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 48,
                      color: AppColors.mainColor,
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // ===== Title =====
                Center(
                  child: CustomText20(
                    "Update Your Name",
                    bold: true,
                    color: AppColors.mainColor,
                  ),
                ),

                SizedBox(height: 12),

                // ===== Subtitle =====
                Center(
                  child: CustomText16(
                    "Enter your new name to update your profile",
                    color: AppColors.greyText,
                  ),
                ),

                SizedBox(height: 32),

                CustomText16("Name", bold: true, color: AppColors.mainColor),

                SizedBox(height: 8),

                CustomTextField(
                  controller: nameController,
                  hintText: 'Enter your name',
                  validator: Validators.validateName,
                ),

                SizedBox(height: 32),

                // ===== Button =====
                BlocBuilder<UpdateNameBloc, UpdateNameState>(
                  builder: (context, state) {
                    final isLoading = state is UpdateNameLoading;

                    return AuthButton(
                      action: () {
                        if (_formKey.currentState!.validate()) {
                          final request = UpdateNameRequest(
                            name: nameController.text,
                          );
                          context.read<UpdateNameBloc>().add(
                            UpdateNameSubmitEvent(request),
                          );
                        }
                      },
                      text: isLoading ? 'Updating...' : 'Update Name',
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

