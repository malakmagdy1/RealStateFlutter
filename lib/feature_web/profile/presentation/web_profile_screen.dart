import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real/core/utils/colors.dart';
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
import 'package:real/feature_web/auth/presentation/web_login_screen.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/compound_favorite_state.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';

class WebProfileScreen extends StatefulWidget {
  WebProfileScreen({Key? key}) : super(key: key);

  @override
  State<WebProfileScreen> createState() => _WebProfileScreenState();
}

class _WebProfileScreenState extends State<WebProfileScreen> {
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
    final loginBloc = context.read<LoginBloc>();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 12),
              Text(l10n.logout),
            ],
          ),
          content: Text(l10n.logoutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel, style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                loginBloc.add(LogoutEvent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.logout),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.language, color: AppColors.mainColor),
              SizedBox(width: 12),
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
              SizedBox(height: 8),
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

  Future<void> _copyToken() async {
    final token = await CasheNetwork.getCasheDataAsync(key: 'token');
    if (token.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: token));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token copied to clipboard!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No token found. Please log in first.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _languageOption(
    BuildContext context,
    LocaleCubit localeCubit,
    String languageName,
    String languageCode,
    bool isSelected,
  ) {
    return InkWell(
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.mainColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                languageName,
                style: TextStyle(
                  color: isSelected ? AppColors.mainColor : Colors.black,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.mainColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LogoutSuccess) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            WebLoginScreen.routeName,
            (route) => false,
          );
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
      child: Container(
        color: Color(0xFFF8F9FA),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              _buildHeader(l10n),

              // Main Content
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1400),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column
                            Expanded(
                              child: Column(
                                children: [
                                  _buildPersonalInfoSection(l10n),
                                  SizedBox(height: 24),
                                  _buildSecuritySection(l10n),
                                ],
                              ),
                            ),
                            SizedBox(width: 24),
                            // Right Column
                            Expanded(
                              child: Column(
                                children: [
                                  _buildPreferencesSection(l10n),
                                  SizedBox(height: 24),
                                  _buildAccountSection(l10n),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        // Developer Section (Full Width)
                        _buildDeveloperSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.mainColor,
            AppColors.mainColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Row(
              children: [
                // Avatar with edit button
                Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _imageFile == null
                            ? Container(
                                color: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 70,
                                  color: AppColors.mainColor,
                                ),
                              )
                            : Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppColors.mainColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 32),
                // User Info
                Expanded(
                  child: BlocBuilder<UserBloc, UserState>(
                    builder: (context, state) {
                      String name = "John Doe";
                      String email = "john.doe@email.com";

                      if (state is UserSuccess) {
                        name = state.user.name;
                        email = state.user.email;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.9), size: 20),
                              SizedBox(width: 8),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.verified_user, color: Colors.white.withOpacity(0.9), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Verified Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildPersonalInfoSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.mainColor, size: 24),
              SizedBox(width: 12),
              Text(
                l10n.personalInformation,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingItem(
            icon: Icons.person_outline,
            title: l10n.editName,
            subtitle: 'Update your display name',
            onTap: () => Navigator.pushNamed(context, EditNameScreen.routeName),
          ),
          SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.phone_outlined,
            title: 'Edit Phone Number',
            subtitle: 'Update your contact number',
            onTap: () => Navigator.pushNamed(context, EditPhoneScreen.routeName),
          ),
          SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.email_outlined,
            title: 'Email Address',
            subtitle: 'View your email address',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppColors.mainColor, size: 24),
              SizedBox(width: 12),
              Text(
                l10n.security,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: l10n.changePassword,
            subtitle: 'Update your password',
            onTap: () => Navigator.pushNamed(context, ChangePasswordScreen.routeName),
          ),
          SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.shield_outlined,
            title: 'Two-Factor Authentication',
            subtitle: 'Add extra security',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: AppColors.mainColor, size: 24),
              SizedBox(width: 12),
              Text(
                l10n.preferences,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return _buildSettingItem(
                icon: Icons.language_outlined,
                title: l10n.language,
                subtitle: locale.languageCode == 'en' ? 'English' : 'العربية',
                onTap: () => _showLanguageDialog(context),
              );
            },
          ),
          SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.brightness_6_outlined,
            title: l10n.theme,
            subtitle: l10n.light,
            onTap: () {},
          ),
          SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification settings',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_circle, color: AppColors.mainColor, size: 24),
              SizedBox(width: 12),
              Text(
                'Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            onTap: () {},
          ),
          SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms',
            onTap: () {},
          ),
          SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with your account',
            onTap: () {},
          ),
          SizedBox(height: 24),
          Divider(),
          SizedBox(height: 24),
          // Logout Button
          BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
              if (state is LogoutLoading) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () => _handleLogout(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 12),
                        Text(
                          l10n.logout,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'App Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection() {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                'Developer Tools',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEV',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Use this token to test API endpoints in Postman or other API clients.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 20),
          FutureBuilder<String>(
            future: CasheNetwork.getCasheDataAsync(key: 'token'),
            builder: (context, snapshot) {
              final token = snapshot.data ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Authentication Token:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Spacer(),
                      ElevatedButton.icon(
                        onPressed: token.isEmpty ? null : _copyToken,
                        icon: Icon(Icons.copy, size: 18),
                        label: Text('Copy Token'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFE6E6E6)),
                    ),
                    child: token.isEmpty
                        ? Text(
                            'No token found. Please log in first.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : SelectableText(
                            token,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: Color(0xFF333333),
                            ),
                          ),
                  ),
                  if (token.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add this token as a Bearer token in your API requests:\nAuthorization: Bearer <token>',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE6E6E6)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.mainColor, size: 22),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF999999)),
            ],
          ),
        ),
      ),
    );
  }
}
