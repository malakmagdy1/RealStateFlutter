import '../../ai_chat/data/ai_api_service.dart';

/// Sales Assistant - Uses backend API (no Gemini in Flutter)
class SalesAssistantRemoteDataSource {
  final AIApiService _apiService = AIApiService();

  SalesAssistantRemoteDataSource();

  /// Send a message and get sales advice from backend
  Future<String> getSalesAdvice(String userMessage) async {
    try {
      final response = await _apiService.salesAssistant(message: userMessage);

      if (response['success'] == true && response['data'] != null) {
        return response['data']['response'] ??
               response['data']['message'] ??
               'No response';
      }

      return 'Could not get sales advice';
    } catch (e) {
      print('[SalesAssistantRemoteDataSource] Error: $e');
      return 'عذراً، حدث خطأ في الاتصال.';
    }
  }

  /// Reset is not needed for API-based approach
  void resetChat() {
    // No-op - backend manages sessions
  }
}
