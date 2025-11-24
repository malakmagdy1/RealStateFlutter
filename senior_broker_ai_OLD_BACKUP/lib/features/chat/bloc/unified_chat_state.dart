import '../../../sales_assistant/data/unified_ai_data_source.dart';
import '../../data/models/comparison_item.dart';

/// Base state class
abstract class UnifiedChatState {
  const UnifiedChatState();
}

/// Initial state
class ChatInitial extends UnifiedChatState {
  const ChatInitial();
}

/// Loading chat history
class ChatHistoryLoading extends UnifiedChatState {
  const ChatHistoryLoading();
}

/// Chat loaded with messages
class ChatLoaded extends UnifiedChatState {
  final List<UnifiedChatMessage> messages;
  final bool isLoading;
  final List<ComparisonItem> comparisonItems;
  
  const ChatLoaded({
    required this.messages,
    this.isLoading = false,
    this.comparisonItems = const [],
  });
  
  ChatLoaded copyWith({
    List<UnifiedChatMessage>? messages,
    bool? isLoading,
    List<ComparisonItem>? comparisonItems,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      comparisonItems: comparisonItems ?? this.comparisonItems,
    );
  }
}

/// Error state
class ChatError extends UnifiedChatState {
  final String message;
  final List<UnifiedChatMessage> previousMessages;
  
  const ChatError({
    required this.message,
    this.previousMessages = const [],
  });
}

/// Chat message model
class UnifiedChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final List<Map<String, dynamic>>? units;
  final List<ComparisonItem>? comparisonItems;
  final AIResponseType? responseType;
  
  const UnifiedChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.units,
    this.comparisonItems,
    this.responseType,
  });
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
      'units': units,
      'responseType': responseType?.name,
    };
  }
  
  /// Create from JSON
  factory UnifiedChatMessage.fromJson(Map<String, dynamic> json) {
    return UnifiedChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isError: json['isError'] as bool? ?? false,
      units: json['units'] != null 
          ? List<Map<String, dynamic>>.from(json['units'])
          : null,
      responseType: json['responseType'] != null
          ? AIResponseType.values.firstWhere(
              (e) => e.name == json['responseType'],
              orElse: () => AIResponseType.salesAdvice,
            )
          : null,
    );
  }
  
  /// Check if this message contains property recommendations
  bool get hasProperties => units != null && units!.isNotEmpty;
  
  /// Check if this is a comparison response
  bool get isComparison => comparisonItems != null && comparisonItems!.isNotEmpty;
}
