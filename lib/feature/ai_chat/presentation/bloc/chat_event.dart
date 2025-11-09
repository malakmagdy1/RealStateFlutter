import 'package:equatable/equatable.dart';

/// Base class for all chat events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Event to send a message to the AI
class SendMessageEvent extends ChatEvent {
  final String message;

  const SendMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// Event to load chat history from local storage
class LoadChatHistoryEvent extends ChatEvent {
  const LoadChatHistoryEvent();
}

/// Event to clear the chat history
class ClearChatHistoryEvent extends ChatEvent {
  const ClearChatHistoryEvent();
}

/// Event to reset the chat session
class ResetChatSessionEvent extends ChatEvent {
  const ResetChatSessionEvent();
}
