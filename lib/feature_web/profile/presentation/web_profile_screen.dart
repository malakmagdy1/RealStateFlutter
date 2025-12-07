import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/core/utils/validators.dart';
import 'package:real/core/utils/web_utils.dart';
import 'package:real/core/locale/locale_cubit.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/login_event.dart';
import 'package:real/feature/auth/presentation/bloc/login_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_event.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_event.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_state.dart';
import 'package:real/feature/auth/presentation/bloc/update_phone_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/update_phone_event.dart';
import 'package:real/feature/auth/presentation/bloc/update_phone_state.dart';
import 'package:real/feature/auth/data/models/update_name_request.dart';
import 'package:real/feature/auth/data/models/update_phone_request.dart';
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
import 'package:real/services/fcm_service.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';
import 'package:real/services/notification_preferences.dart';


class WebProfileScreen extends StatefulWidget {
  WebProfileScreen({Key? key}) : super(key: key);

  @override
  State<WebProfileScreen> createState() => _WebProfileScreenState();
}

class _WebProfileScreenState extends State<WebProfileScreen> {
  Uint8List? _imageBytes;
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
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _loadingNotifications = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    print('═══════════════════════════════════════════════════════');
    print('🔔 [WEB PROFILE] Toggle notifications called: $value');
    print('═══════════════════════════════════════════════════════');

    setState(() => _loadingNotifications = true);

    try {
      print('🔄 [WEB PROFILE] Calling FCMService.toggleNotifications($value)...');
      await FCMService().toggleNotifications(value);
      print('✅ [WEB PROFILE] FCMService.toggleNotifications completed successfully');

      if (mounted) {
        setState(() {
          _notificationsEnabled = value;
          _loadingNotifications = false;
        });
        print('✅ [WEB PROFILE] State updated: _notificationsEnabled = $value');

        final l10n = AppLocalizations.of(context)!;
        MessageHelper.showSuccess(
          context,
          value ? l10n.notificationsEnabled : l10n.notificationsDisabled,
        );
        print('✅ [WEB PROFILE] Success message shown to user');
      }
    } catch (e, stackTrace) {
      print('❌ [WEB PROFILE] Error toggling notifications: $e');
      print('❌ [WEB PROFILE] Stack trace: $stackTrace');

      if (mounted) {
        setState(() => _loadingNotifications = false);
        MessageHelper.showError(context, 'Failed to toggle notifications: $e');
      }
    }

    print('═══════════════════════════════════════════════════════');
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Read image as bytes immediately after picking for web compatibility
        // On web, the Blob URL can get revoked, so we read bytes right away
        Uint8List bytes;
        try {
          bytes = await pickedFile.readAsBytes();
        } catch (e) {
          // If blob was revoked, try to re-pick
          print('[PROFILE IMAGE] Error reading bytes: $e');
          MessageHelper.showError(context, l10n.errorReadingImage);
          return;
        }

