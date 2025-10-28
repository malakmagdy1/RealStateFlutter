// Web-specific implementation
import 'dart:html' as html;

void setGoogleSignInPrompt(String value) {
  html.window.localStorage['google_sign_in_prompt'] = value;
}
