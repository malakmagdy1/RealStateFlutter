// Web-specific implementation
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
