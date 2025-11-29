import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/l10n/app_localizations.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_cache_service.dart';
import '../widgets/notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  static String routeName = '/notifications';

  NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  final NotificationCacheService _cacheService = NotificationCacheService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  /// Load notifications from cache
  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final cachedNotifications = await _cacheService.getAllNotifications();
      setState(() {
        notifications = cachedNotifications;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<NotificationModel> _getFilteredNotifications(String filter) {
    if (filter == 'all') {
      return notifications;
    } else if (filter == 'unread') {
      return notifications.where((n) => !n.isRead).toList();
    } else {
      return notifications.where((n) => n.type == filter).toList();
    }
  }

  int _getUnreadCount() {
    return notifications.where((n) => !n.isRead).toList().length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        title: Text(
          l10n.notifications,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.white),
            onPressed: () async {
              await _cacheService.markAllAsRead();
              await _loadNotifications();
              if (mounted) {
                MessageHelper.showSuccess(context, l10n.markedAllAsRead);
              }
            },
            tooltip: l10n.markAllAsRead,
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: () {
              _showClearAllDialog();
            },
            tooltip: l10n.clearAll,
          ),
        ],
      ),
      body: _buildNotificationsList('all'),
    );
  }

  Widget _buildNotificationsList(String filter) {
    final l10n = AppLocalizations.of(context)!;
    final filteredNotifications = _getFilteredNotifications(filter);

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              l10n.noNotifications,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.greyText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              l10n.allCaughtUp,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.greyText,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.mainColor,
      onRefresh: () async {
        await _loadNotifications();
      },
      child: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppColors.mainColor,
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () async {
              // Mark as read in cache
              await _cacheService.markAsRead(notification.id);
              await _loadNotifications();
              if (mounted) {
                _showNotificationDetails(notification);
              }
            },
            onDelete: () async {
              // Delete from cache
              await _cacheService.deleteNotification(notification.id);
              await _loadNotifications();
              if (mounted) {
                MessageHelper.showSuccess(context, l10n.notificationDeleted);
              }
            },
          );
        },
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.greyText,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  if (notification.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        notification.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Icon(Icons.image, size: 50),
                              ),
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllNotifications),
        content: Text(l10n.clearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              // Clear all notifications from cache
              await _cacheService.clearAllNotifications();
              await _loadNotifications();

              Navigator.pop(context);

              if (mounted) {
                MessageHelper.showSuccess(context, l10n.allNotificationsCleared);
              }
            },
            child: Text(
              l10n.clearAll,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}