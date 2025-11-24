import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/chat/bloc/unified_chat_state.dart';

/// Service for managing chat history persistence
class UnifiedChatHistoryService {
  static const String _historyKey = 'unified_chat_history';
  static const int _maxMessagesToStore = 100;

  /// Load chat history from local storage
  Future<List<UnifiedChatMessage>> loadUnifiedChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList
          .map((json) => UnifiedChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[ChatHistoryService] ❌ Error loading history: $e');
      return [];
    }
  }

  /// Save chat history to local storage
  Future<void> saveUnifiedChatHistory(List<UnifiedChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Keep only the last N messages
      final messagesToStore = messages.length > _maxMessagesToStore
          ? messages.sublist(messages.length - _maxMessagesToStore)
          : messages;
      
      final historyJson = jsonEncode(
        messagesToStore.map((m) => m.toJson()).toList(),
      );
      
      await prefs.setString(_historyKey, historyJson);
      print('[ChatHistoryService] ✅ Saved ${messagesToStore.length} messages');
    } catch (e) {
      print('[ChatHistoryService] ❌ Error saving history: $e');
    }
  }

  /// Clear all chat history
  Future<void> clearUnifiedChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      print('[ChatHistoryService] ✅ History cleared');
    } catch (e) {
      print('[ChatHistoryService] ❌ Error clearing history: $e');
    }
  }

  /// Export chat history as text (for sharing or debugging)
  Future<String> exportChatHistory() async {
    final messages = await loadUnifiedChatHistory();
    final buffer = StringBuffer();
    
    buffer.writeln('=== Senior Broker AI Chat History ===');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Messages: ${messages.length}');
    buffer.writeln('=====================================\n');
    
    for (final message in messages) {
      final sender = message.isUser ? '👤 User' : '🤖 Senior Broker';
      final time = _formatTime(message.timestamp);
      buffer.writeln('[$time] $sender:');
      buffer.writeln(message.content);
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  String _formatTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
