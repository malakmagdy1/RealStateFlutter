/// AI Configuration
/// Note: API key is now on backend - this is just for model names reference
class AppConfig {
  // Model names (for reference - actual calls go through backend)
  static const String geminiModel = 'gemini-2.0-flash';
  static const String salesAssistantModel = 'gemini-2.0-flash';

  // Generation config (for reference - actual config is on backend)
  static const double temperature = 0.7;
  static const int maxOutputTokens = 2000;
  static const double topP = 0.95;
  static const int topK = 40;
  static const int salesMaxOutputTokens = 500;

  // API key removed - now on backend only
  // static const String geminiApiKey = '...'; // REMOVED FOR SECURITY
}
