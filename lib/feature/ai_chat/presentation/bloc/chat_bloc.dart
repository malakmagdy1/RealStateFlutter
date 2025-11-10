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

  /// Load chat history from local storage
  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatHistoryLoading());

    try {
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

    print('[ChatBloc] 📨 Processing message: "${event.message}"');

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
      print('[ChatBloc] 🔄 Calling AI remote data source...');
      final aiMessage = await _remoteDataSource.sendMessage(event.message);
      print('[ChatBloc] ✅ Received AI response');
      final finalMessages = [...updatedMessages, aiMessage];

      // Save to local storage
      await _historyService.saveChatHistory(finalMessages);

      // Emit success state
      emit(ChatLoaded(messages: finalMessages, isLoading: false));
    } catch (e) {
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
      await _historyService.clearChatHistory();
      _remoteDataSource.resetChat();
      emit(const ChatLoaded(messages: []));
    } catch (e) {
      emit(ChatError(
        message: 'Failed to clear chat history: ${e.toString()}',
      ));
    }
  }

  /// Reset the chat session (keeps history but resets AI context)
  Future<void> _onResetChatSession(
    ResetChatSessionEvent event,
    Emitter<ChatState> emit,
  ) async {
    _remoteDataSource.resetChat();

    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith());
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('api key') || errorStr.contains('invalid_api_key')) {
      return 'API key is not configured. Please add your Google AI Studio API key in the config file.';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (errorStr.contains('quota') || errorStr.contains('rate limit')) {
      return 'API quota exceeded. Please try again later.';
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
