import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/router/app_router.dart';
import 'package:real/core/locale/locale_cubit.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/notifications/data/services/notification_cache_service.dart';
import 'package:real/feature/notifications/data/models/notification_model.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_event.dart';
import 'package:real/feature/subscription/presentation/bloc/subscription_state.dart';
import '../home/presentation/web_home_screen.dart';
import '../compounds/presentation/web_compounds_screen.dart';
import '../favorites/presentation/web_favorites_screen.dart';
import '../history/presentation/web_history_screen.dart';
import '../profile/presentation/web_profile_screen.dart';
import '../notifications/presentation/web_notifications_screen.dart';
import '../ai_chat/presentation/web_ai_chat_screen.dart';
import 'package:real/core/utils/web_utils_stub.dart' if (dart.library.html) 'package:real/core/utils/web_utils_web.dart';

class WebMainScreen extends StatefulWidget {
  static String routeName = '/web-main';

  const WebMainScreen({Key? key}) : super(key: key);

  @override
  State<WebMainScreen> createState() => _WebMainScreenState();
}

class _WebMainScreenState extends State<WebMainScreen> {
  int _selectedIndex = 0;
  int _unreadNotifications = 0;
  final NotificationCacheService _cacheService = NotificationCacheService();
  Timer? _notificationCheckTimer;

