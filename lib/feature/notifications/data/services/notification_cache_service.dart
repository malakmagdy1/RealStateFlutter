import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationCacheService extends ChangeNotifier {
  static final NotificationCacheService _instance = NotificationCacheService._internal();
  factory NotificationCacheService() => _instance;
  NotificationCacheService._internal();

  static String _notificationsKey = 'cached_notifications';

  // Cached unread count for quick access
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// Update and notify listeners about unread count change
  void _updateUnreadCount(List<NotificationModel> notifications) {
    final newCount = notifications.where((n) => !n.isRead).length;
    if (_unreadCount != newCount) {
      _unreadCount = newCount;
      notifyListeners();
    }
  }

  /// Generate a content hash for duplicate detection
  /// This helps identify the same notification even with different IDs
  String _generateContentHash(NotificationModel notification) {
    // Create hash from title + message + type (ignoring timestamp-based ID variations)
    return '${notification.title}_${notification.message}_${notification.type}'.toLowerCase();
  }

  /// Save a single notification to cache
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing notifications
      List<NotificationModel> notifications = await getAllNotifications();

      // Check if notification already exists (by id)
      int existingIndex = notifications.indexWhere((n) => n.id == notification.id);

      if (existingIndex != -1) {
        // Update existing notification
        notifications[existingIndex] = notification;
        print('✅ Notification updated in cache: ${notification.title}');
      } else {
        // Also check for content duplicates (same title/message/type within 5 minutes)
        final contentHash = _generateContentHash(notification);
        final fiveMinutesAgo = DateTime.now().subtract(Duration(minutes: 5));

        final contentDuplicate = notifications.any((n) {
          if (_generateContentHash(n) != contentHash) return false;
          // Only consider duplicates within the last 5 minutes
          return n.timestamp.isAfter(fiveMinutesAgo);
        });

        if (contentDuplicate) {
          print('⚠️ Duplicate notification detected (same content), skipping: ${notification.title}');
          return; // Skip saving duplicate
        }

        // Add new notification at the beginning (most recent first)
        notifications.insert(0, notification);
        print('✅ Notification saved to cache: ${notification.title}');
      }

      // Convert to JSON and save
      List<String> jsonList = notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_notificationsKey, jsonList);
      _updateUnreadCount(notifications);
    } catch (e) {
      print('❌ Error saving notification to cache: $e');
    }
  }

  /// Get all notifications from cache
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? jsonList = prefs.getStringList(_notificationsKey);

      if (jsonList == null || jsonList.isEmpty) {
        return [];
      }

      // Convert JSON strings to NotificationModel objects
      List<NotificationModel> notifications = jsonList
          .map((json) => NotificationModel.fromJson(jsonDecode(json)))
          .toList();

      // Sort by timestamp (most recent first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _updateUnreadCount(notifications);
      return notifications;
    } catch (e) {
      print('❌ Error loading notifications from cache: $e');
      return [];
    }
  }

  /// Delete a specific notification by ID
  Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing notifications
      List<NotificationModel> notifications = await getAllNotifications();

      // Remove the notification with the given ID
      notifications.removeWhere((n) => n.id == notificationId);

      // Save updated list
      List<String> jsonList = notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_notificationsKey, jsonList);
      _updateUnreadCount(notifications);

      print('✅ Notification deleted from cache: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification from cache: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      // Also set to empty list to ensure it's cleared on web
      await prefs.setStringList(_notificationsKey, []);
      await prefs.remove(_notificationsKey);
      // Force reload to clear any memory cache
      await prefs.reload();
      // Reset unread count to 0 and notify
      _unreadCount = 0;
      notifyListeners();
      print('✅ All notifications cleared from cache');
    } catch (e) {
      print('❌ Error clearing notifications from cache: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing notifications (without triggering update)
      List<String>? jsonList = prefs.getStringList(_notificationsKey);
      if (jsonList == null || jsonList.isEmpty) return;

      List<NotificationModel> notifications = jsonList
          .map((json) => NotificationModel.fromJson(jsonDecode(json)))
          .toList();

      // Find and update the notification
      int index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);

        // Save updated list
        List<String> updatedJsonList = notifications.map((n) => jsonEncode(n.toJson())).toList();
        await prefs.setStringList(_notificationsKey, updatedJsonList);
        _updateUnreadCount(notifications);

        print('✅ Notification marked as read: $notificationId');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing notifications (without triggering update)
      List<String>? jsonList = prefs.getStringList(_notificationsKey);
      if (jsonList == null || jsonList.isEmpty) return;

      List<NotificationModel> notifications = jsonList
          .map((json) => NotificationModel.fromJson(jsonDecode(json)))
          .toList();

      // Mark all as read
      notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();

      // Save updated list
      List<String> updatedJsonList = notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_notificationsKey, updatedJsonList);

      // Reset unread count to 0 and notify
      _unreadCount = 0;
      notifyListeners();

      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      List<NotificationModel> notifications = await getAllNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }
}
