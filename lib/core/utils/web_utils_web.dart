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
    final db = await html.window.indexedDB!.open(_dbName, version: _dbVersion);

    final transaction = db.transaction(_storeName, 'readwrite');
    final store = transaction.objectStore(_storeName);
    store.clear();

    await transaction.completed;
    db.close();

    print('[WEB] Cleared all notifications from IndexedDB');
  } catch (e) {
    print('[WEB] Error clearing IndexedDB: $e');
  }
}
