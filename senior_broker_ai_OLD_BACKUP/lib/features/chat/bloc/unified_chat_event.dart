import '../../data/models/comparison_item.dart';
import '../bloc/unified_chat_bloc.dart';

/// Base event class
abstract class UnifiedChatEvent {
  const UnifiedChatEvent();
}

/// Load chat history from local storage
class LoadChatHistoryEvent extends UnifiedChatEvent {
  const LoadChatHistoryEvent();
}

/// Send a message to the AI
class SendMessageEvent extends UnifiedChatEvent {
  final String message;
  
  const SendMessageEvent({required this.message});
}

/// Send comparison request
class SendComparisonEvent extends UnifiedChatEvent {
  final List<ComparisonItem> items;
  final String? additionalContext;
  
  const SendComparisonEvent({
    required this.items,
    this.additionalContext,
  });
}

/// Clear all chat history
class ClearChatHistoryEvent extends UnifiedChatEvent {
  const ClearChatHistoryEvent();
}

/// Load available units from backend for recommendations
class LoadAvailableUnitsEvent extends UnifiedChatEvent {
  final List<Map<String, dynamic>> units;
  
  const LoadAvailableUnitsEvent({required this.units});
}

/// Quick advice request (predefined scenarios)
class AskForAdviceEvent extends UnifiedChatEvent {
  final AdviceType adviceType;
  
  const AskForAdviceEvent({required this.adviceType});
}

/// Start a comparison flow
class StartComparisonFlowEvent extends UnifiedChatEvent {
  const StartComparisonFlowEvent();
}

/// Add item to comparison
class AddToComparisonEvent extends UnifiedChatEvent {
  final ComparisonItem item;
  
  const AddToComparisonEvent({required this.item});
}

/// Remove item from comparison
class RemoveFromComparisonEvent extends UnifiedChatEvent {
  final String itemId;
  
  const RemoveFromComparisonEvent({required this.itemId});
}
