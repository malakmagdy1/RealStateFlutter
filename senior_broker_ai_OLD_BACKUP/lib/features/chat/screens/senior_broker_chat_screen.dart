import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/unified_chat_bloc.dart';
import '../bloc/unified_chat_event.dart';
import '../bloc/unified_chat_state.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/comparison_fab.dart';

/// 🎨 Senior Broker AI Chat Screen
/// Beautiful, bilingual chat interface for real estate brokers
class SeniorBrokerChatScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialUnits;
  
  const SeniorBrokerChatScreen({
    super.key,
    this.initialUnits,
  });

  @override
  State<SeniorBrokerChatScreen> createState() => _SeniorBrokerChatScreenState();
}

class _SeniorBrokerChatScreenState extends State<SeniorBrokerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  bool _showQuickActions = true;

  @override
  void initState() {
    super.initState();
    // Load chat history on init
    context.read<UnifiedChatBloc>().add(const LoadChatHistoryEvent());
    
    // Load available units if provided
    if (widget.initialUnits != null) {
      context.read<UnifiedChatBloc>().add(
        LoadAvailableUnitsEvent(units: widget.initialUnits!),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    context.read<UnifiedChatBloc>().add(SendMessageEvent(message: message));
    _messageController.clear();
    _focusNode.requestFocus();
    
    // Hide quick actions after first message
    if (_showQuickActions) {
      setState(() => _showQuickActions = false);
    }
    
    // Scroll to bottom
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context, isArabic),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: BlocConsumer<UnifiedChatBloc, UnifiedChatState>(
              listener: (context, state) {
                if (state is ChatLoaded && !state.isLoading) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is ChatHistoryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (state is ChatError && state.previousMessages.isEmpty) {
                  return _buildErrorView(state.message, isArabic);
                }
                
                final messages = state is ChatLoaded 
                    ? state.messages 
                    : state is ChatError 
                        ? state.previousMessages 
                        : <UnifiedChatMessage>[];
                
                if (messages.isEmpty) {
                  return _buildWelcomeView(isArabic);
                }
                
                return _buildMessagesList(messages, state is ChatLoaded && state.isLoading);
              },
            ),
          ),
          
          // Quick actions bar (shown initially)
          if (_showQuickActions)
            QuickActionsBar(
              onActionTap: (adviceType) {
                context.read<UnifiedChatBloc>().add(
                  AskForAdviceEvent(adviceType: adviceType),
                );
                setState(() => _showQuickActions = false);
              },
            ),
          
          // Message input area
          _buildInputArea(isArabic),
        ],
      ),
      floatingActionButton: ComparisonFab(
        onCompare: () {
          // Navigate to comparison selection screen
          // or show bottom sheet with comparison options
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isArabic) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1E3A5F), // Deep blue
      title: Row(
        children: [
          // AI Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Title and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'المستشار العقاري' : 'Senior Broker AI',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                isArabic ? 'متصل الآن' : 'Online',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Clear chat button
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => _showClearConfirmation(context, isArabic),
          tooltip: isArabic ? 'مسح المحادثة' : 'Clear Chat',
        ),
        // Settings button
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            // Navigate to settings
          },
          tooltip: isArabic ? 'الإعدادات' : 'Settings',
        ),
      ],
    );
  }

  Widget _buildWelcomeView(bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Welcome icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              size: 50,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isArabic ? 'أهلاً بيك يا باشا! 👋' : 'Welcome! 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isArabic 
                ? 'أنا المستشار العقاري بتاعك.\nعندي خبرة 20 سنة في السوق.\nاسألني أي حاجة!'
                : 'I\'m your Senior Broker AI.\n20 years of market experience.\nAsk me anything!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Feature cards
          _buildFeatureCard(
            icon: Icons.people_outline_rounded,
            title: isArabic ? 'نصائح العملاء' : 'Client Advice',
            subtitle: isArabic 
                ? 'إزاي تتعامل مع كل نوع عميل'
                : 'How to handle different clients',
          ),
          _buildFeatureCard(
            icon: Icons.home_work_outlined,
            title: isArabic ? 'توصيات الوحدات' : 'Unit Recommendations',
            subtitle: isArabic 
                ? 'أقترحلك أفضل الوحدات للعميل'
                : 'Best units for your client',
          ),
          _buildFeatureCard(
            icon: Icons.compare_arrows_rounded,
            title: isArabic ? 'مقارنة العقارات' : 'Property Comparison',
            subtitle: isArabic 
                ? 'قارن بين أي وحدتين أو أكتر'
                : 'Compare any two or more properties',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1E3A5F),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<UnifiedChatMessage> messages, bool isLoading) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (isLoading && index == messages.length) {
          return _buildTypingIndicator();
        }
        return ChatMessageBubble(message: messages[index]);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 150)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.4 + (value * 0.4)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildErrorView(String message, bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<UnifiedChatBloc>().add(const LoadChatHistoryEvent());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isArabic) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
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
      child: Row(
        children: [
          // Attachment button (optional)
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: Colors.grey[600],
            onPressed: () {
              // Show attachment options
            },
          ),
          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                hintText: isArabic ? 'اكتب رسالتك...' : 'Type your message...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A5F),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isArabic ? Icons.send_rounded : Icons.send_rounded,
                color: Colors.white,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'مسح المحادثة؟' : 'Clear Chat?'),
        content: Text(
          isArabic 
              ? 'هيتم مسح كل الرسائل. الإجراء ده مش ممكن التراجع عنه.'
              : 'All messages will be deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<UnifiedChatBloc>().add(const ClearChatHistoryEvent());
              Navigator.pop(context);
              setState(() => _showQuickActions = true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isArabic ? 'مسح' : 'Clear'),
          ),
        ],
      ),
    );
  }
}
