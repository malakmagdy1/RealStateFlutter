// Web-specific implementation
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

void setGoogleSignInPrompt(String value) {
  html.window.localStorage['google_sign_in_prompt'] = value;
}

String? getLocalStorageItem(String key) {
  return html.window.localStorage[key];
}

void setLocalStorageItem(String key, String value) {
  html.window.localStorage[key] = value;
}

void removeLocalStorageItem(String key) {
  html.window.localStorage.remove(key);
}

void showWebNotification(String title, String body) {
  // Check if browser supports notifications
  if (html.Notification.supported) {
    // Request permission if not granted
    html.Notification.requestPermission().then((permission) {
      if (permission == 'granted') {
        // Show notification
        html.Notification(title, body: body, icon: '/firebase-logo.png');
      }
    });
  }
}

void reloadWebPage() {
  html.window.location.reload();
}

// IndexedDB constants - must match service worker
const String _dbName = 'notifications_db';
const String _storeName = 'pending_notifications';
const int _dbVersion = 1;

// StreamController for notification updates
StreamController<Map<String, dynamic>>? _notificationController;

/// Get a stream of new notifications from the service worker
Stream<Map<String, dynamic>> getNotificationStream() {
  _notificationController ??= StreamController<Map<String, dynamic>>.broadcast();
  return _notificationController!.stream;
}

/// Initialize listener for service worker messages
void initServiceWorkerListener() {
  html.window.navigator.serviceWorker?.addEventListener('message', (event) {
    final messageEvent = event as html.MessageEvent;
    final data = messageEvent.data;

    print('[WEB] Received message from service worker: $data');

    if (data != null && data['type'] == 'NEW_NOTIFICATION') {
      final notification = data['notification'];
      if (notification != null) {
        print('[WEB] New notification received: ${notification['title']}');
        _notificationController?.add(Map<String, dynamic>.from(notification));
      }
    }
  });

  print('[WEB] Service worker message listener initialized');
}

/// Get notifications from IndexedDB
Future<List<Map<String, dynamic>>> getNotificationsFromIndexedDB() async {
  try {
    // Open the database
    final db = await html.window.indexedDB!.open(_dbName, version: _dbVersion,
      onUpgradeNeeded: (event) {
        final database = (event.target as dynamic).result;
        if (!(database.objectStoreNames as List).contains(_storeName)) {
          database.createObjectStore(_storeName, keyPath: 'id');
        }
      },
    );

    final transaction = db.transaction(_storeName, 'readonly');
    final store = transaction.objectStore(_storeName);
    final getAllRequest = store.getAll(null);

    await getAllRequest.onSuccess.first;

    final result = getAllRequest.result as List<dynamic>?;
    db.close();

    if (result == null || result.isEmpty) {
      print('[WEB] No notifications in IndexedDB');
      return [];
    }

    print('[WEB] Found ${result.length} notifications in IndexedDB');
    return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  } catch (e) {
    print('[WEB] Error reading from IndexedDB: $e');
    return [];
  }
}

/// Clear a specific notification from IndexedDB
Future<void> deleteNotificationFromIndexedDB(String notificationId) async {
  try {
    final db = await html.window.indexedDB!.open(_dbName, version: _dbVersion);

    final transaction = db.transaction(_storeName, 'readwrite');
    final store = transaction.objectStore(_storeName);
    store.delete(notificationId);

    await transaction.completed;
    db.close();

    print('[WEB] Deleted notification from IndexedDB: $notificationId');
  } catch (e) {
    print('[WEB] Error deleting from IndexedDB: $e');
  }
}

/// Clear all notifications from IndexedDB
Future<void> clearNotificationsFromIndexedDB() async {
  try {
    // Method 1: Clear the object store first
    try {
      final db = await html.window.indexedDB!.open(_dbName, version: _dbVersion);
      final transaction = db.transaction(_storeName, 'readwrite');
      final store = transaction.objectStore(_storeName);
      store.clear();
      await transaction.completed;
      db.close();
      print('[WEB] Cleared IndexedDB store');
    } catch (e) {
      print('[WEB] Error clearing store: $e');
    }

    // Method 2: Delete the entire database - properly await the deletion
    try {
      await html.window.indexedDB!.deleteDatabase(_dbName).timeout(
        Duration(seconds: 2),
        onTimeout: () {
          print('[WEB] IndexedDB delete timed out, continuing anyway');
          throw TimeoutException('IndexedDB delete timed out');
        },
      );
      print('[WEB] Deleted IndexedDB database: $_dbName');
    } catch (e) {
      print('[WEB] Error deleting database: $e');
    }

    // Method 3: Clear localStorage directly
    _clearAllNotificationStorage();

    print('[WEB] Cleared all notifications from IndexedDB and localStorage');
  } catch (e) {
    print('[WEB] Error clearing notifications: $e');
  }
}

/// Clear all notification-related data from localStorage
void _clearAllNotificationStorage() {
  try {
    // Direct keys
    html.window.localStorage.remove('cached_notifications');
    html.window.localStorage.remove('flutter.cached_notifications');

    // Find and remove all notification-related keys
    final allKeys = html.window.localStorage.keys.toList();
    for (final key in allKeys) {
      if (key.toLowerCase().contains('notification') ||
          key.toLowerCase().contains('cached_notification')) {
        html.window.localStorage.remove(key);
        print('[WEB] Removed localStorage key: $key');
      }
    }

    print('[WEB] Cleared all notification localStorage keys');
  } catch (e) {
    print('[WEB] Error clearing localStorage: $e');
  }
}

/// Force clear all notification data - call this from Flutter
Future<void> forceClearAllNotifications() async {
  print('[WEB] Force clearing all notifications...');

  // Clear localStorage first
  _clearAllNotificationStorage();

  // Clear IndexedDB - properly await the deletion
  try {
    // First try to clear the store
    try {
      final db = await html.window.indexedDB!.open(_dbName, version: _dbVersion);
      final transaction = db.transaction(_storeName, 'readwrite');
      final store = transaction.objectStore(_storeName);
      store.clear();
      await transaction.completed;
      db.close();
    } catch (e) {
      print('[WEB] Error clearing store in force clear: $e');
    }

    // Then delete the database
    await html.window.indexedDB!.deleteDatabase(_dbName).timeout(
      Duration(seconds: 2),
      onTimeout: () {
        print('[WEB] Force delete IndexedDB timed out');
        throw TimeoutException('Force delete IndexedDB timed out');
      },
    );
    print('[WEB] Force deleted IndexedDB');
  } catch (e) {
    print('[WEB] Error force deleting IndexedDB: $e');
  }

  print('[WEB] Force clear completed');
}
