import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/core/locale/locale_cubit.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/login_event.dart';
import 'package:real/feature/auth/presentation/bloc/login_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_event.dart';
import 'package:real/feature/auth/presentation/screen/changePasswordScreen.dart';
import 'package:real/feature/auth/presentation/screen/editNameScreen.dart';
import 'package:real/feature/auth/presentation/screen/editPhoneScreen.dart';
import 'package:real/feature_web/auth/presentation/web_login_screen.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/auth/data/web_services/auth_web_services.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_state.dart';
import 'package:real/feature_web/subscription/presentation/web_subscription_plans_screen.dart';
import 'package:go_router/go_router.dart';

class WebProfileScreen extends StatefulWidget {
  WebProfileScreen({Key? key}) : super(key: key);

  @override
  State<WebProfileScreen> createState() => _WebProfileScreenState();
}

class _WebProfileScreenState extends State<WebProfileScreen> {
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load subscription status when profile screen loads
    context.read<SubscriptionBloc>().add(LoadSubscriptionStatusEvent());
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Read image as bytes for web compatibility
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });

        // Upload the image to the backend
        MessageHelper.showMessage(
          context: context,
          message: l10n.uploadingProfileImage,
          isSuccess: true,
        );

        final authWebServices = AuthWebServices();
        await authWebServices.uploadProfileImage(
          pickedFile.path,
          fileBytes: bytes,
        );

        // Refresh user data to get the updated image URL from backend
        context.read<UserBloc>().add(FetchUserEvent());

        MessageHelper.showSuccess(context, l10n.profileImageUpdated);

        // Clear local image bytes so it uses the backend image
        setState(() {
          _imageBytes = null;
        });
      }
    } catch (e) {
      MessageHelper.showError(context, 'Error uploading image: $e');
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
    final l10n = AppLocalizations.of(context)!;
    final token = await CasheNetwork.getCasheDataAsync(key: 'token');
    if (token.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: token));
      if (mounted) {
        MessageHelper.showSuccess(context, l10n.tokenCopied);
      }
    } else {
      if (mounted) {
        MessageHelper.showMessage(
          context: context,
          message: l10n.noLoginMessage,
          isSuccess: false,
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
        MessageHelper.showSuccess(context, l10n.languageChanged);
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
          MessageHelper.showSuccess(context, state.message);
        } else if (state is LogoutError) {
          MessageHelper.showError(context, state.message);
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
                                  _buildPreferencesSection(l10n),
                                ],
                              ),
                            ),
                            SizedBox(width: 24),
                            // Right Column
                            Expanded(
                              child: Column(
                                children: [
                                  _buildSubscriptionSection(l10n),
                                  SizedBox(height: 24),
                                  _buildLogoutSection(l10n),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                BlocBuilder<UserBloc, UserState>(
                  builder: (context, userState) {
                    String? imageUrl;
                    if (userState is UserSuccess) {
                      imageUrl = userState.user.imageUrl;
                    }

                    return Stack(
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
                            child: _imageBytes != null
                                ? Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : imageUrl != null && imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.white,
                                            child: Icon(
                                              Icons.person,
                                              size: 70,
                                              color: AppColors.mainColor,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.white,
                                        child: Icon(
                                          Icons.person,
                                          size: 70,
                                          color: AppColors.mainColor,
                                        ),
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
                    );
                  },
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
                                l10n.verifiedAccount,
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
            subtitle: l10n.updateYourDisplayName,
            onTap: () => Navigator.pushNamed(context, EditNameScreen.routeName),
          ),
          SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.phone_outlined,
            title: l10n.editPhoneNumber,
            subtitle: l10n.updateYourContactNumber,
            onTap: () => Navigator.pushNamed(context, EditPhoneScreen.routeName),
          ),
          SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.email_outlined,
            title: l10n.emailAddress,
            subtitle: l10n.viewYourEmailAddress,
            onTap: () {},
          ),
        ],
      ),
    );
  }


  Widget _buildSubscriptionSection(AppLocalizations l10n) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        if (state is SubscriptionStatusLoaded) {
          final status = state.status;
          return Container(
            padding: EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.mainColor.withOpacity(0.05),
                  AppColors.mainColor.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.mainColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mainColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.workspace_premium, color: AppColors.mainColor, size: 28),
                        SizedBox(width: 12),
                        Text(
                          l10n.subscriptionPlan,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: status.hasActiveSubscription
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (status.hasActiveSubscription
                                    ? Colors.green
                                    : Colors.orange)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        status.hasActiveSubscription ? l10n.active : l10n.inactive,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.planNameEn,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      ),
                      if (status.planName.isNotEmpty && status.planName != status.planNameEn) ...[
                        SizedBox(height: 4),
                        Text(
                          status.planName,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.search, color: AppColors.mainColor, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.searchQuota,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  status.hasUnlimitedSearches
                                      ? l10n.unlimitedSearches
                                      : '${status.searchesUsed} / ${status.searchLimit} ${l10n.search}es',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!status.hasUnlimitedSearches) ...[
                        SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: status.searchLimit > 0
                                ? status.searchesUsed / status.searchLimit
                                : 0,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              status.canSearch
                                  ? AppColors.mainColor
                                  : Colors.red,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          status.canSearch
                              ? '${status.remainingSearches} ${l10n.search}es remaining'
                              : l10n.noSearchesRemaining,
                          style: TextStyle(
                            fontSize: 12,
                            color: status.canSearch
                                ? Colors.grey[600]
                                : Colors.red,
                            fontWeight: status.canSearch
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                      if (status.expiresAt != null) ...[
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.expiresOn,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    status.expiresAt!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 20),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: () {
                      context.push('/subscription');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.mainColor,
                            AppColors.mainColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mainColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upgrade, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            l10n.manageSubscription,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (state is SubscriptionLoading) {
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
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return SizedBox.shrink();
      },
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
            icon: Icons.notifications_outlined,
            title: l10n.notifications,
            subtitle: l10n.manageNotificationSettings,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(AppLocalizations l10n) {
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
              Icon(Icons.logout, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text(
                l10n.logout,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
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
                      gradient: LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.red.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          l10n.logout,
                          style: TextStyle(
                            color: Colors.white,
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
              l10n.appVersion,
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
