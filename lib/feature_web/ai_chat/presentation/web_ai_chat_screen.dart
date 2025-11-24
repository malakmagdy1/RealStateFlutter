import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import '../../../feature/ai_chat/presentation/bloc/unified_chat_bloc.dart';
import '../../../feature/ai_chat/presentation/bloc/unified_chat_event.dart';
import '../../../feature/ai_chat/presentation/bloc/unified_chat_state.dart';
import '../../widgets/web_property_card_widget.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';
import '../../../feature/ai_chat/data/services/comparison_list_service.dart';
import '../../../feature/ai_chat/data/models/comparison_item.dart';

/// Web-optimized AI Chat Screen with desktop-friendly layout
class WebAiChatScreen extends StatefulWidget {
  const WebAiChatScreen({super.key});

  @override
  State<WebAiChatScreen> createState() => _WebAiChatScreenState();
}

class _WebAiChatScreenState extends State<WebAiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComparisonExpanded = false;

  @override
  void initState() {
    super.initState();
    print('');
    print('==============================================');
    print('🤖 WEB AI CHAT SCREEN OPENED');
    print('==============================================');
    print('');
    // Load chat history when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnifiedChatBloc>().add(const LoadChatHistoryEvent());
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    print('');
    print('==============================================');
    print('💬 USER SENT MESSAGE: "$message"');
    print('==============================================');
    print('');

    context.read<UnifiedChatBloc>().add(SendMessageEvent(message));
    _messageController.clear();

    // Scroll to bottom after messages are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Wait longer for layout to complete
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_scrollController.hasClients && mounted) {
          try {
            final maxExtent = _scrollController.position.maxScrollExtent;
            if (maxExtent > 0) {
              _scrollController.animateTo(
                maxExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          } catch (e) {
            print('⚠️ Scroll error: $e');
          }
        }
      });
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              this.context.read<UnifiedChatBloc>().add(const ClearChatHistoryEvent());
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFFF8F9FA),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 32,
                          color: AppColors.mainColor,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'AI Property Assistant',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const Spacer(),
                        // Clear button
                        OutlinedButton.icon(
                          onPressed: _clearChat,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Clear Chat'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ask me about properties, units, or compounds',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Comparison dropdown
                    _buildComparisonDropdown(),

                    // Messages area
                    Expanded(
                      child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: BlocConsumer<UnifiedChatBloc, UnifiedChatState>(
                      listener: (context, state) {
                        // Scroll to bottom when new messages arrive
                        if (state is ChatLoaded && state.messages.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToBottom();
                          });
                        }
                      },
                      builder: (context, state) {
                        print('🔍 Chat State: ${state.runtimeType}');

                        if (state is ChatHistoryLoading) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomLoadingDots(
                                  size: 120,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Loading chat history...',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (state is ChatLoaded) {
                          print('📝 Messages count: ${state.messages.length}');
                          if (state.messages.isEmpty) {
                            return _buildEmptyState();
                          }
                          return _buildMessagesList(state.messages);
                        } else if (state is ChatError) {
                          return _buildErrorState(state.message);
                        }
                        // ChatInitial state
                        return _buildEmptyState();
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Loading indicator
                BlocBuilder<UnifiedChatBloc, UnifiedChatState>(
                  builder: (context, state) {
                    if (state is ChatLoaded && state.isLoading) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CustomLoadingDots(
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'AI is thinking...',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                      return const SizedBox.shrink();
                    },
                    ),

                    const SizedBox(height: 16),

                    // Input field
                    _buildInputField(),
              ],
            ),
          ),
        ),
      ),

      // Floating Comparison Cart (like mobile)
      // Positioned(
      //   bottom: 16,
      //   right: 16,
      //   left: 16,
      //   child: Center(
      //       child: ConstrainedBox(
      //         constraints: const BoxConstraints(maxWidth: 600),
      //         child: StreamBuilder<List<ComparisonItem>>(
      //           stream: ComparisonListService().comparisonStream,
      //           builder: (context, snapshot) {
      //             final items = snapshot.data ?? [];
      //             if (items.isEmpty) return const SizedBox.shrink();

      //             return _buildFloatingComparisonCart(items);
      //           },
      //         ),
      //       ),
      //     ),
      //   ),
        )],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Start a conversation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ask me about properties, units, or compounds',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 32),
            _buildSuggestionChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'Show me villas in New Cairo',
      '3-bedroom apartment under 3M',
      'Compounds with swimming pool',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(
            suggestion,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 14,
            ),
          ),
          backgroundColor: AppColors.mainColor.withOpacity(0.1),
          side: BorderSide(color: AppColors.mainColor.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onPressed: () {
            _messageController.text = suggestion;
            _sendMessage();
          },
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<UnifiedChatMessage> messages) {
    print('🎨 Building messages list with ${messages.length} messages');
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        print('💬 Message $index: ${message.isUser ? "User" : "AI"} - ${message.content.substring(0, message.content.length > 30 ? 30 : message.content.length)}...');
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(UnifiedChatMessage message) {
    print('💬 Building message bubble - isUser: ${message.isUser}, hasUnits: ${message.units != null && message.units!.isNotEmpty}');

    Widget messageContent;
    if (message.isUser) {
      messageContent = _buildUserMessage(message);
    } else if (message.units != null && message.units!.isNotEmpty) {
      // Property results with cards
      messageContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI text response
          if (message.content.isNotEmpty) ...[
            _buildAiMessage(message),
            const SizedBox(height: 12),
          ],
          // Property cards
          ...message.units!.map((unit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 340,
                  child: WebPropertyCardWidget(unit: unit),
                ),
              )),
        ],
      );
    } else {
      messageContent = _buildAiMessage(message);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: 20,
                color: AppColors.mainColor,
              ),
            ),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: message.isUser || (message.units == null || message.units!.isEmpty)
                    ? 600  // Text messages keep wider width
                    : 380, // Property cards are narrower (increased height)
              ),
              child: messageContent,
            ),
          ),
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.mainColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 20,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(UnifiedChatMessage message) {
    print('👤 Building user message: "${message.content}"');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mainColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.content,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAiMessage(UnifiedChatMessage message) {
    final isError = message.isError;
    print('🤖 Building AI message: "${message.content.substring(0, message.content.length > 50 ? 50 : message.content.length)}"');
    print('   isError: $isError');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isError ? Colors.red.shade300 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: isError ? Colors.red.shade900 : Colors.black87,
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Ask about properties...',
                hintStyle: const TextStyle(
                  color: Color(0xFF999999),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.mainColor),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Row(
              children: [
                Icon(Icons.send, size: 20),
                SizedBox(width: 8),
                Text(
                  'Send',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonDropdown() {
    return StreamBuilder<List<ComparisonItem>>(
      stream: ComparisonListService().comparisonStream,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Collapsed header with "Start Compare" button
              Material(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: _isComparisonExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      )
                    : BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isComparisonExpanded = !_isComparisonExpanded;
                    });
                  },
                  borderRadius: _isComparisonExpanded
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        )
                      : BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          _isComparisonExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: AppColors.mainColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.compare_arrows,
                          color: AppColors.mainColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${items.length} ${items.length == 1 ? 'item' : 'items'} for comparison',
                            style: TextStyle(
                              color: AppColors.mainColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _startComparison(items);
                          },
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text('Start Compare'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Expanded list of items
              if (_isComparisonExpanded)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.mainColor.withOpacity(0.2),
                            radius: 24,
                            child: Icon(
                              item.type == 'unit'
                                  ? Icons.apartment
                                  : item.type == 'compound'
                                      ? Icons.business
                                      : Icons.domain,
                              color: AppColors.mainColor,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${item.type.toUpperCase()} • ${item.data['location'] ?? 'Location N/A'}',
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 24),
                            color: Colors.red,
                            onPressed: () {
                              ComparisonListService().removeAt(index);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _startComparison(List<ComparisonItem> items) {
    if (items.isEmpty) return;

    // Build comparison prompt
    final itemNames = items.map((item) => '${item.type}: ${item.name}').join(', ');
    final comparisonPrompt = 'Compare these units: $itemNames';

    print('');
    print('==============================================');
    print('📊 WEB START COMPARISON CLICKED');
    print('Items: ${items.length}');
    print('Prompt: $comparisonPrompt');
    print('==============================================');
    print('');

    // Send comparison event to AI
    context.read<UnifiedChatBloc>().add(SendComparisonEvent(items));

    // Clear the comparison list
    ComparisonListService().clear();

    // Collapse the dropdown
    setState(() {
      _isComparisonExpanded = false;
    });

    // Scroll to bottom to see the response
    _scrollToBottom();
  }

  Widget _buildFloatingComparisonCart(List<ComparisonItem> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 80), // Space above input field
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isComparisonExpanded = !_isComparisonExpanded;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    // Icon with badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.compare_arrows,
                            color: AppColors.mainColor,
                            size: 24,
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${items.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Text info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comparison List',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${items.length} ${items.length == 1 ? 'item' : 'items'} selected',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action buttons
                    ElevatedButton.icon(
                      onPressed: () {
                        _startComparison(items);
                      },
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('Compare'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    IconButton(
                      icon: Icon(
                        _isComparisonExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _isComparisonExpanded = !_isComparisonExpanded;
                        });
                      },
                    ),
                  ],
                ),

                // Expanded list
                if (_isComparisonExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.type == 'unit'
                                  ? Icons.home
                                  : item.type == 'compound'
                                      ? Icons.apartment
                                      : Icons.business,
                              color: AppColors.mainColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.data['location'] != null)
                                    Text(
                                      item.data['location'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: Colors.red,
                              onPressed: () {
                                ComparisonListService().removeAt(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ComparisonListService().clear();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
