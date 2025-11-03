import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/feature/notifications/data/services/notification_cache_service.dart';
import 'package:real/feature/notifications/data/models/notification_model.dart';
import 'package:real/core/utils/web_utils_stub.dart' if (dart.library.html) 'package:real/core/utils/web_utils_web.dart';

// ============================================================
// BACKGROUND MESSAGE HANDLER (Top-level function required)
// ============================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📬 Background Message: ${message.notification?.title}');

  // Save notification to cache (works on mobile, not on web service worker)
  final notificationModel = NotificationModel(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: message.notification?.title ?? message.data['title'] ?? 'Notification',
    message: message.notification?.body ?? message.data['body'] ?? '',
    type: message.data['type'] ?? 'general',
    timestamp: DateTime.now(),
    isRead: false,
    imageUrl: message.data['image_url'],
    data: message.data,
  );

  await NotificationCacheService().saveNotification(notificationModel);
  print('💾 Background notification saved to cache');
}

// ============================================================
// FCM SERVICE - Handles all Firebase Cloud Messaging logic
// ============================================================
class FCMService {
  // Singleton pattern
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Firebase & Notification instances
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Track shown notification IDs to prevent duplicates
  final Set<String> _shownNotificationIds = <String>{};

  // ⚠️ IMPORTANT: Use correct URL for your platform
  // Android Emulator: https://aqar.bdcbiz.com
  // iOS Simulator: https://aqar.bdcbiz.com
  // Physical Device: http://YOUR_COMPUTER_IP:8001
  static String API_BASE = 'https://aqar.bdcbiz.com';

  // Web Push VAPID key for web notifications
  static const String VAPID_KEY = 'BKNUQN5DnmFPV9XbrqwGvuVHHSlDwq2a9PjzmcbSbrMDVJEaGk-w_5MLdkV2dOWn6RUPwPQBK_0lrz0aZemHDVI';

