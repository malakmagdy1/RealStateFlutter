// Stub implementation for non-web platforms
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
