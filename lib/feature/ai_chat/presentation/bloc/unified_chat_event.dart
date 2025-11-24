import 'package:equatable/equatable.dart';
import '../../data/models/comparison_item.dart';

/// Unified Chat Events
abstract class UnifiedChatEvent extends Equatable {
  const UnifiedChatEvent();

  @override
  List<Object?> get props => [];
}

/// Load chat history from storage
class LoadChatHistoryEvent extends UnifiedChatEvent {
  const LoadChatHistoryEvent();
}

/// Send a message (user input)
class SendMessageEvent extends UnifiedChatEvent {
  final String message;

  const SendMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// Send a comparison request with structured data
class SendComparisonEvent extends UnifiedChatEvent {
  final List<ComparisonItem> items;

  const SendComparisonEvent(this.items);

  @override
  List<Object?> get props => [items];
}

/// Clear all chat history
class ClearChatHistoryEvent extends UnifiedChatEvent {
  const ClearChatHistoryEvent();
}
