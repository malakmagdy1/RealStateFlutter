import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/core/locale/language_service.dart';
import '../bloc/unified_chat_bloc.dart';
import '../bloc/unified_chat_event.dart';
import '../bloc/unified_chat_state.dart';
import '../widget/property_card_widget.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';
import '../../data/models/comparison_item.dart';
import '../../data/services/comparison_list_service.dart';

/// 🚀 UNIFIED AI CHAT SCREEN
/// يجمع Algorithm 1 (Property Search) + Algorithm 2 (Sales Advice)
/// في شاشة واحدة مع AI ذكي يقرر
class UnifiedAIChatScreen extends StatefulWidget {
  final List<ComparisonItem>? comparisonItems;

  const UnifiedAIChatScreen({
    super.key,
    this.comparisonItems,
  });

  @override
  State<UnifiedAIChatScreen> createState() => _UnifiedAIChatScreenState();
}

class _UnifiedAIChatScreenState extends State<UnifiedAIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComparisonExpanded = false;

  @override
  void initState() {
    super.initState();
    print('');
    print('==============================================');
    print('🤖 UNIFIED AI CHAT SCREEN OPENED');
    if (widget.comparisonItems != null && widget.comparisonItems!.isNotEmpty) {
      print('📊 COMPARISON MODE: ${widget.comparisonItems!.length} items');
      for (var item in widget.comparisonItems!) {
        print('   - ${item.type}: ${item.name}');
      }
    }
    print('==============================================');
    print('');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnifiedChatBloc>().add(const LoadChatHistoryEvent());

      // If comparison items provided, send comparison request
      if (widget.comparisonItems != null && widget.comparisonItems!.isNotEmpty) {
        _sendComparisonRequest();
      }
    });
  }

  void _sendComparisonRequest() {
    if (widget.comparisonItems == null || widget.comparisonItems!.isEmpty) return;

    print('');
    print('==============================================');
    print('📊 SENDING COMPARISON REQUEST');
    print('Items: ${widget.comparisonItems!.map((i) => '${i.type}:${i.name}').join(', ')}');
    print('==============================================');
    print('');

    // Use the dedicated SendComparisonEvent for better prompt formatting
    context.read<UnifiedChatBloc>().add(SendComparisonEvent(widget.comparisonItems!));

    _scrollToBottom();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearHistory),
        content: Text(l10n.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              this.context.read<UnifiedChatBloc>().add(const ClearChatHistoryEvent());
              Navigator.pop(context);
            },
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = LanguageService.currentLanguage;
    final isArabic = currentLang == 'ar';
    final brokerName = isArabic ? 'أبو خالد' : 'Senior Alex';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('🎯 $brokerName - ${l10n.aiChat}'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: l10n.clearAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // Comparison dropdown (collapsible)
          _buildComparisonDropdown(),

          // Quick action buttons
          _buildQuickButtons(),

          const Divider(height: 1),

          // Messages
          Expanded(
            child: BlocConsumer<UnifiedChatBloc, UnifiedChatState>(
              listener: (context, state) {
                if (state is ChatLoaded && state.messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
              },
              builder: (context, state) {
                print('🔍 Chat State: ${state.runtimeType}');

                if (state is ChatHistoryLoading) {
                  return Container(
                    color: Colors.grey.shade50,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomLoadingDots(size: 80),
                          const SizedBox(height: 16),
                          Text(
                            l10n.loading,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
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
                return _buildEmptyState();
              },
            ),
          ),

          // Loading indicator
          BlocBuilder<UnifiedChatBloc, UnifiedChatState>(
            builder: (context, state) {
              if (state is ChatLoaded && state.isLoading) {
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      CustomLoadingDots(size: 30),
                      const SizedBox(width: 12),
                      Text(
                        l10n.loading,
                        style: TextStyle(
                          color: Colors.grey.shade700,
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

          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildQuickButtons() {
    final currentLang = LanguageService.currentLanguage;
    final isArabic = currentLang == 'ar';

    // Quick actions - defined locally (prompts handled by backend)
    final quickPrompts = isArabic ? [
      {'icon': '👤', 'text': 'إزاي أتعامل مع عميل جديد؟'},
      {'icon': '🤔', 'text': 'عندي عميل متردد، إيه النصيحة؟'},
      {'icon': '💰', 'text': 'العميل بيقول السعر غالي، أعمل إيه؟'},
      {'icon': '🎯', 'text': 'إزاي أقفل الصفقة بنجاح؟'},
      {'icon': '🤝', 'text': 'نصائح التفاوض على السعر'},
      {'icon': '📈', 'text': 'عميل عايز يستثمر، أنصحه بإيه؟'},
    ] : [
      {'icon': '👤', 'text': 'How to approach a new client?'},
      {'icon': '🤔', 'text': 'Client is hesitant, what should I do?'},
      {'icon': '💰', 'text': 'Client says price is too high, how to handle?'},
      {'icon': '🎯', 'text': 'How to successfully close the deal?'},
      {'icon': '🤝', 'text': 'Price negotiation tips'},
      {'icon': '📈', 'text': 'Client wants to invest, what to recommend?'},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickPrompts.length,
        itemBuilder: (context, index) {
          final prompt = quickPrompts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(
                '${prompt['icon']} ${prompt['text']}',
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                _messageController.text = prompt['text'] as String;
                _sendMessage();
              },
              backgroundColor: AppColors.mainColor.withOpacity(0.1),
              side: BorderSide(color: AppColors.mainColor.withOpacity(0.3)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aiChat,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.searchFor,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            _buildSuggestionChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final currentLang = LanguageService.currentLanguage;
    final isArabic = currentLang == 'ar';

    // Show first 3 suggestions in empty state
    final suggestions = isArabic ? [
      'إزاي أتعامل مع عميل جديد؟',
      'العميل بيقول السعر غالي، أعمل إيه؟',
      'إزاي أقفل الصفقة بنجاح؟',
    ] : [
      'How to approach a new client?',
      'Client says price is too high, how to handle?',
      'How to successfully close the deal?',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(
            suggestion,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          backgroundColor: AppColors.mainColor.withOpacity(0.1),
          side: BorderSide(color: AppColors.mainColor.withOpacity(0.3)),
          onPressed: () {
            _messageController.text = suggestion;
            _sendMessage();
          },
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(String message) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.error,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<UnifiedChatMessage> messages) {
    print('🎨 Building messages list with ${messages.length} messages');
    return Container(
      color: Colors.grey.shade50,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          print('💬 Message $index: ${message.isUser ? "User" : "AI"}');
          return _buildMessageBubble(message);
        },
      ),
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
          _buildAiMessage(message),
          const SizedBox(height: 12),
          // Property cards
          ...message.units!.map((unit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 340,
                  child: PropertyCardWidget(unit: unit),
                ),
              )),
        ],
      );
    } else {
      messageContent = _buildAiMessage(message);
    }

    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser && (message.units == null || message.units!.isEmpty))
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: messageContent,
            )
          else if (message.isUser)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: messageContent,
            )
          else
            Expanded(child: messageContent), // Full width for property results
        ],
      ),
    );
  }

  Widget _buildUserMessage(UnifiedChatMessage message) {
    print('👤 Building user message: "${message.content}"');

    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.mainColor,
          borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Widget _buildAiMessage(UnifiedChatMessage message) {
    final isError = message.isError;
    print('🤖 Building AI message: "${message.content.substring(0, message.content.length > 50 ? 50 : message.content.length)}"');
    print('   isError: $isError');

    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isError ? Colors.red.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isError ? Colors.red.shade300 : Colors.grey.shade400,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smart_toy,
                  size: 16,
                  color: isError ? Colors.red.shade700 : AppColors.mainColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: isError ? Colors.red.shade700 : AppColors.mainColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.content,
              style: TextStyle(
                color: isError ? Colors.red.shade900 : Colors.black,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
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
                  hintText: '${l10n.search}...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.mainColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonDropdown() {
    final comparisonService = ComparisonListService();
    return StreamBuilder<List<ComparisonItem>>(
      stream: comparisonService.comparisonStream,
      initialData: comparisonService.currentItems,
      builder: (context, snapshot) {
        final items = snapshot.data ?? comparisonService.currentItems;
        if (items.isEmpty) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context)!;

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // Collapsed header with "Start Compare" button
              Material(
                color: AppColors.mainColor.withOpacity(0.1),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isComparisonExpanded = !_isComparisonExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          _isComparisonExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: AppColors.mainColor,
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.compare_arrows,
                          color: AppColors.mainColor,
                          size: 20
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${items.length} ${items.length == 1 ? 'item' : 'items'} for comparison',
                            style: TextStyle(
                              color: AppColors.mainColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _startComparison(items);
                          },
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Start Compare'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8
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
                  color: Colors.grey.shade50,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.mainColor.withOpacity(0.2),
                            child: Icon(
                              item.type == 'unit'
                                  ? Icons.apartment
                                  : item.type == 'compound'
                                  ? Icons.business
                                  : Icons.domain,
                              color: AppColors.mainColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${item.type.toUpperCase()} • ${item.data['location'] ?? 'Location N/A'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 20),
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

              const Divider(height: 1),
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
    print('📊 START COMPARISON CLICKED');
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
}
