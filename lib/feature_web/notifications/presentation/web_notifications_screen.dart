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

class WebNotificationsScreen extends StatefulWidget {
  static String routeName = '/web-notifications';

  WebNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<WebNotificationsScreen> createState() => _WebNotificationsScreenState();
}

class _WebNotificationsScreenState extends State<WebNotificationsScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  String selectedFilter = 'all';
  final NotificationCacheService _cacheService = NotificationCacheService();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Refresh notifications every 2 seconds to catch new ones
    _refreshTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _checkAndMigrateWebNotifications();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndMigrateWebNotifications() async {
    try {
      // Check localStorage for pending notifications from service worker (only available on web)
      final pendingNotificationsJson = getLocalStorageItem('pending_web_notifications');

      if (pendingNotificationsJson != null && pendingNotificationsJson.isNotEmpty) {
        final List<dynamic> pendingNotifications = jsonDecode(pendingNotificationsJson);

        print('📦 Found ${pendingNotifications.length} pending web notifications');

        // Migrate each notification to SharedPreferences
        for (var notifJson in pendingNotifications) {
          try {
            final notification = NotificationModel.fromJson(notifJson);
            await _cacheService.saveNotification(notification);
            print('✅ Migrated notification: ${notification.title}');
          } catch (e) {
            print('⚠️ Error migrating notification: $e');
          }
        }

        // Clear localStorage after migration
        removeLocalStorageItem('pending_web_notifications');
        print('🗑️ Cleared pending notifications from localStorage');

        // Reload notifications to show the new ones
        await _loadNotifications();
      } else {
        // Just refresh the list
        await _loadNotifications();
      }
    } catch (e) {
      print('❌ Error checking pending notifications: $e');
      await _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final cachedNotifications = await _cacheService.getAllNotifications();
      if (mounted) {
        setState(() {
          notifications = cachedNotifications;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<NotificationModel> _getFilteredNotifications() {
    if (selectedFilter == 'all') {
      return notifications;
    } else if (selectedFilter == 'unread') {
      return notifications.where((n) => !n.isRead).toList();
    } else {
      return notifications.where((n) => n.type == selectedFilter).toList();
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
    final filteredNotifications = _getFilteredNotifications();

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

                // Filters
                _buildFilters(l10n),
                SizedBox(height: 24),

                // Content
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.mainColor,
                          ),
                        )
                      : filteredNotifications.isEmpty
                          ? _buildEmptyState(l10n)
                          : _buildNotificationsList(filteredNotifications),
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

        // Action buttons
        if (notifications.isNotEmpty) ...[
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

  Widget _buildFilters(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', l10n.all, Icons.grid_view_rounded, notifications.length),
          SizedBox(width: 12),
          _buildFilterChip('unread', l10n.unread, Icons.mark_email_unread_rounded, _getUnreadCount()),
          SizedBox(width: 12),
          _buildFilterChip('sale', l10n.sales, Icons.sell_rounded, notifications.where((n) => n.type == 'sale').length),
          SizedBox(width: 12),
          _buildFilterChip('unit', l10n.units, Icons.home_work_rounded, notifications.where((n) => n.type == 'unit').length),
          SizedBox(width: 12),
          _buildFilterChip('compound', l10n.updates, Icons.location_city_rounded, notifications.where((n) => n.type == 'compound').length),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon, int count) {
    final isSelected = selectedFilter == filter;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mainColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.mainColor : Color(0xFFE0E0E0),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.mainColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Color(0xFF666666),
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Color(0xFF333333),
                ),
              ),
              if (count > 0) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.3) : Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ],
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
            selectedFilter == 'unread' ? l10n.noUnreadNotifications : l10n.noNotifications,
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
              SizedBox(height: 20),

              // View Details Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                    _navigateToDetails(notification);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.viewDetails,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  void _navigateToDetails(NotificationModel notification) {
    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case 'sale':
      case 'unit':
        // Show message that unit details require full data
        MessageHelper.showMessage(
          context: context,
          message: 'Unit details are not available from notifications yet',
          isSuccess: false,
        );
        break;

      case 'compound':
        // Show message that compound details require full data
        MessageHelper.showMessage(
          context: context,
          message: 'Compound details are not available from notifications yet',
          isSuccess: false,
        );
        break;

      default:
        MessageHelper.showError(context, AppLocalizations.of(context)!.noDetailsAvailable);
        break;
    }
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
