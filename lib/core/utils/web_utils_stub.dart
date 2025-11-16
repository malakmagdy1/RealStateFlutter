// Stub implementation for non-web platforms
void setGoogleSignInPrompt(String value) {
  // No-op on non-web platforms
}

String? getLocalStorageItem(String key) {
  // No-op on non-web platforms
  return null;
}

void removeLocalStorageItem(String key) {
  // No-op on non-web platforms
}

void showWebNotification(String title, String body) {
  // No-op on non-web platforms (notifications handled by FCMService)
}
