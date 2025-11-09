import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/chat_message.dart';

/// Service for persisting chat history locally
class ChatHistoryService {
  static const String _historyKey = 'ai_chat_history';
  static const int _maxHistoryLength = 50; // Keep last 50 messages

  /// Save chat history to local storage
  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Keep only the last N messages to avoid storage bloat
      final messagesToSave = messages.length > _maxHistoryLength
          ? messages.sublist(messages.length - _maxHistoryLength)
          : messages;

      final jsonList = messagesToSave.map((m) => m.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await prefs.setString(_historyKey, jsonString);
    } catch (e) {
      // Silently fail - chat history is not critical
      print('Failed to save chat history: $e');
    }
  }

  /// Load chat history from local storage
  Future<List<ChatMessage>> loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Failed to load chat history: $e');
      // Clear corrupted data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_historyKey);
      } catch (_) {}
      return [];
    }
  }

  /// Clear all chat history
  Future<void> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Failed to clear chat history: $e');
    }
  }

  /// Check if chat history exists
  Future<bool> hasHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_historyKey);
    } catch (e) {
      return false;
    }
  }
}
