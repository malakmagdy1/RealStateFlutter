import 'package:flutter/material.dart';
import '../../data/unified_ai_data_source.dart';
import '../../../compound/data/models/unit_model.dart';
import '../../../compound/presentation/screen/unit_detail_screen.dart';
import 'package:real/core/utils/colors.dart';

class SalesAssistantScreen extends StatefulWidget {
  const SalesAssistantScreen({Key? key}) : super(key: key);

  @override
  State<SalesAssistantScreen> createState() => _SalesAssistantScreenState();
}

class _SalesAssistantScreenState extends State<SalesAssistantScreen> {
  late UnifiedAIDataSource _dataSource;
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataSource = UnifiedAIDataSource();

    // Welcome message
    _messages.add(ChatMessage(
      role: 'assistant',
      content: '👋 مرحباً! أنا مساعدك العقاري الذكي 🚀\n\n'
               'اسألني عن:\n'
               '🏘️ البحث عن عقارات ووحدات\n'
               '💰 نصائح المبيعات والحسابات\n'
               '🗣️ كيف ترد على اعتراضات العملاء\n'
               '📞 سكريبتات المكالمات\n\n'
               'اكتب سؤالك بالعربي أو English',
      type: ChatMessageType.text,
    ));
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        role: 'user',
        content: userMessage,
        type: ChatMessageType.text,
      ));
      _isLoading = true;
    });
    _controller.clear();

    _scrollToBottom();

    try {
      final response = await _dataSource.sendMessage(userMessage);

      setState(() {
        if (response.type == AIResponseType.properties && response.units != null) {
          // Property response - show units
          _messages.add(ChatMessage(
            role: 'assistant',
            content: response.textResponse ?? 'هذه أفضل الخيارات المتاحة:',
            type: ChatMessageType.properties,
            units: response.units,
          ));
        } else {
          // Sales advice response - show text only
          _messages.add(ChatMessage(
            role: 'assistant',
            content: response.textResponse ?? '',
            type: ChatMessageType.text,
          ));
        }
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: 'عذراً، حدث خطأ. حاول مرة أخرى.',
          type: ChatMessageType.text,
        ));
        _isLoading = false;
      });
    }
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

  void _useQuickPrompt(String prompt) {
    _controller.text = prompt;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant 🤖'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'بدء محادثة جديدة',
            onPressed: () {
              setState(() {
                _messages.clear();
                _dataSource.resetChat();
                _messages.add(ChatMessage(
                  role: 'assistant',
                  content: '👋 مرحباً! أنا مساعدك العقاري الذكي 🚀\n\n'
                           'اسألني عن:\n'
                           '🏘️ البحث عن عقارات ووحدات\n'
                           '💰 نصائح المبيعات والحسابات\n'
                           '🗣️ كيف ترد على اعتراضات العملاء\n'
                           '📞 سكريبتات المكالمات\n\n'
                           'اكتب سؤالك بالعربي أو English',
                  type: ChatMessageType.text,
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick buttons
          _buildQuickButtons(),

          const Divider(height: 1),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageItem(_messages[index]);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('جاري التفكير...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildQuickButtons() {
    final quickPrompts = [
      '🏘️ عايز فيلا 4 غرف',
      '💰 العميل يقول السعر غالي',
      '🧮 احسب عمولة 3%',
      '🎯 ازاي أقفل الصفقة؟',
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickPrompts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(
                quickPrompts[index],
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () => _useQuickPrompt(quickPrompts[index]),
              backgroundColor: Colors.blue.shade50,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    if (message.type == ChatMessageType.properties && message.units != null) {
      // Property message with cards
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text message
          _buildMessageBubble(message.content, false),
          const SizedBox(height: 12),
          // Property cards
          ...message.units!.map((unit) => _buildPropertyCard(unit)),
        ],
      );
    } else {
      // Regular text message
      return _buildMessageBubble(message.content, message.role == 'user');
    }
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Unit unit) {
    final price = unit.discountedPrice ?? unit.totalPrice ?? unit.normalPrice ?? unit.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UnitDetailScreen(
                unit: unit,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property type and location
              Row(
                children: [
                  Icon(Icons.home, color: AppColors.mainColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${unit.usageType ?? unit.unitType ?? 'Unit'} - ${unit.compoundName ?? 'Location'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Details
              Row(
                children: [
                  if (unit.bedrooms != '0')
                    _buildPropertyDetail(Icons.bed, '${unit.bedrooms} غرف'),
                  const SizedBox(width: 16),
                  if (unit.bathrooms != '0')
                    _buildPropertyDetail(Icons.bathroom, '${unit.bathrooms} حمام'),
                  const SizedBox(width: 16),
                  if (unit.area != '0')
                    _buildPropertyDetail(Icons.square_foot, '${unit.area}م²'),
                ],
              ),
              const SizedBox(height: 8),

              // Price
              Text(
                _formatPrice(price),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainColor,
                ),
              ),

              // Company
              if (unit.companyName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    unit.companyName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }

  String _formatPrice(String? price) {
    if (price == null || price.isEmpty || price == '0') return 'اتصل للسعر';
    try {
      final numPrice = double.parse(price);
      if (numPrice >= 1000000) {
        return '${(numPrice / 1000000).toStringAsFixed(2)} مليون ج.م';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)} ألف ج.م';
      }
      return '${numPrice.toStringAsFixed(0)} ج.م';
    } catch (e) {
      return price;
    }
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'اكتب سؤالك...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              color: _isLoading ? Colors.grey : Colors.blue,
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

enum ChatMessageType {
  text,
  properties,
}

class ChatMessage {
  final String role;
  final String content;
  final ChatMessageType type;
  final List<Unit>? units;

  ChatMessage({
    required this.role,
    required this.content,
    required this.type,
    this.units,
  });
}
