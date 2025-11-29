// Stub implementation for non-web platforms
import 'dart:async';

void setGoogleSignInPrompt(String value) {
  // No-op on non-web platforms
}

String? getLocalStorageItem(String key) {
  // No-op on non-web platforms
  return null;
}

void setLocalStorageItem(String key, String value) {
  // No-op on non-web platforms
}

void removeLocalStorageItem(String key) {
  // No-op on non-web platforms
}

void showWebNotification(String title, String body) {
  // No-op on non-web platforms (notifications handled by FCMService)
}

void reloadWebPage() {
  // No-op on non-web platforms
}

/// Get a stream of new notifications from the service worker (stub)
Stream<Map<String, dynamic>> getNotificationStream() {
  return Stream.empty();
}

/// Initialize listener for service worker messages (stub)
void initServiceWorkerListener() {
  // No-op on non-web platforms
}

/// Get notifications from IndexedDB (stub)
Future<List<Map<String, dynamic>>> getNotificationsFromIndexedDB() async {
  return [];
}

/// Clear a specific notification from IndexedDB (stub)
Future<void> deleteNotificationFromIndexedDB(String notificationId) async {
  // No-op on non-web platforms
}

/// Clear all notifications from IndexedDB (stub)
Future<void> clearNotificationsFromIndexedDB() async {
  // No-op on non-web platforms
}
