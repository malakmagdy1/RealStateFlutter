import 'package:equatable/equatable.dart';
import '../../../compound/data/models/unit_model.dart';

/// Unified Chat State
abstract class UnifiedChatState extends Equatable {
  const UnifiedChatState();

  @override
  List<Object?> get props => [];
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

  const ChatLoaded({
    required this.messages,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [messages, isLoading];

  ChatLoaded copyWith({
    List<UnifiedChatMessage>? messages,
    bool? isLoading,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
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

  @override
  List<Object?> get props => [message, previousMessages];
}

/// Unified Chat Message
class UnifiedChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<Unit>? units; // For property search results
  final bool isError;

  const UnifiedChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.units,
    this.isError = false,
  });

  @override
  List<Object?> get props => [id, content, isUser, timestamp, units, isError];

  UnifiedChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    List<Unit>? units,
    bool? isError,
  }) {
    return UnifiedChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      units: units ?? this.units,
      isError: isError ?? this.isError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'units': units?.map((u) => u.toJson()).toList(),
      'isError': isError,
    };
  }

  factory UnifiedChatMessage.fromJson(Map<String, dynamic> json) {
    return UnifiedChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      units: json['units'] != null
          ? (json['units'] as List)
              .map((u) => Unit.fromJson(u as Map<String, dynamic>))
              .toList()
          : null,
      isError: json['isError'] as bool? ?? false,
    );
  }
}
