import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/feature/auth/data/models/update_name_request.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_event.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_state.dart';

import '../../../../core/widget/button/authButton.dart';
import '../widget/textFormField.dart';

class EditNameScreen extends StatefulWidget {
  static const String routeName = '/edit-name';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText20("Edit Name", color: AppColors.black, bold: true),
      ),
      resizeToAvoidBottomInset: true,
      body: BlocListener<UpdateNameBloc, UpdateNameState>(
        listener: (context, state) {
          if (state is UpdateNameSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.response.message),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate back after successful name update
            Navigator.pop(context);
          } else if (state is UpdateNameError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  CustomText16(
                    "Enter your new name to update your profile",
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 30),
                  CustomText16("Name", bold: true, color: AppColors.mainColor),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: nameController,
                    hintText: 'Enter your name',
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 30),
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
      ),
    );
  }
}
