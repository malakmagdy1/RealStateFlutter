import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/chat_history_service.dart';
import '../../data/chat_remote_data_source.dart';
import '../../domain/chat_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// BLoC for managing AI chat state and logic
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRemoteDataSource _remoteDataSource;
  final ChatHistoryService _historyService;

  ChatBloc({
    ChatRemoteDataSource? remoteDataSource,
    ChatHistoryService? historyService,
  })  : _remoteDataSource = remoteDataSource ?? ChatRemoteDataSource(),
        _historyService = historyService ?? ChatHistoryService(),
        super(const ChatInitial()) {
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<ClearChatHistoryEvent>(_onClearChatHistory);
    on<ResetChatSessionEvent>(_onResetChatSession);
  }

  /// Get the current conversation ID
  String? get currentConversationId => _remoteDataSource.currentConversationId;

  /// Load chat history from local storage
  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatHistoryLoading());

    try {
      // First try to get saved conversation ID
      final savedConversationId = await _historyService.getConversationId();

      if (savedConversationId != null) {
        // Set the conversation ID in the remote data source
        _remoteDataSource.setConversationId(savedConversationId);

        // Try to load from server
        try {
          final serverMessages = await _historyService.loadConversationFromServer(savedConversationId);
          if (serverMessages.isNotEmpty) {
            print('[ChatBloc] Loaded ${serverMessages.length} messages from server');
            emit(ChatLoaded(messages: serverMessages));
            return;
          }
        } catch (e) {
          print('[ChatBloc] Could not load from server: $e');
        }
      }

      // Fallback to local storage
      final messages = await _historyService.loadChatHistory();
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      emit(ChatError(
        message: 'Failed to load chat history: ${e.toString()}',
      ));
    }
  }

  /// Send a message to the AI
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (event.message.trim().isEmpty) return;

    print('[ChatBloc] Processing message: "${event.message}"');

    final currentState = state;
    final currentMessages = currentState is ChatLoaded
        ? currentState.messages
        : currentState is ChatError
            ? currentState.previousMessages
            : <ChatMessage>[];

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...currentMessages, userMessage];

    // Emit loading state with user message
    emit(ChatLoaded(messages: updatedMessages, isLoading: true));

    try {
      // Get AI response
      print('[ChatBloc] Calling AI API...');
      final aiMessage = await _remoteDataSource.sendMessage(event.message);
      print('[ChatBloc] Received AI response');

      final finalMessages = [...updatedMessages, aiMessage];

      // Save conversation ID if we have one
      if (_remoteDataSource.currentConversationId != null) {
        await _historyService.saveConversationId(_remoteDataSource.currentConversationId);
      }

      // Save to local storage (backup)
      await _historyService.saveChatHistory(finalMessages);

      // Emit success state
      emit(ChatLoaded(messages: finalMessages, isLoading: false));
    } catch (e) {
      print('[ChatBloc] Error: $e');

      // Create error message
      final errorMessage = ChatMessage(
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

  /// Clear all chat history
  Future<void> _onClearChatHistory(
    ClearChatHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      print('[ChatBloc] Clearing chat history...');

      // Delete conversation from server if we have one
      final conversationId = _remoteDataSource.currentConversationId;
      if (conversationId != null) {
        try {
          await _historyService.deleteConversation(conversationId);
        } catch (e) {
          print('[ChatBloc] Could not delete server conversation: $e');
        }
      }

      // Clear local history
      await _historyService.clearChatHistory();
      print('[ChatBloc] Local history cleared, resetting chat session...');

      _remoteDataSource.resetChat();
      print('[ChatBloc] Chat session reset, emitting empty state');

      emit(const ChatLoaded(messages: []));
      print('[ChatBloc] Clear history completed successfully');
    } catch (e) {
      print('[ChatBloc] Error clearing history: $e');
      emit(ChatError(
        message: 'Failed to clear chat history: ${e.toString()}',
        previousMessages: const [],
      ));
    }
  }

  /// Reset the chat session (keeps history but starts new conversation)
  Future<void> _onResetChatSession(
    ResetChatSessionEvent event,
    Emitter<ChatState> emit,
  ) async {
    _remoteDataSource.resetChat();
    await _historyService.saveConversationId(null);

    final currentState = state;
    if (currentState is ChatLoaded) {
      // Clear messages to start fresh
      emit(const ChatLoaded(messages: []));
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Please log in to use the AI assistant.';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
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
    _remoteDataSource.dispose();
    return super.close();
  }
}
