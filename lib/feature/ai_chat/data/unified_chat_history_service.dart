import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/bloc/unified_chat_state.dart';

/// Service for managing unified chat history (local storage)
class UnifiedChatHistoryService {
  static const String _chatHistoryKey = 'unified_ai_chat_history';
  static const int _maxLocalMessages = 100;

  /// Save unified chat history locally
  Future<void> saveUnifiedChatHistory(List<UnifiedChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Keep only last N messages
      final messagesToSave = messages.length > _maxLocalMessages
          ? messages.sublist(messages.length - _maxLocalMessages)
          : messages;

      final jsonList = messagesToSave.map((m) => m.toJson()).toList();
      await prefs.setString(_chatHistoryKey, jsonEncode(jsonList));

      print('[UnifiedChatHistoryService] Saved ${messagesToSave.length} messages');
    } catch (e) {
      print('[UnifiedChatHistoryService] Error saving history: $e');
    }
  }

  /// Load unified chat history from local storage
  Future<List<UnifiedChatMessage>> loadUnifiedChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_chatHistoryKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      final messages = jsonList
          .map((json) => UnifiedChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      print('[UnifiedChatHistoryService] Loaded ${messages.length} messages');
      return messages;
    } catch (e) {
      print('[UnifiedChatHistoryService] Error loading history: $e');
      return [];
    }
  }

  /// Clear local chat history
  Future<void> clearUnifiedChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatHistoryKey);
      print('[UnifiedChatHistoryService] History cleared');
    } catch (e) {
      print('[UnifiedChatHistoryService] Error clearing history: $e');
    }
  }
}
