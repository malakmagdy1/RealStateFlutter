import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/chat_message.dart';
import 'ai_api_service.dart';

/// Service for managing chat history (local storage + server sync)
class ChatHistoryService {
  static const String _chatHistoryKey = 'ai_chat_history';
  static const String _conversationIdKey = 'ai_conversation_id';
  static const int _maxLocalMessages = 100;

  final AIApiService _apiService = AIApiService();

  /// Save chat history locally
  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Keep only last N messages
      final messagesToSave = messages.length > _maxLocalMessages
          ? messages.sublist(messages.length - _maxLocalMessages)
          : messages;

      final jsonList = messagesToSave.map((m) => m.toJson()).toList();
      await prefs.setString(_chatHistoryKey, jsonEncode(jsonList));

      print('[ChatHistoryService] Saved ${messagesToSave.length} messages locally');
    } catch (e) {
      print('[ChatHistoryService] Error saving history: $e');
    }
  }

  /// Load chat history from local storage
  Future<List<ChatMessage>> loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_chatHistoryKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      final messages = jsonList
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      print('[ChatHistoryService] Loaded ${messages.length} messages from local storage');
      return messages;
    } catch (e) {
      print('[ChatHistoryService] Error loading history: $e');
      return [];
    }
  }

  /// Clear local chat history
  Future<void> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatHistoryKey);
      await prefs.remove(_conversationIdKey);
      print('[ChatHistoryService] Local history cleared');
    } catch (e) {
      print('[ChatHistoryService] Error clearing history: $e');
    }
  }

  /// Save conversation ID
  Future<void> saveConversationId(String? conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (conversationId != null) {
        await prefs.setString(_conversationIdKey, conversationId);
      } else {
        await prefs.remove(_conversationIdKey);
      }
      print('[ChatHistoryService] Saved conversation ID: $conversationId');
    } catch (e) {
      print('[ChatHistoryService] Error saving conversation ID: $e');
    }
  }

  /// Get saved conversation ID
  Future<String?> getConversationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_conversationIdKey);
    } catch (e) {
      print('[ChatHistoryService] Error getting conversation ID: $e');
      return null;
    }
  }

  /// Load conversation from server
  Future<List<ChatMessage>> loadConversationFromServer(String conversationId) async {
    try {
      final response = await _apiService.getConversation(conversationId);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final messages = <ChatMessage>[];

        if (data['messages'] != null && data['messages'] is List) {
          for (var msg in data['messages'] as List) {
            messages.add(ChatMessage(
              id: msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              content: msg['content'] ?? '',
              isUser: msg['role'] == 'user',
              timestamp: msg['created_at'] != null
                  ? DateTime.parse(msg['created_at'])
                  : DateTime.now(),
            ));
          }
        }

        print('[ChatHistoryService] Loaded ${messages.length} messages from server');
        return messages;
      }

      return [];
    } catch (e) {
      print('[ChatHistoryService] Error loading from server: $e');
      return [];
    }
  }

  /// Delete conversation from server
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _apiService.deleteConversation(conversationId);
      print('[ChatHistoryService] Deleted conversation from server');
    } catch (e) {
      print('[ChatHistoryService] Error deleting from server: $e');
    }
  }
}
