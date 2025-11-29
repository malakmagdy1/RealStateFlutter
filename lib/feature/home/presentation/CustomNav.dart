import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/login_event.dart';
import 'package:real/feature/auth/presentation/bloc/login_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_state.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';
import 'package:real/feature/auth/presentation/screen/blocked_user_screen.dart';
import 'package:real/feature/home/presentation/profileScreen.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_state.dart';
import 'package:real/feature/notifications/data/services/notification_cache_service.dart';
import 'package:real/l10n/app_localizations.dart';

import '../../../core/utils/text_style.dart';
import 'FavoriteScreen.dart';
import 'HistoryScreen.dart';
import 'homeScreen.dart';
import '../../notifications/presentation/screens/notifications_screen.dart';
import '../../compound/presentation/screen/compounds_screen.dart';
import '../../ai_chat/presentation/screen/unified_ai_chat_screen.dart';
import '../../ai_chat/data/services/comparison_list_service.dart';
import '../../ai_chat/data/models/comparison_item.dart';

class CustomNav extends StatefulWidget {
  static String routeName = '/nav';

  @override
  State<CustomNav> createState() => _CustomNavState();
}

class _CustomNavState extends State<CustomNav> {
  int _selectedIndex = 0;
  DateTime? _lastHomeTap;
  static const Duration _doubleTapDuration = Duration(milliseconds: 300);
  int _unreadNotificationCount = 0;
  final NotificationCacheService _notificationCacheService = NotificationCacheService();