        // Validate that we have actual image data
        if (bytes.isEmpty) {
          MessageHelper.showError(context, l10n.errorReadingImage);
          return;
        }

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
          pickedFile.name, // Use name instead of path for web
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
      print('[PROFILE IMAGE] Error: $e');
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
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 7),
              Text(l10n.logout, style: TextStyle(color: Colors.black87)),
            ],
          ),
          content: Text(l10n.logoutConfirm, style: TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel, style: TextStyle(color: Colors.blue)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                loginBloc.add(LogoutEvent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(l10n.logout, style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loginBloc = context.read<LoginBloc>();
    final reasonController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 8),
                  Text(
                    l10n.deleteAccountTitle,
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          l10n.deleteAccountWarning,
                          style: TextStyle(color: Colors.red[700], fontSize: 14),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        l10n.deleteAccountReason,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          hintText: l10n.deleteAccountReasonHint,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(height: 16),
                      Text(
                        l10n.typeDeleteToConfirm,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: confirmController,
                        decoration: InputDecoration(
                          hintText: 'DELETE',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (confirmController.text != 'DELETE') {
                            MessageHelper.showError(context, l10n.deleteConfirmationRequired);
                            return;
                          }

                          setState(() => isLoading = true);

                          try {
                            final authService = AuthWebServices();
                            await authService.deleteAccount(reason: reasonController.text);

                            Navigator.of(dialogContext).pop();
                            MessageHelper.showSuccess(context, l10n.deleteAccountSuccess);

                            // Logout the user after successful deletion request
                            Future.delayed(Duration(seconds: 2), () {
                              loginBloc.add(LogoutEvent());
                            });
                          } catch (e) {
                            setState(() => isLoading = false);
                            MessageHelper.showError(context, l10n.deleteAccountError);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(l10n.deleteAccount),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: context.read<UpdateNameBloc>(),
          child: BlocConsumer<UpdateNameBloc, UpdateNameState>(
            listener: (context, state) {
              if (state is UpdateNameSuccess) {
                MessageHelper.showSuccess(context, state.response.message);
                context.read<UserBloc>().add(FetchUserEvent());
                Navigator.of(dialogContext).pop();
              } else if (state is UpdateNameError) {
                MessageHelper.showError(context, state.message);
              }
            },
            builder: (context, state) {
              final isLoading = state is UpdateNameLoading;
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.mainColor),
                    SizedBox(width: 7),
                    Text(l10n.editName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: SizedBox(
                  width: 200,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.updateYourDisplayName, style: TextStyle(color: Colors.grey[600])),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          enabled: !isLoading,
                          validator: Validators.validateName,
                          decoration: InputDecoration(
                            labelText: l10n.editName,
                            hintText: l10n.enterYourName,
                            prefixIcon: Icon(Icons.person, color: AppColors.mainColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: BorderSide(color: AppColors.mainColor, width: 1.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.cancel, style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : () {
                      if (formKey.currentState!.validate()) {
                        final request = UpdateNameRequest(name: nameController.text);
                        context.read<UpdateNameBloc>().add(UpdateNameSubmitEvent(request));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    ),
                    child: isLoading
                        ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.2))
                        : Text(l10n.update, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showEditPhoneDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: context.read<UpdatePhoneBloc>(),
          child: BlocConsumer<UpdatePhoneBloc, UpdatePhoneState>(
            listener: (context, state) {
              if (state is UpdatePhoneSuccess) {
                MessageHelper.showSuccess(context, state.response.message);
                context.read<UserBloc>().add(FetchUserEvent());
                Navigator.of(dialogContext).pop();
              } else if (state is UpdatePhoneError) {
                MessageHelper.showError(context, state.message);
              }
            },
            builder: (context, state) {
              final isLoading = state is UpdatePhoneLoading;
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Row(
                  children: [
                    Icon(Icons.phone_outlined, color: AppColors.mainColor),
                    SizedBox(width: 7),
                    Text(l10n.editPhoneNumber, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: SizedBox(
                  width: 200,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.updateYourContactNumber, style: TextStyle(color: Colors.grey[600])),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          enabled: !isLoading,
                          validator: Validators.validatePhone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: l10n.editPhoneNumber,
                            hintText: l10n.enterYourPhoneNumber,
                            prefixIcon: Icon(Icons.phone, color: AppColors.mainColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: BorderSide(color: AppColors.mainColor, width: 1.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.cancel, style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : () {
                      if (formKey.currentState!.validate()) {
                        final request = UpdatePhoneRequest(phone: phoneController.text);
                        context.read<UpdatePhoneBloc>().add(UpdatePhoneSubmitEvent(request));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    ),
                    child: isLoading
                        ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.2))
                        : Text(l10n.update, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Row(
            children: [
              Icon(Icons.language, color: AppColors.mainColor),
              SizedBox(width: 7),
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
              SizedBox(height: 5),
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
    return InkWell(
      onTap: () async {
        await localeCubit.changeLocale(Locale(languageCode));
        Navigator.of(context).pop();
        final l10n = AppLocalizations.of(context)!;
        MessageHelper.showSuccess(context, l10n.languageChanged);

        // Reload the page to apply language changes
        await Future.delayed(Duration(milliseconds: 500));
        reloadWebPage();
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? AppColors.mainColor : Colors.grey.shade300,
            width: 1.2,
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
                  fontSize: 15,
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
          // Navigate to login screen using GoRouter for web
          // Use pushReplacement to ensure clean navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
            // Force a router rebuild
            if (context.mounted) {
              MessageHelper.showSuccess(context, state.message);
            }
            // Reload the page to clear all state
            Future.delayed(Duration(milliseconds: 500), () {
              reloadWebPage();
            });
          });
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
                  constraints: BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: EdgeInsets.all(19),
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
                                  SizedBox(height: 14),
                                  _buildPreferencesSection(l10n),
                                ],
                              ),
                            ),
                            SizedBox(width: 14),
                            // Right Column
                            Expanded(
                              child: Column(
                                children: [
                                  _buildSubscriptionSection(l10n),
                                  SizedBox(height: 14),
                                  _buildDeviceManagementSection(l10n),
                                  SizedBox(height: 14),
                                  _buildNotificationSettings(l10n),
                                  SizedBox(height: 14),
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
          constraints: BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 19, vertical: 29),
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
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: Offset(0, 5),
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
                                    size: 32,
                                    color: AppColors.mainColor,
                                  ),
                                );
                              },
                            )
                                : Container(
                              color: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 30,
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
                                padding: EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 15,
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
                SizedBox(width: 19),
                // User Info
                Expanded(
                  child: BlocBuilder<UserBloc, UserState>(
                    builder: (context, state) {
                      String name = "User";
                      String email = "user@email.com";

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
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.9), size: 14),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.verified_user, color: Colors.white.withOpacity(0.9), size: 14),
                              SizedBox(width: 5),
                              Text(
                                l10n.verifiedAccount,
                                style: TextStyle(
                                  fontSize: 12,
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
      padding: EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 9,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.mainColor, size: 14),
              SizedBox(width: 7),
              Text(
                l10n.personalInformation,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _buildSettingItem(
            icon: Icons.person_outline,
            title: l10n.editName,
            subtitle: l10n.updateYourDisplayName,
            onTap: () => _showEditNameDialog(context),
          ),
          SizedBox(height: 7),
          _buildSettingItem(
            icon: Icons.phone_outlined,
            title: l10n.editPhoneNumber,
            subtitle: l10n.updateYourContactNumber,
            onTap: () => _showEditPhoneDialog(context),
          ),
          SizedBox(height: 7),
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
            padding: EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.mainColor.withOpacity(0.05),
                  AppColors.mainColor.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.mainColor.withOpacity(0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mainColor.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 2),
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
                        Icon(Icons.workspace_premium, color: AppColors.mainColor, size: 17),
                        SizedBox(width: 7),
                        Text(
                          l10n.subscriptionPlan,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: status.hasActiveSubscription
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (status.hasActiveSubscription
                                ? Colors.green
                                : Colors.orange)
                                .withOpacity(0.3),
                            blurRadius: 5,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        status.hasActiveSubscription ? l10n.active : l10n.inactive,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.planNameEn,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      ),
                      if (status.planName.isNotEmpty && status.planName != status.planNameEn) ...[
                        SizedBox(height: 2),
                        Text(
                          status.planName,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                      SizedBox(height: 10),
                      Divider(),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.search, color: AppColors.mainColor, size: 14),
                          SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.searchQuota,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  status.hasUnlimitedSearches
                                      ? l10n.unlimitedSearches
                                      : l10n.searchesLeft(status.remainingSearches, status.searchLimit),
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
                      if (!status.hasUnlimitedSearches) ...[
                        SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
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
                            minHeight: 5,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          status.canSearch
                              ? l10n.searchesRemaining(status.remainingSearches)
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
                        SizedBox(height: 10),
                        Divider(),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600], size: 12),
                            SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.expiresOn,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    status.expiresAt!,
                                    style: TextStyle(
                                      fontSize: 15,
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
                SizedBox(height: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: () {
                      context.push('/subscription');
                    },
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.mainColor,
                            AppColors.mainColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mainColor.withOpacity(0.3),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upgrade, color: Colors.white),
                          SizedBox(width: 7),
                          Text(
                            l10n.manageSubscription,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
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
            padding: EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 9,
                  offset: Offset(0, 2),
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
      padding: EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 9,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: AppColors.mainColor, size: 14),
              SizedBox(width: 7),
              Text(
                l10n.preferences,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
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
          SizedBox(height: 7),
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
      padding: EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 9,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_circle, color: Colors.grey[700], size: 14),
              SizedBox(width: 7),
              Text(
                l10n.account,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          // Delete Account Button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: () => _showDeleteAccountDialog(context),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 7),
                    Text(
                      l10n.deleteAccount,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          // Logout Button
          BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
              if (state is LogoutLoading) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: 1.2,
                    ),
                  ),
                );
              }

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () => _handleLogout(context),
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.red.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.white),
                        SizedBox(width: 7),
                        Text(
                          l10n.logout,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
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
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Color(0xFFE6E6E6)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: AppColors.mainColor, size: 13),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF999999)),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildFeatureChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.mainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.mainColor,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDeviceManagementSection(AppLocalizations l10n)
  {
    final AuthWebServices authService = AuthWebServices();

    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        authService.getUserDevices(),
        authService.getSubscriptionInfo(),
      ]).then((results) => {
        'devices': results[0],
        'subscription': results[1],
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 9,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: CustomLoadingDots(size: 24)),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 9,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Error loading devices: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final devices = snapshot.data!['devices'] as List<Map<String, dynamic>>;
        final subscription = snapshot.data!['subscription'] as Map<String, dynamic>;

        return Container(
          padding: EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 9,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.devices_other, color: AppColors.mainColor, size: 22),
                  SizedBox(width: 7),
                  Text(
                    l10n.deviceManagement,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Device limit info
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.mainColor.withOpacity(0.1),
                      AppColors.mainColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppColors.mainColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: AppColors.mainColor, size: 12),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        l10n.devicesUsed(subscription['current_devices'] ?? 0, subscription['max_devices'] ?? 0),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),

              // Devices list
              if (devices.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      l10n.noDevicesFound,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                ...devices.take(3).map((device) {
                  final isCurrentDevice = device['is_current_device'] == true || device['is_current_device'] == 1;
                  return Container(
                    margin: EdgeInsets.only(bottom: 7),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrentDevice ? AppColors.mainColor.withOpacity(0.05) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: isCurrentDevice ? AppColors.mainColor : Colors.grey[200]!,
                        width: isCurrentDevice ? 1.2 : 0.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getDeviceIcon(device['device_type']),
                          color: AppColors.mainColor,
                          size: 17,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      device['device_name'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isCurrentDevice)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.mainColor,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        'Current',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Text(
                                device['os_version'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCurrentDevice)
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 11, color: Colors.red),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  title: Text('Remove Device'),
                                  content: Text('Are you sure you want to remove "${device['device_name']}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: Text('Remove'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                try {
                                  // Use device_id (e.g. "web_1763299843458") not numeric id
                                  await authService.removeDevice(device['device_id'].toString());
                                  MessageHelper.showSuccess(context, 'Device removed successfully');
                                  setState(() {}); // Refresh
                                } catch (e) {
                                  MessageHelper.showError(context, 'Failed to remove device');
                                }
                              }
                            },
                          ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Build Notification Settings Section
  Widget _buildNotificationSettings(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 9,
            offset: Offset(0, 2),
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
                  Icon(
                    _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: AppColors.mainColor,
                    size: 15,
                  ),
                  SizedBox(width: 7),
                  Text(
                    l10n.notifications,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              _loadingNotifications
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
                      ),
                    )
                  : Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeColor: AppColors.mainColor,
                      ),
                    ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.mainColor.withOpacity(0.1),
                  AppColors.mainColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppColors.mainColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  _notificationsEnabled ? Icons.check_circle : Icons.info_outline,
                  color: _notificationsEnabled ? Colors.green : Colors.orange,
                  size: 16,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _notificationsEnabled
                        ? 'You will receive push notifications for new units, sales, and updates'
                        : 'Push notifications are disabled. Toggle on to receive updates',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String? deviceType) {
    switch (deviceType?.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.web;
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.laptop_mac;
      default:
        return Icons.devices;
    }
  }
}
