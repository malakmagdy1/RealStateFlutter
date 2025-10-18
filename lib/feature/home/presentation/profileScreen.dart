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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

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
                loginBloc.add(const LogoutEvent());
              },
              child: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
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
              const SizedBox(width: 8),
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
              const Divider(),
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
            duration: const Duration(seconds: 2),
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
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: screenWidth * 0.15,
                            backgroundColor: AppColors.mainColor.withOpacity(
                              0.2,
                            ),
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : null,

                            child: _imageFile == null
                                ? Icon(
                                    Icons.person,
                                    size: screenWidth * 0.15,
                                    color: AppColors.mainColor,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: screenWidth * 0.05,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      BlocBuilder<UserBloc, UserState>(
                        builder: (context, state) {
                          if (state is UserSuccess) {
                            return Column(
                              children: [
                                CustomText20(
                                  state.user.name,
                                  color: Colors.black,
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                CustomText16(
                                  state.user.email,
                                  color: Colors.grey,
                                ),
                              ],
                            );
                          } else if (state is UserLoading) {
                            return const CircularProgressIndicator();
                          }
                          return Column(
                            children: [
                              CustomText20("User Name", color: Colors.black),
                              SizedBox(height: screenHeight * 0.005),
                              CustomText16(
                                "user@email.com",
                                color: Colors.grey,
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: screenHeight * 0.03),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  child: CustomText20(
                    l10n.personalInformation,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                CustomListTile(
                  icon: Icons.person_outline,
                  title: l10n.editName,
                  onTap: () {
                    Navigator.pushNamed(context, EditNameScreen.routeName);
                  },
                  screenWidth: screenWidth,
                ),
                CustomListTile(
                  icon: Icons.phone_outlined,
                  title: l10n.editPhone,
                  onTap: () {
                    Navigator.pushNamed(context, EditPhoneScreen.routeName);
                  },
                  screenWidth: screenWidth,
                ),

                SizedBox(height: screenHeight * 0.02),

                // Security Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  child: CustomText20(l10n.security, color: Colors.black),
                ),
                SizedBox(height: screenHeight * 0.015),
                CustomListTile(
                  icon: Icons.lock_outline,
                  title: l10n.changePassword,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      ChangePasswordScreen.routeName,
                    );
                  },
                  screenWidth: screenWidth,
                ),

                SizedBox(height: screenHeight * 0.02),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  child: CustomText20(l10n.preferences, color: Colors.black),
                ),
                SizedBox(height: screenHeight * 0.015),
                CustomListTile(
                  icon: Icons.brightness_6_outlined,
                  title: l10n.theme,
                  subtitle: l10n.light,
                  onTap: () {
                    // TODO: Navigate to theme settings
                  },
                  screenWidth: screenWidth,
                ),
                BlocBuilder<LocaleCubit, Locale>(
                  builder: (context, locale) {
                    return CustomListTile(
                      icon: Icons.language_outlined,
                      title: l10n.language,
                      subtitle: locale.languageCode == 'en' ? 'English' : 'العربية',
                      onTap: () => _showLanguageDialog(context),
                      screenWidth: screenWidth,
                    );
                  },
                ),

                SizedBox(height: screenHeight * 0.02),

                // Account Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  child: CustomText20(l10n.account, color: Colors.black),
                ),
                SizedBox(height: screenHeight * 0.015),
                CustomListTile(
                  icon: Icons.notifications_outlined,
                  title: l10n.notifications,
                  onTap: () {
                    // TODO: Navigate to notification settings
                  },
                  screenWidth: screenWidth,
                ),
                CustomListTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.privacyPolicy,
                  onTap: () {
                    // TODO: Navigate to privacy policy
                  },
                  screenWidth: screenWidth,
                ),
                CustomListTile(
                  icon: Icons.help_outline,
                  title: l10n.helpSupport,
                  onTap: () {
                    // TODO: Navigate to help screen
                  },
                  screenWidth: screenWidth,
                ),
                SizedBox(height: screenHeight * 0.02),

                // Logout Button
                BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    if (state is LogoutLoading) {
                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.red),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () => _handleLogout(context),
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.04,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: screenWidth * 0.06,
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            CustomText18(
                              l10n.logout,
                              color: Colors.red,
                              bold: true,
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.red,
                              size: screenWidth * 0.04,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
