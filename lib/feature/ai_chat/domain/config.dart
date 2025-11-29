/// AI Chat Configuration
///
/// Get your API key from: https://aistudio.google.com/app/apikey
class AppConfig {
  // API key from Google AI Studio (realState2 - Fresh key)
  static const String geminiApiKey = 'AIzaSyDPqe54op4APQDIANK4UZriK--DCvfpuPA';

  // Model to use (gemini-2.0-flash is free and fast)
  static const String geminiModel = 'gemini-2.0-flash';

  // Temperature: 0.0 = focused/deterministic, 1.0 = creative/random
  static const double temperature = 0.7;

  // Maximum response length in tokens
  static const int maxOutputTokens = 2000;

  // Top P sampling parameter
  static const double topP = 0.95;

  // Top K sampling parameter
  static const int topK = 40;

  // Sales Assistant Configuration
  static const String salesAssistantModel = 'gemini-2.0-flash';
  static const int salesMaxOutputTokens = 500; // Short responses for quick calls
}
