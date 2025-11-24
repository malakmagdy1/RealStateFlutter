import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:real/feature/auth/presentation/bloc/user_event.dart';
import 'package:real/feature/auth/presentation/screen/editNameScreen.dart';
import 'package:real/feature/auth/presentation/screen/editPhoneScreen.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';
import 'package:real/feature/auth/presentation/screen/device_management_screen.dart';
import 'package:real/feature/home/presentation/widget/customListTile.dart';
import 'package:real/feature/notifications/presentation/screens/notifications_screen.dart';
import 'package:real/feature/ai_chat/presentation/screen/unified_ai_chat_screen.dart';
import 'package:real/feature/auth/data/web_services/auth_web_services.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_state.dart';
import 'package:real/feature/subscription/presentation/screens/subscription_plans_screen.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';
import 'package:real/services/fcm_service.dart';
import 'package:real/services/notification_preferences.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _notificationsEnabled = true;
  bool _loadingNotifications = true;

  @override
  void initState() {
    super.initState();
    // Load subscription status when profile screen loads
    context.read<SubscriptionBloc>().add(LoadSubscriptionStatusEvent());
    // Load notification preference
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final enabled = await NotificationPreferences.getNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
      _loadingNotifications = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _loadingNotifications = true);

    try {
      await FCMService().toggleNotifications(value);

      setState(() {
        _notificationsEnabled = value;
        _loadingNotifications = false;
      });

      if (mounted) {
        MessageHelper.showSuccess(
          context,
          value ? 'Notifications enabled' : 'Notifications disabled',
        );
      }
    } catch (e) {
      setState(() => _loadingNotifications = false);
      if (mounted) {
        MessageHelper.showError(context, 'Failed to toggle notifications');
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimatedImagePickerSheet(
        onCameraTap: () async {
          Navigator.pop(context);
          await _pickImageFromSource(ImageSource.camera);
        },
        onGalleryTap: () async {
          Navigator.pop(context);
          await _pickImageFromSource(ImageSource.gallery);
        },
      ),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        // Upload the image to the backend
        MessageHelper.showMessage(
          context: context,
          message: 'Uploading profile image...',
          isSuccess: true,
        );

        final authWebServices = AuthWebServices();
        await authWebServices.uploadProfileImage(pickedFile.path);

        // Refresh user data to get the updated image URL from backend
        context.read<UserBloc>().add(FetchUserEvent());

        MessageHelper.showSuccess(context, 'Profile image updated successfully!');

        // Clear local image file so it uses the backend image
        setState(() {
          _imageFile = null;
        });
      }
    } catch (e) {
      MessageHelper.showError(context, 'Error uploading image: $e');
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
        MessageHelper.showSuccess(context, l10n.languageChanged);
      },
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.mainColor,
          fontWeight: FontWeight.w500,
        ),
      ),
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
          MessageHelper.showSuccess(context, state.message);
        } else if (state is LogoutError) {
          MessageHelper.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Profile',
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
                      BlocBuilder<UserBloc, UserState>(
                        builder: (context, userState) {
                          String? imageUrl;
                          if (userState is UserSuccess) {
                            imageUrl = userState.user.imageUrl;
                          }

                          return Container(
                            width: screenWidth * 0.28,
                            height: screenWidth * 0.28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.mainColor.withOpacity(0.2),
                                  AppColors.mainColor.withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.mainColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: _imageFile != null
                                ? ClipOval(
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : imageUrl != null && imageUrl.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: screenWidth * 0.12,
                                              color: AppColors.mainColor,
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: screenWidth * 0.12,
                                        color: AppColors.mainColor,
                                      ),
                          );
                        },
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
                            return CustomLoadingDots(size: 60);
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

              // Subscription Section - Compact
              BlocBuilder<SubscriptionBloc, SubscriptionState>(
                builder: (context, state) {
                  if (state is SubscriptionStatusLoaded) {
                    final status = state.status;
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: status.hasActiveSubscription
                              ? [
                                  AppColors.mainColor,
                                  AppColors.mainColor.withOpacity(0.8),
                                ]
                              : [
                                  Colors.grey[700]!,
                                  Colors.grey[600]!,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: status.hasActiveSubscription
                                ? AppColors.mainColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row - compact
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.workspace_premium,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      status.planNameEn,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status.hasActiveSubscription
                                        ? Colors.green
                                        : Colors.orange[700],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.hasActiveSubscription ? 'ACTIVE' : 'INACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),

                            // Search usage - inline
                            Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                if (status.hasUnlimitedSearches)
                                  Text(
                                    'Unlimited Searches',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  )
                                else
                                  Text(
                                    '${status.remainingSearches} / ${status.searchLimit} searches left',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                              ],
                            ),

                            if (!status.hasUnlimitedSearches) ...[
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: status.searchLimit > 0
                                      ? status.searchesUsed / status.searchLimit
                                      : 0,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    status.canSearch
                                        ? Colors.green[300]!
                                        : Colors.red[300]!,
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ],

                            // Expiry and button row
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (status.expiresAt != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event_available,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        status.expiresAt!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  SizedBox(),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      SubscriptionPlansScreen.routeName,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: status.hasActiveSubscription
                                        ? AppColors.mainColor
                                        : Colors.grey[700],
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: Size(0, 0),
                                  ),
                                  child: Text(
                                    status.hasActiveSubscription
                                        ? 'Manage'
                                        : 'Upgrade',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (state is SubscriptionLoading) {
                    return Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: CustomLoadingDots(size: 60),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),

              SizedBox(height: 16),

              // Profile Options
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person_outline, color: AppColors.mainColor, size: 24),
                      ),
                      title: Text(
                        l10n.editName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => EditNameScreen(),  // الودجت اللي جهزناه
                          );
                        },
                    ),
                    Divider(height: 1, indent: 72, endIndent: 16),
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.phone_outlined, color: AppColors.mainColor, size: 24),
                      ),
                      title: Text(
                        'Edit Phone Number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => EditPhoneScreen(), // الودجت الجديد اللي هنعمله تحت
                          );
                        },
                    ),
                    Divider(height: 1, indent: 72, endIndent: 16),
                    BlocBuilder<LocaleCubit, Locale>(
                      builder: (context, locale) {
                        return ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.mainColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.language_outlined, color: AppColors.mainColor, size: 24),
                          ),
                          title: Text(
                            l10n.language,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            locale.languageCode == 'en' ? 'English' : 'العربية',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () => _showLanguageDialog(context),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 72, endIndent: 16),
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.devices_other, color: AppColors.mainColor, size: 24),
                      ),
                      title: Text(
                        'Manage Devices',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'View and remove devices',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.pushNamed(context, DeviceManagementScreen.routeName);
                      },
                    ),
                    Divider(height: 1, indent: 72, endIndent: 16),
                    // Notification Toggle
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                          color: AppColors.mainColor,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        l10n.notifications,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        _notificationsEnabled ? 'Receive push notifications' : 'Notifications disabled',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      trailing: _loadingNotifications
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
                              ),
                            )
                          : Switch(
                              value: _notificationsEnabled,
                              onChanged: _toggleNotifications,
                              activeColor: AppColors.mainColor,
                            ),
                    ),
                    Divider(height: 1, indent: 72, endIndent: 16),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Logout Button - Centered with limited width
              Center(
                child: BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    if (state is LogoutLoading) {
                      return Container(
                        width: screenWidth * 0.5,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFE5E5),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: CustomLoadingDots(size: 30),
                        ),
                      );
                    }

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: InkWell(
                            onTap: () => _handleLogout(context),
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              width: screenWidth * 0.5,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red[400]!,
                                    Colors.red[600]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    l10n.logout,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
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

/// Animated Image Picker Bottom Sheet Widget
class AnimatedImagePickerSheet extends StatefulWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const AnimatedImagePickerSheet({
    Key? key,
    required this.onCameraTap,
    required this.onGalleryTap,
  }) : super(key: key);

  @override
  State<AnimatedImagePickerSheet> createState() => _AnimatedImagePickerSheetState();
}

class _AnimatedImagePickerSheetState extends State<AnimatedImagePickerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text(
              'Choose Profile Photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera Option
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildPickerOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: AppColors.mainColor,
                    onTap: widget.onCameraTap,
                    delay: 0,
                  ),
                ),

                // Gallery Option
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildPickerOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.blue,
                    onTap: widget.onGalleryTap,
                    delay: 100,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return _AnimatedPickerButton(
      icon: icon,
      label: label,
      color: color,
      onTap: onTap,
    );
  }
}

/// Animated Picker Button with scale and vibration
class _AnimatedPickerButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedPickerButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_AnimatedPickerButton> createState() => _AnimatedPickerButtonState();
}

class _AnimatedPickerButtonState extends State<_AnimatedPickerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _controller.forward().then((_) {
      _controller.reverse();
    });

    // Delay the actual tap callback slightly for better UX
    Future.delayed(Duration(milliseconds: 100), () {
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: GestureDetector(
                    onTap: _handleTap,
                    child: Container(
                      width: 140,
                      padding: EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: widget.color.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.2),
                            blurRadius: _controller.value * 15,
                            spreadRadius: _controller.value * 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: widget.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: widget.color.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: widget.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
