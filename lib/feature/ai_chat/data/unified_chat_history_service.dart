import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/bloc/unified_chat_state.dart';

/// Service for managing unified chat history persistence
class UnifiedChatHistoryService {
  static const String _unifiedHistoryKey = 'unified_chat_history';

  /// Save unified chat history
  Future<void> saveUnifiedChatHistory(List<UnifiedChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = messages.map((msg) => msg.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_unifiedHistoryKey, jsonString);
      print('[ChatHistoryService] ✅ Saved ${messages.length} messages');
    } catch (e) {
      print('[ChatHistoryService] ❌ Error saving history: $e');
      rethrow;
    }
  }

  /// Load unified chat history
  Future<List<UnifiedChatMessage>> loadUnifiedChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_unifiedHistoryKey);

      if (jsonString == null || jsonString.isEmpty) {
        print('[ChatHistoryService] No history found');
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      final messages = jsonList
          .map((json) => UnifiedChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      print('[ChatHistoryService] ✅ Loaded ${messages.length} messages');
      return messages;
    } catch (e) {
      print('[ChatHistoryService] ❌ Error loading history: $e');
      return [];
    }
  }

  /// Clear unified chat history
  Future<void> clearUnifiedChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_unifiedHistoryKey);
      print('[ChatHistoryService] ✅ History cleared');
    } catch (e) {
      print('[ChatHistoryService] ❌ Error clearing history: $e');
      rethrow;
    }
  }
}
