import 'package:equatable/equatable.dart';
import '../../domain/chat_message.dart';

/// Base class for all chat states
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any interaction
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// State when chat history is being loaded
class ChatHistoryLoading extends ChatState {
  const ChatHistoryLoading();
}

/// State when chat is ready with messages
class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const ChatLoaded({
    required this.messages,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [messages, isLoading];

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// State when an error occurs
class ChatError extends ChatState {
  final String message;
  final List<ChatMessage> previousMessages;

  const ChatError({
    required this.message,
    this.previousMessages = const [],
  });

  @override
  List<Object?> get props => [message, previousMessages];
}
