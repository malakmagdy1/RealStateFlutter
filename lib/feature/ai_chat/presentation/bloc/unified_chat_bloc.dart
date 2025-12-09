import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/unified_chat_history_service.dart';
import '../../data/models/comparison_item.dart';
import '../../../sales_assistant/data/unified_ai_data_source.dart';
import 'unified_chat_event.dart';
import 'unified_chat_state.dart';

/// Unified Chat BLoC
/// Uses backend API for all AI operations (no prompts in Flutter)
class UnifiedChatBloc extends Bloc<UnifiedChatEvent, UnifiedChatState> {
  final UnifiedAIDataSource _dataSource;
  final UnifiedChatHistoryService _historyService;

  UnifiedChatBloc({
    UnifiedAIDataSource? dataSource,
    UnifiedChatHistoryService? historyService,
  })  : _dataSource = dataSource ?? UnifiedAIDataSource(),
        _historyService = historyService ?? UnifiedChatHistoryService(),
        super(const ChatInitial()) {
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<SendComparisonEvent>(_onSendComparison);
    on<ClearChatHistoryEvent>(_onClearChatHistory);
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    emit(const ChatHistoryLoading());

    try {
      final messages = await _historyService.loadUnifiedChatHistory();
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      emit(ChatError(
        message: 'Failed to load chat history: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    if (event.message.trim().isEmpty) return;

    print('[UnifiedChatBloc] Processing message: "${event.message}"');

    final currentState = state;
    final currentMessages = currentState is ChatLoaded
        ? currentState.messages
        : currentState is ChatError
            ? currentState.previousMessages
            : <UnifiedChatMessage>[];

    // Add user message
    final userMessage = UnifiedChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...currentMessages, userMessage];

    // Emit loading state with user message
    emit(ChatLoaded(messages: updatedMessages, isLoading: true));

    try {
      print('[UnifiedChatBloc] Calling AI API...');

      // Call backend API (handles prompts on server)
      final aiResponse = await _dataSource.sendMessage(event.message);

      print('[UnifiedChatBloc] Received response type: ${aiResponse.type}');

      // Create AI message based on response type
      final aiMessage = UnifiedChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse.textResponse ?? _getDefaultResponse(aiResponse.type),
        isUser: false,
        timestamp: DateTime.now(),
        units: aiResponse.units,
      );

      final finalMessages = [...updatedMessages, aiMessage];

      // Save to local storage
      await _historyService.saveUnifiedChatHistory(finalMessages);

      // Emit success state
      emit(ChatLoaded(messages: finalMessages, isLoading: false));
    } catch (e) {
      print('[UnifiedChatBloc] Error: $e');

      // Create error message
      final errorMessage = UnifiedChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _getErrorMessage(e),
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      final messagesWithError = [...updatedMessages, errorMessage];

      emit(ChatLoaded(messages: messagesWithError, isLoading: false));
    }
  }

  Future<void> _onSendComparison(
    SendComparisonEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    if (event.items.isEmpty) return;

    print('[UnifiedChatBloc] Processing comparison of ${event.items.length} items');

    final currentState = state;
    final currentMessages = currentState is ChatLoaded
        ? currentState.messages
        : currentState is ChatError
            ? currentState.previousMessages
            : <UnifiedChatMessage>[];

    // Extract unit IDs for comparison
    final unitIds = event.items
        .where((item) => item.type == 'unit')
        .map((item) => int.tryParse(item.id) ?? 0)
        .where((id) => id > 0)
        .toList();

    // Build simple comparison message (backend handles the prompt)
    final comparisonMessage = _buildSimpleComparisonMessage(event.items);

    // Add user message
    final userMessage = UnifiedChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: comparisonMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...currentMessages, userMessage];

    // Emit loading state with user message
    emit(ChatLoaded(messages: updatedMessages, isLoading: true));

    try {
      print('[UnifiedChatBloc] Sending comparison to backend...');

      String responseText;

      // If we have 2+ units, use the compare endpoint
      if (unitIds.length >= 2) {
        responseText = await _dataSource.compareProperties(unitIds);
      } else {
        // Otherwise use chat with the items data
        final aiResponse = await _dataSource.sendMessage(comparisonMessage);
        responseText = aiResponse.textResponse ?? 'Could not compare';
      }

      print('[UnifiedChatBloc] Received comparison response');

      // Create AI message
      final aiMessage = UnifiedChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final finalMessages = [...updatedMessages, aiMessage];

      // Save to local storage
      await _historyService.saveUnifiedChatHistory(finalMessages);

      // Emit success state
      emit(ChatLoaded(messages: finalMessages, isLoading: false));
    } catch (e) {
      print('[UnifiedChatBloc] Comparison error: $e');

      // Create error message
      final errorMessage = UnifiedChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _getErrorMessage(e),
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      final messagesWithError = [...updatedMessages, errorMessage];

      emit(ChatLoaded(messages: messagesWithError, isLoading: false));
    }
  }

  /// Build a simple comparison message - backend handles the prompt
  String _buildSimpleComparisonMessage(List<ComparisonItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('Compare these properties:');
    buffer.writeln();

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      buffer.writeln('${i + 1}. ${item.name} (${item.type})');
      buffer.writeln(jsonEncode(item.data));
      buffer.writeln();
    }

    return buffer.toString();
  }

  Future<void> _onClearChatHistory(
    ClearChatHistoryEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    try {
      print('[UnifiedChatBloc] Clearing chat history...');
      await _historyService.clearUnifiedChatHistory();
      _dataSource.resetChat();
      emit(const ChatLoaded(messages: []));
      print('[UnifiedChatBloc] Clear history completed');
    } catch (e) {
      print('[UnifiedChatBloc] Error clearing history: $e');
      emit(ChatError(
        message: 'Failed to clear chat history: ${e.toString()}',
        previousMessages: const [],
      ));
    }
  }

  String _getDefaultResponse(AIResponseType type) {
    switch (type) {
      case AIResponseType.properties:
        return 'Here are some matching properties:';
      case AIResponseType.salesAdvice:
        return 'Here is my advice:';
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    print('[UnifiedChatBloc] Full error details: $error');

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Please log in to use the AI assistant.';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorStr.contains('quota') || errorStr.contains('rate limit')) {
      return 'Too many requests. Please try again later.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
