import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/notifications/data/models/notification_model.dart';
import 'package:real/feature/notifications/data/services/notification_cache_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:real/core/utils/web_utils_stub.dart' if (dart.library.html) 'package:real/core/utils/web_utils_web.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';

class WebNotificationsScreen extends StatefulWidget {
  static String routeName = '/web-notifications';

  WebNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<WebNotificationsScreen> createState() => _WebNotificationsScreenState();
}

class _WebNotificationsScreenState extends State<WebNotificationsScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  final NotificationCacheService _cacheService = NotificationCacheService();
  Timer? _refreshTimer;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    print('[WEB NOTIFICATIONS SCREEN] initState called');

    // Initialize service worker listener
    initServiceWorkerListener();

    // Listen for new notifications from service worker
    _notificationSubscription = getNotificationStream().listen((notificationData) {
      print('[WEB NOTIFICATIONS] Received new notification from stream');
      _handleNewNotification(notificationData);
    });

    // First load notifications immediately
    _loadNotifications();

    // Check for pending notifications from IndexedDB
    _checkAndMigrateWebNotifications();

    // Refresh notifications every 5 seconds to catch new ones
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkAndMigrateWebNotifications();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _handleNewNotification(Map<String, dynamic> notificationData) async {
    try {
      final notification = NotificationModel(
        id: notificationData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: notificationData['title'] ?? '',
        message: notificationData['message'] ?? notificationData['body'] ?? '',
        type: notificationData['type'] ?? 'general',
        timestamp: notificationData['timestamp'] != null
            ? DateTime.parse(notificationData['timestamp'])
            : DateTime.now(),
        isRead: false,
        imageUrl: notificationData['imageUrl'] ?? notificationData['image_url'],
        data: notificationData['data'] != null
            ? Map<String, dynamic>.from(notificationData['data'])
            : null,
      );

      await _cacheService.saveNotification(notification);
      await _loadNotifications();
      print('[WEB NOTIFICATIONS] New notification added: ${notification.title}');
    } catch (e) {
      print('[WEB NOTIFICATIONS] Error handling new notification: $e');
    }
  }

  Future<void> _checkAndMigrateWebNotifications() async {
    try {
      print('[WEB NOTIFICATIONS] Checking IndexedDB for pending notifications...');

      // Get notifications from IndexedDB
      final pendingNotifications = await getNotificationsFromIndexedDB();

      if (pendingNotifications.isNotEmpty) {
        print('[WEB NOTIFICATIONS] Found ${pendingNotifications.length} pending notifications in IndexedDB');

        // Migrate each notification to SharedPreferences
        int successCount = 0;
        for (var notifJson in pendingNotifications) {
          try {
            final notification = NotificationModel(
              id: notifJson['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: notifJson['title'] ?? '',
              message: notifJson['message'] ?? notifJson['body'] ?? '',
              type: notifJson['type'] ?? 'general',
              timestamp: notifJson['timestamp'] != null
                  ? DateTime.parse(notifJson['timestamp'])
                  : DateTime.now(),
              isRead: notifJson['isRead'] ?? false,
              imageUrl: notifJson['imageUrl'] ?? notifJson['image_url'],
              data: notifJson['data'] != null
                  ? Map<String, dynamic>.from(notifJson['data'])
                  : null,
            );
            await _cacheService.saveNotification(notification);
            print('[WEB NOTIFICATIONS] Migrated notification: ${notification.title}');
            successCount++;
          } catch (e) {
            print('[WEB NOTIFICATIONS] Error migrating notification: $e');
          }
        }

        print('[WEB NOTIFICATIONS] Migration complete: $successCount/${pendingNotifications.length} notifications migrated');

        // Clear IndexedDB after migration
        await clearNotificationsFromIndexedDB();
        print('[WEB NOTIFICATIONS] Cleared pending notifications from IndexedDB');

        // Reload notifications to show the new ones
        await _loadNotifications();
      } else {
        // Just refresh the list
        await _loadNotifications();
      }
    } catch (e) {
      print('[WEB NOTIFICATIONS] Error checking pending notifications: $e');
      await _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    try {
      print('[WEB NOTIFICATIONS] Loading notifications from cache...');
      final cachedNotifications = await _cacheService.getAllNotifications();
      print('[WEB NOTIFICATIONS] Found ${cachedNotifications.length} notifications in cache');

      if (cachedNotifications.isNotEmpty) {
        print('[WEB NOTIFICATIONS] Sample notification: ${cachedNotifications.first.title}');
      }

      if (mounted) {
        setState(() {
          notifications = cachedNotifications;
          isLoading = false;
        });
        print('[WEB NOTIFICATIONS] UI updated with ${notifications.length} notifications');
      }
    } catch (e) {
      print('[WEB NOTIFICATIONS] Error loading notifications: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  int _getUnreadCount() {
    return notifications.where((n) => !n.isRead).toList().length;
  }

  IconData _getIconByType(String type) {
    switch (type) {
      case 'sale':
        return Icons.sell_rounded;
      case 'unit':
        return Icons.home_work_rounded;
      case 'compound':
        return Icons.location_city_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorByType(String type) {
    switch (type) {
      case 'sale':
        return Color(0xFFFF6B35);
      case 'unit':
        return Color(0xFF4E8FE1);
      case 'compound':
        return Color(0xFF22C55E);
      default:
        return AppColors.mainColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(l10n),
                SizedBox(height: 24),

                // Content
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CustomLoadingDots(
                            size: 120,
                          ),
                        )
                      : notifications.isEmpty
                          ? _buildEmptyState(l10n)
                          : _buildNotificationsList(notifications),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        // Icon and Title
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            size: 32,
            color: AppColors.mainColor,
          ),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.notifications,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              l10n.totalNotificationsCount(notifications.length),
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        Spacer(),

        // Refresh button
        _buildActionButton(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onPressed: () async {
            print('[WEB NOTIFICATIONS] Manual refresh triggered');
            setState(() {
              isLoading = true;
            });
            await _checkAndMigrateWebNotifications();
            MessageHelper.showSuccess(context, 'Notifications refreshed');
          },
          isPrimary: false,
        ),

        // Action buttons
        if (notifications.isNotEmpty) ...[
          SizedBox(width: 12),
          if (_getUnreadCount() > 0)
            _buildActionButton(
              icon: Icons.done_all_rounded,
              label: l10n.markAllAsRead,
              onPressed: () async {
                await _cacheService.markAllAsRead();
                await _loadNotifications();
                MessageHelper.showSuccess(context, l10n.markedAllAsRead);
              },
              isPrimary: true,
            ),
          SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.delete_sweep_rounded,
            label: l10n.clearAll,
            onPressed: _showClearAllDialog,
            isPrimary: false,
            isDestructive: true,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive
            ? Colors.red.shade50
            : (isPrimary ? AppColors.mainColor : Colors.white),
        foregroundColor: isDestructive
            ? Colors.red
            : (isPrimary ? Colors.white : Color(0xFF666666)),
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDestructive
                ? Colors.red.shade200
                : (isPrimary ? AppColors.mainColor : Color(0xFFE0E0E0)),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            l10n.noNotifications,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 8),
          Text(
            l10n.allCaughtUp,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final l10n = AppLocalizations.of(context)!;
    final color = _getColorByType(notification.type);
    final isUnread = !notification.isRead;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.shade50.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? AppColors.mainColor.withOpacity(0.3) : Color(0xFFE0E0E0),
          width: isUnread ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await _cacheService.markAsRead(notification.id);
            await _loadNotifications();
            _showNotificationDetails(notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconByType(notification.type),
                    color: color,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: AppColors.mainColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Color(0xFF999999),
                          ),
                          SizedBox(width: 4),
                          Text(
                            timeago.format(notification.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility_rounded, size: 20),
                      color: AppColors.mainColor,
                      tooltip: l10n.viewDetails,
                      onPressed: () async {
                        await _cacheService.markAsRead(notification.id);
                        await _loadNotifications();
                        _showNotificationDetails(notification);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded, size: 20),
                      color: Colors.red.shade400,
                      tooltip: l10n.delete,
                      onPressed: () async {
                        await _cacheService.deleteNotification(notification.id);
                        await _loadNotifications();
                        MessageHelper.showSuccess(context, l10n.notificationDeleted);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 550,
          constraints: BoxConstraints(maxHeight: 600),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getColorByType(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconByType(notification.type),
                      color: _getColorByType(notification.type),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Image (if available)
              if (notification.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    notification.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Message
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Timestamp
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: Color(0xFF999999),
                  ),
                  SizedBox(width: 6),
                  Text(
                    timeago.format(notification.timestamp),
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          l10n.clearAllNotifications,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(l10n.clearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await _cacheService.clearAllNotifications();
              await clearNotificationsFromIndexedDB(); // Also clear IndexedDB
              await _loadNotifications();
              context.pop();
              MessageHelper.showSuccess(context, l10n.allNotificationsCleared);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.clearAll,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