  final List<Widget> _screens = [
    WebHomeScreen(),
    const WebCompoundsScreen(),
    WebFavoritesScreen(),
    WebHistoryScreen(),
    const WebAiChatScreen(),
    WebNotificationsScreen(),
    WebProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // Check for new notifications every 3 seconds
    _notificationCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _loadUnreadCount();
    });

    // Load subscription status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionBloc>().add(LoadSubscriptionStatusEvent());
    });
  }

  @override
  void dispose() {
    _notificationCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      // First check for pending notifications from service worker
      await _checkAndMigrateWebNotifications();

      // Then load the count
      final notifications = await _cacheService.getAllNotifications();
      if (mounted) {
        setState(() {
          _unreadNotifications = notifications.where((n) => !n.isRead).length;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  Future<void> _checkAndMigrateWebNotifications() async {
    try {
      // Check localStorage for pending notifications from service worker (only available on web)
      final pendingNotificationsJson = getLocalStorageItem('pending_web_notifications');

      if (pendingNotificationsJson != null && pendingNotificationsJson.isNotEmpty) {
        final List<dynamic> pendingNotifications = jsonDecode(pendingNotificationsJson);

        // Migrate each notification to SharedPreferences
        for (var notifJson in pendingNotifications) {
          try {
            final notification = NotificationModel.fromJson(notifJson);
            await _cacheService.saveNotification(notification);
          } catch (e) {
            print('⚠️ Error migrating notification: $e');
          }
        }

        // Clear localStorage after migration
        removeLocalStorageItem('pending_web_notifications');
      }
    } catch (e) {
      print('❌ Error checking pending notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          _buildNavBar(l10n),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(AppLocalizations l10n) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFE6E6E6),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  // Logo
                  const Text(
                    '🏘️',
                    style: TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainColor,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Subscription Status Badge (Clickable)
                  BlocBuilder<SubscriptionBloc, SubscriptionState>(
                    builder: (context, state) {
                      if (state is SubscriptionStatusLoaded) {
                        final status = state.status;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _showSubscriptionDialog(context, status),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: status.hasActiveSubscription
                                      ? [
                                          AppColors.mainColor.withOpacity(0.2),
                                          AppColors.mainColor.withOpacity(0.1),
                                        ]
                                      : [
                                          Colors.grey[300]!,
                                          Colors.grey[200]!,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: status.hasActiveSubscription
                                      ? AppColors.mainColor.withOpacity(0.3)
                                      : Colors.grey[400]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    status.hasActiveSubscription
                                        ? Icons.workspace_premium
                                        : Icons.info_outline,
                                    size: 16,
                                    color: status.hasActiveSubscription
                                        ? AppColors.mainColor
                                        : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    status.planNameEn.isNotEmpty
                                        ? status.planNameEn
                                        : (status.hasActiveSubscription ? l10n.active : l10n.free),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: status.hasActiveSubscription
                                          ? AppColors.mainColor
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(width: 24),

                  // Language Selector
                  BlocBuilder<LocaleCubit, Locale>(
                    builder: (context, locale) {
                      return PopupMenuButton<String>(
                        offset: const Offset(0, 50),
                        tooltip: l10n.changeLanguage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                size: 18,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                locale.languageCode == 'ar' ? 'العربية' : 'English',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 18,
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'en',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 18,
                                  color: locale.languageCode == 'en'
                                      ? AppColors.mainColor
                                      : Colors.transparent,
                                ),
                                const SizedBox(width: 8),
                                const Text('English'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'ar',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 18,
                                  color: locale.languageCode == 'ar'
                                      ? AppColors.mainColor
                                      : Colors.transparent,
                                ),
                                const SizedBox(width: 8),
                                const Text('العربية'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (String languageCode) {
                          context.read<LocaleCubit>().changeLocale(Locale(languageCode));
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 24),

                  // Navigation Links
                  _buildNavItem(l10n.home, 0, Icons.home_outlined, Icons.home),
                  const SizedBox(width: 24),
                  _buildNavItem(l10n.compounds, 1, Icons.apartment_outlined, Icons.apartment),
                  const SizedBox(width: 24),
                  _buildNavItem(l10n.favorites, 2, Icons.favorite_border, Icons.favorite),
                  const SizedBox(width: 24),
                  _buildNavItem(l10n.history, 3, Icons.history_outlined, Icons.history),
                  const SizedBox(width: 24),
                  _buildNavItem(l10n.aiChat, 4, Icons.smart_toy_outlined, Icons.smart_toy),
                  const SizedBox(width: 24),
                  _buildNavItemWithBadge(l10n.notifications, 5, Icons.notifications_outlined, Icons.notifications, _unreadNotifications),
                  const SizedBox(width: 24),
                  _buildNavItem(l10n.profile, 6, Icons.person_outline, Icons.person),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, int index, IconData outlinedIcon, IconData filledIcon) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 5) {
          _loadUnreadCount(); // Reload count when notifications screen is opened
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              size: 20,
              color: isSelected ? AppColors.mainColor : const Color(0xFF666666),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.mainColor : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(String title, int index, IconData outlinedIcon, IconData filledIcon, int badgeCount) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _loadUnreadCount(); // Reload count when notifications screen is opened
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(
                  isSelected ? filledIcon : outlinedIcon,
                  size: 20,
                  color: isSelected ? AppColors.mainColor : const Color(0xFF666666),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.mainColor : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context, dynamic status) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
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
                      Colors.grey[800]!,
                      Colors.grey[700]!,
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  Icons.stars_rounded,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status.hasActiveSubscription
                            ? Icons.workspace_premium
                            : Icons.rocket_launch,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Status badge
                    if (status.hasActiveSubscription)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Title
                    Text(
                      status.hasActiveSubscription
                          ? l10n.yourCurrentPlan
                          : l10n.unlockPremiumFeatures,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Subtitle/Description
                    if (status.hasActiveSubscription) ...[
                      Text(
                        status.planNameEn ?? status.planName ?? 'Premium Plan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Search usage info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.searchAccess,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    status.isUnlimited
                                        ? l10n.unlimitedSearches
                                        : '${status.searchesUsed}/${status.searchesAllowed} Used',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (status.isUnlimited)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber[600],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.all_inclusive,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        l10n.unlimitedSearchesDescription,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Features list
                      ...[
                        l10n.unlimitedSearches,
                        l10n.advancedFilters,
                        l10n.prioritySupport,
                        l10n.exclusiveListings,
                      ].map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green[300],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],

                    const SizedBox(height: 24),

                    // Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              context.push('/subscription');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: status.hasActiveSubscription
                                  ? AppColors.mainColor
                                  : Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  status.hasActiveSubscription
                                      ? Icons.settings
                                      : Icons.star,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  status.hasActiveSubscription
                                      ? l10n.manageSubscription
                                      : l10n.viewPlans,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text(
                            l10n.close,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