  // ============================================================
  // INITIALIZATION - Call this in main.dart
  // ============================================================
  Future<void> initialize() async {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔔 Initializing FCM Service... (${kIsWeb ? 'Web' : 'Mobile'})');
    print('═══════════════════════════════════════════════════════');

    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else {
      print('❌ User denied notification permission');
      return;
    }

    // Initialize local notifications for foreground (skip on web)
    if (!kIsWeb) {
      await _initializeLocalNotifications();
    }

    // Get FCM token (with VAPID key for web)
    _fcmToken = kIsWeb
        ? await _firebaseMessaging.getToken(vapidKey: VAPID_KEY)
        : await _firebaseMessaging.getToken();
    if (_fcmToken != null) {
      print('');
      print('╔════════════════════════════════════════════════════════════╗');
      print('║              FCM TOKEN GENERATED                           ║');
      print('╠════════════════════════════════════════════════════════════╣');
      print('║                                                            ║');
      print('║ Token: ${_fcmToken!.substring(0, 50).padRight(50)}... ║');
      print('║                                                            ║');
      print('╚════════════════════════════════════════════════════════════╝');
      print('');

      // Check if user is already logged in and send token immediately
      final authToken = CasheNetwork.getCasheData(key: 'token');
      if (authToken.isNotEmpty) {
        print('✅ User already logged in - sending FCM token to backend...');
        await sendTokenToBackend(_fcmToken!);
      } else {
        print('ℹ️  User not logged in - FCM token will be sent after login');
      }
    }

    // Listen for token refresh (e.g., after reinstall)
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token Refreshed!');
      _fcmToken = newToken;
      sendTokenToBackend(newToken);
    });

    // Subscribe to "all" topic for broadcast messages (not supported on web)
    if (!kIsWeb) {
      await _firebaseMessaging.subscribeToTopic('all');
      print('✅ Subscribed to "all" topic for broadcast notifications');
    } else {
      print('ℹ️  Topic subscriptions not supported on web - use web push instead');
    }

    // On web, check for notifications saved by service worker in localStorage
    if (kIsWeb) {
      await _migrateWebNotificationsFromLocalStorage();
    }

    print('✅ FCM Service initialized successfully');
    print('═══════════════════════════════════════════════════════');
    print('');
  }

  // ============================================================
  // MIGRATE WEB NOTIFICATIONS FROM LOCALSTORAGE
  // ============================================================
  Future<void> _migrateWebNotificationsFromLocalStorage() async {
    try {
      print('🔄 Checking for pending web notifications in localStorage...');

      // Read from localStorage (only available on web)
      final pendingNotificationsJson = getLocalStorageItem('pending_web_notifications');

      if (pendingNotificationsJson != null && pendingNotificationsJson.isNotEmpty) {
        final List<dynamic> pendingNotifications = jsonDecode(pendingNotificationsJson);

        print('📦 Found ${pendingNotifications.length} pending notifications');

        // Migrate each notification to SharedPreferences
        for (var notifJson in pendingNotifications) {
          try {
            final notification = NotificationModel.fromJson(notifJson);
            await NotificationCacheService().saveNotification(notification);
            print('✅ Migrated notification: ${notification.title}');
          } catch (e) {
            print('⚠️ Error migrating notification: $e');
          }
        }

        // Clear localStorage after migration
        removeLocalStorageItem('pending_web_notifications');
        print('🗑️ Cleared pending notifications from localStorage');
      } else {
        print('ℹ️ No pending notifications found in localStorage');
      }
    } catch (e) {
      print('❌ Error migrating notifications from localStorage: $e');
    }
  }

  // ============================================================
  // LOCAL NOTIFICATIONS SETUP (for foreground messages)
  // ============================================================
  Future<void> _initializeLocalNotifications() async {
    AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📲 Local notification tapped: ${response.payload}');
        // TODO: Handle notification tap and navigate to specific screen
      },
    );

    // Create Android notification channel
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('✅ Local notifications initialized');
  }

  // ============================================================
  // SEND TOKEN TO LARAVEL BACKEND (After Login)
  // ============================================================
  Future<bool> sendTokenToBackend(String token) async {
    try {
      // Get the user's auth token from cache
      final authToken = CasheNetwork.getCasheData(key: 'token');

      if (authToken.isEmpty) {
        print('⚠️ No auth token found. User not logged in.');
        print('📝 FCM token will be sent when user logs in');
        return false;
      }

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 Sending FCM token to backend...');
      print('═══════════════════════════════════════════════════════');

      final response = await http.post(
        Uri.parse('$API_BASE/api/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': token,
        }),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('');
          print('╔════════════════════════════════════════════════════╗');
          print('║   ✅ FCM TOKEN SAVED TO BACKEND SUCCESSFULLY!     ║');
          print('╠════════════════════════════════════════════════════╣');
          print('║   User ID: ${data['data']['user_id'].toString().padRight(39)} ║');
          print('║   You will now receive notifications!             ║');
          print('╚════════════════════════════════════════════════════╝');
          print('');
          return true;
        }
      }

      print('❌ Failed to send FCM token: ${response.statusCode}');
      print('═══════════════════════════════════════════════════════');
      print('');
      return false;

    } catch (e) {
      print('❌ Error sending FCM token to backend: $e');
      print('═══════════════════════════════════════════════════════');
      print('');
      return false;
    }
  }

  // ============================================================
  // HANDLE FOREGROUND MESSAGES (App is open)
  // ============================================================
  void handleForegroundMessage(RemoteMessage message) async {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('📨 FOREGROUND MESSAGE RECEIVED');
    print('═══════════════════════════════════════════════════════');
    print('MessageID: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
    print('═══════════════════════════════════════════════════════');
    print('');

    // Check for duplicate notifications
    final notificationId = message.messageId ??
                          message.data['notification_id'] ??
                          DateTime.now().millisecondsSinceEpoch.toString();

    if (_shownNotificationIds.contains(notificationId)) {
      print('⚠️ Duplicate notification detected (foreground), skipping: $notificationId');
      return;
    }

    // Add to shown set
    _shownNotificationIds.add(notificationId);

    // Keep only last 100 IDs to prevent memory issues
    if (_shownNotificationIds.length > 100) {
      final idsToKeep = _shownNotificationIds.toList().sublist(_shownNotificationIds.length - 50);
      _shownNotificationIds.clear();
      _shownNotificationIds.addAll(idsToKeep);
    }

    await _saveNotificationToCache(message);

    // Show local notification when app is in foreground (skip on web)
    if (message.notification != null && !kIsWeb) {
      _localNotifications.show(
        message.notification.hashCode,
        message.notification!.title,
        message.notification!.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  // ============================================================
  // SAVE NOTIFICATION TO CACHE (Helper method)
  // ============================================================
  Future<void> _saveNotificationToCache(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    // Always save notification to cache, even if notification is null
    final notificationModel = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? message.data['title'] ?? 'Notification',
      message: notification?.body ?? message.data['body'] ?? '',
      type: message.data['type'] ?? 'general',
      timestamp: DateTime.now(),
      isRead: false,
      imageUrl: message.data['image_url'],
      data: message.data,
    );

    print('💾 Saving notification to cache...');
    print('   ID: ${notificationModel.id}');
    print('   Title: ${notificationModel.title}');
    print('   Type: ${notificationModel.type}');

    await NotificationCacheService().saveNotification(notificationModel);

    // Verify it was saved
    final allNotifications = await NotificationCacheService().getAllNotifications();
    print('✅ Notification saved! Total notifications in cache: ${allNotifications.length}');
    print('');
  }

  // ============================================================
  // HANDLE NOTIFICATION TAP (User clicked notification)
  // ============================================================
  void handleNotificationTap(RemoteMessage message) async {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('👆 NOTIFICATION TAPPED!');
    print('═══════════════════════════════════════════════════════');
    print('Data: ${message.data}');
    print('═══════════════════════════════════════════════════════');
    print('');

    // Save to cache in case it wasn't saved before (e.g., background notification on web)
    await _saveNotificationToCache(message);

    // Navigate based on notification type
    if (message.data.containsKey('type')) {
      final type = message.data['type'];

      switch (type) {
        case 'new_unit':
          final unitId = message.data['unit_id'];
          print('🏢 Navigate to Unit Details: $unitId');
          // TODO: Add navigation
          // Navigator.pushNamed(navigatorKey.currentContext!, '/unit-details', arguments: unitId);
          break;

        case 'new_sale':
          final saleId = message.data['sale_id'];
          print('💰 Navigate to Sale Details: $saleId');
          // TODO: Add navigation
          break;

        default:
          print('ℹ️ Unknown notification type: $type');
      }
    }
  }

  // ============================================================
  // CLEAR TOKEN (Call on logout)
  // ============================================================
  Future<void> clearToken() async {
    try {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('🗑️ Clearing FCM token...');
      print('═══════════════════════════════════════════════════════');

      final authToken = CasheNetwork.getCasheData(key: 'token');

      if (authToken.isNotEmpty) {
        // Remove token from backend
        final response = await http.delete(
          Uri.parse('$API_BASE/api/fcm-token'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
          },
        );

        print('📥 Backend response: ${response.statusCode}');
      }

      // Delete local token from Firebase
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;

      print('✅ FCM token cleared successfully');
      print('═══════════════════════════════════════════════════════');
      print('');
    } catch (e) {
      print('❌ Error clearing FCM token: $e');
      print('═══════════════════════════════════════════════════════');
      print('');
    }
  }

  // ============================================================
  // SETUP MESSAGE LISTENERS (Call after user logs in)
  // ============================================================
  void setupMessageListeners() {
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(handleForegroundMessage);

    // Handle notification when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(handleNotificationTap);

    print('✅ FCM message listeners set up');
  }
}
