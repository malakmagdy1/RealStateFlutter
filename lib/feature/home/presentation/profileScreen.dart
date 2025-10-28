import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/locale/locale_cubit.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/login_event.dart';
import 'package:real/feature/auth/presentation/bloc/login_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_state.dart';
import 'package:real/feature/auth/presentation/screen/changePasswordScreen.dart';
import 'package:real/feature/auth/presentation/screen/editNameScreen.dart';
import 'package:real/feature/auth/presentation/screen/editPhoneScreen.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';
import 'package:real/feature/home/presentation/widget/customListTile.dart';
import 'package:real/feature/notifications/presentation/screens/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isPersonalInfoExpanded = false;
  bool _isSecurityExpanded = false;
  bool _isPreferencesExpanded = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleLogout(BuildContext context) {
    // Capture the LoginBloc before showing the dialog
    final loginBloc = context.read<LoginBloc>();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.logout),
          content: Text(l10n.logoutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                loginBloc.add(LogoutEvent());
              },
              child: Text(l10n.logout, style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localeCubit = context.read<LocaleCubit>();
    final currentLocale = localeCubit.state;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.language, color: AppColors.mainColor),
              SizedBox(width: 8),
              Text(l10n.selectLanguage),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageOption(
                dialogContext,
                localeCubit,
                'English',
                'en',
                currentLocale.languageCode == 'en',
              ),
              Divider(),
              _languageOption(
                dialogContext,
                localeCubit,
                'العربية',
                'ar',
                currentLocale.languageCode == 'ar',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(
    BuildContext context,
    LocaleCubit localeCubit,
    String languageName,
    String languageCode,
    bool isSelected,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        languageName,
        style: TextStyle(
          color: isSelected ? AppColors.mainColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.mainColor)
          : null,
      onTap: () {
        localeCubit.changeLocale(Locale(languageCode));
        Navigator.of(context).pop();
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.languageChanged),
            backgroundColor: AppColors.mainColor,
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LogoutSuccess) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is LogoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Profile & Settings',
            style: TextStyle(
              color: AppColors.mainColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Container(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.mainColor.withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: screenWidth * 0.28,
                            height: screenWidth * 0.28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.mainColor.withOpacity(0.2),
                                  AppColors.mainColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.mainColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: _imageFile == null
                                ? Icon(
                                    Icons.person,
                                    size: screenWidth * 0.12,
                                    color: AppColors.mainColor,
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.mainColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      BlocBuilder<UserBloc, UserState>(
                        builder: (context, state) {
                          if (state is UserSuccess) {
                            return Column(
                              children: [
                                Text(
                                  state.user.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  state.user.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            );
                          } else if (state is UserLoading) {
                            return CircularProgressIndicator();
                          }
                          return Column(
                            children: [
                              Text(
                                "John Doe",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "john.doe@email.com",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, thickness: 1),

              // Personal Information Section
              ExpansionTile(
                leading: Icon(Icons.person_outline, color: AppColors.mainColor),
                title: Text(
                  l10n.personalInformation,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainColor,
                  ),
                ),
                iconColor: AppColors.mainColor,
                collapsedIconColor: AppColors.mainColor,
                initiallyExpanded: _isPersonalInfoExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isPersonalInfoExpanded = expanded;
                  });
                },
                children: [
                  ListTile(
                    leading: Icon(Icons.person_outline, color: AppColors.mainColor.withOpacity(0.7)),
                    title: Text(l10n.editName),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mainColor),
                    onTap: () {
                      Navigator.pushNamed(context, EditNameScreen.routeName);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.phone_outlined, color: AppColors.mainColor.withOpacity(0.7)),
                    title: Text('Edit Phone Number'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mainColor),
                    onTap: () {
                      Navigator.pushNamed(context, EditPhoneScreen.routeName);
                    },
                  ),
                ],
              ),

              Divider(height: 1, thickness: 1),

              // Security Section
              ExpansionTile(
                leading: Icon(Icons.security_outlined, color: AppColors.mainColor),
                title: Text(
                  l10n.security,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainColor,
                  ),
                ),
                iconColor: AppColors.mainColor,
                collapsedIconColor: AppColors.mainColor,
                initiallyExpanded: _isSecurityExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isSecurityExpanded = expanded;
                  });
                },
                children: [
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: AppColors.mainColor.withOpacity(0.7)),
                    title: Text(l10n.changePassword),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mainColor),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        ChangePasswordScreen.routeName,
                      );
                    },
                  ),
                ],
              ),

              Divider(height: 1, thickness: 1),

              // Preferences Section
              ExpansionTile(
                leading: Icon(Icons.settings_outlined, color: AppColors.mainColor),
                title: Text(
                  l10n.preferences,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainColor,
                  ),
                ),
                iconColor: AppColors.mainColor,
                collapsedIconColor: AppColors.mainColor,
                initiallyExpanded: _isPreferencesExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isPreferencesExpanded = expanded;
                  });
                },
                children: [
                  ListTile(
                    leading: Icon(Icons.brightness_6_outlined, color: AppColors.mainColor.withOpacity(0.7)),
                    title: Text(l10n.theme),
                    subtitle: Text(l10n.light),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mainColor),
                    onTap: () {
                      // TODO: Navigate to theme settings
                    },
                  ),
                  BlocBuilder<LocaleCubit, Locale>(
                    builder: (context, locale) {
                      return ListTile(
                        leading: Icon(Icons.language_outlined, color: AppColors.mainColor.withOpacity(0.7)),
                        title: Text(l10n.language),
                        subtitle: Text(locale.languageCode == 'en' ? 'English' : 'العربية'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mainColor),
                        onTap: () => _showLanguageDialog(context),
                      );
                    },
                  ),
                ],
              ),

              Divider(height: 1, thickness: 1),

              SizedBox(height: screenHeight * 0.04),

              // Logout Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    if (state is LogoutLoading) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFE5E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    return InkWell(
                      onTap: () => _handleLogout(context),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFE5E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            l10n.logout,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // App Version
              Center(
                child: Text(
                  'App Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}