  final List<Widget> widgetOptions = [
    HomeScreen(),
    CompoundsScreen(),
    FavoriteScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _handleHomeTap() {
    final now = DateTime.now();

    // Check if already on home screen
    if (_selectedIndex == 0) {
      // Check for double tap
      if (_lastHomeTap != null &&
          now.difference(_lastHomeTap!) < _doubleTapDuration) {
        // Double tap detected - refresh the app
        _refreshApp();
        _lastHomeTap = null; // Reset to prevent triple tap
      } else {
        // First tap - record time
        _lastHomeTap = now;
      }
    } else {
      // Not on home screen, just navigate to home
      setState(() {
        _selectedIndex = 0;
      });
      _lastHomeTap = now;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadNotificationCount() async {
    final count = await _notificationCacheService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  void _refreshApp() {
    final l10n = AppLocalizations.of(context)!;

    // Show a visual feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(l10n.refreshing),
          ],
        ),
        duration: Duration(milliseconds: 1500),
        backgroundColor: AppColors.mainColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    // Trigger a full app refresh by rebuilding the widget tree
    setState(() {
      // Force rebuild of the current screen
      _selectedIndex = _selectedIndex;
    });
  }

  void _handleLogout(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer

    // Capture the LoginBloc before showing the dialog
    final loginBloc = context.read<LoginBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
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

  @override
  Widget build(BuildContext context) {
    // 👇 get screen width & height
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        // Listen to logout events
        BlocListener<LoginBloc, LoginState>(
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
        ),
        // Listen to user status changes to check if banned or not verified
        BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserSuccess) {
              // Check if user is banned
              if (state.user.isBanned) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => BlockedUserScreen(
                      reason: 'Account Banned',
                      message: 'Your account has been banned. Please contact support for more information.',
                      icon: Icons.block,
                      iconColor: Colors.red,
                    ),
                  ),
                  (route) => false,
                );
              }
              // Check if user is not verified
              else if (!state.user.isVerified) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => BlockedUserScreen(
                      reason: 'Account Not Verified',
                      message: 'Your account is not verified yet. Please check your email or contact support to verify your account.',
                      icon: Icons.email_outlined,
                      iconColor: Colors.orange,
                    ),
                  ),
                  (route) => false,
                );
              }
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          actions: [
            Badge(
              label: Text('$_unreadNotificationCount'),
              isLabelVisible: _unreadNotificationCount > 0,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              child: IconButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, NotificationsScreen.routeName);
                  // Refresh unread count when returning from notifications screen
                  _loadUnreadNotificationCount();
                },
                icon: Icon(
                  Icons.notifications,
                  color: AppColors.mainColor,
                  size: screenWidth * 0.05,
                ),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: AppColors.mainColor),
                child: BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    if (state is UserSuccess) {
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey,
                            radius: screenWidth * 0.08,
                            child: Text(
                              state.user.name.isNotEmpty
                                  ? state.user.name[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText20(
                                  state.user.name,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  state.user.email,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 6),
                                // Subscription Plan Badge
                                BlocBuilder<SubscriptionBloc, SubscriptionState>(
                                  builder: (context, subState) {
                                    if (subState is SubscriptionStatusLoaded) {
                                      final planName = subState.status.planNameEn;
                                      return Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: subState.status.hasActiveSubscription
                                              ? Colors.amber[600]
                                              : Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.workspace_premium,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              planName,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: screenWidth * 0.08,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        CustomText20("user name", color: Colors.white),
                      ],
                    );
                  },
                ),
              ),
              ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.home_outlined,
                      color: AppColors.mainColor,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    CustomText16(l10n.home, color: AppColors.mainColor),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Close drawer
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      color: AppColors.mainColor,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    CustomText16(l10n.aiChat, color: AppColors.mainColor),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Close drawer
                  setState(() {
                    _selectedIndex = 4;
                  });
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.person_3_outlined,
                      color: AppColors.mainColor,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    CustomText16(l10n.profile, color: AppColors.mainColor),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Close drawer
                  setState(() {
                    _selectedIndex = 5;
                  });
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: AppColors.mainColor,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    CustomText16(l10n.compounds, color: AppColors.mainColor),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Close drawer
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.favorite_border_outlined,
                      color: AppColors.mainColor,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    CustomText16(l10n.favorites, color: AppColors.mainColor),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Close drawer
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              Divider(),
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  if (state is LogoutLoading) {
                    return ListTile(
                      title: Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      ),
                    );
                  }
                  return ListTile(
                    title: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: screenWidth * 0.06,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        CustomText16(l10n.logout, color: Colors.red),
                      ],
                    ),
                    onTap: () => _handleLogout(context),
                  );
                },
              ),
            ],
          ),
        ),
        body: widgetOptions[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.02,
                vertical: screenHeight * 0.01,
              ),
              child: GNav(
                rippleColor: Colors.grey[300]!,
                hoverColor: Colors.grey[100]!,
                gap: screenWidth * 0.01,
                color: AppColors.mainColor,
                // inactive icon color
                activeColor: Colors.white,
                // active icon color
                iconSize: screenWidth * 0.06,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.012,
                ),
                duration: Duration(milliseconds: 400),
                tabBackgroundColor: AppColors.mainColor.withOpacity(0.9),
                // highlight color (main color)
                tabBorderRadius: 12,
                // decrease radius of background bubble
                tabs: [
                  GButton(icon: Icons.home_outlined,),
                  GButton(icon: Icons.business, ),
                  GButton(
                    icon: Icons.favorite_border_outlined,
                  ),
                  GButton(icon: Icons.history, ),
                  GButton(icon: Icons.person_2_outlined),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  if (index == 0) {
                    // Handle home tab with double-tap detection
                    _handleHomeTap();
                  } else {
                    // For other tabs, just change the index
                    setState(() {
                      _selectedIndex = index;
                    });
                  }
                },
              ),
            ),
          ),
        ),
        floatingActionButton: StreamBuilder<List<ComparisonItem>>(
          stream: ComparisonListService().comparisonStream,
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            final count = items.length;

            return Badge(
              label: Text('$count'),
              isLabelVisible: count > 0,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UnifiedAIChatScreen(),
                    ),
                  );
                },
                backgroundColor: AppColors.mainColor,
                icon: Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                ),
                label: Text(
                  l10n.aiAssistant,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                elevation: 6,
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
