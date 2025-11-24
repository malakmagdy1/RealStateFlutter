import 'package:flutter/material.dart';
import '../../data/sales_assistant_remote_data_source.dart';

/// SIMPLE VERSION - ONLY Algorithm 2 (Sales Advice)
/// Use this to test if Algorithm 2 works alone
class SalesAssistantScreenOLD extends StatefulWidget {
  const SalesAssistantScreenOLD({Key? key}) : super(key: key);

  @override
  State<SalesAssistantScreenOLD> createState() => _SalesAssistantScreenOLDState();
}

class _SalesAssistantScreenOLDState extends State<SalesAssistantScreenOLD> {
  late SalesAssistantRemoteDataSource _dataSource;
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataSource = SalesAssistantRemoteDataSource();

    print('[OLD SCREEN] ✅ Using SalesAssistantRemoteDataSource (Algorithm 2 ONLY)');

    _messages.add(ChatMessage(
      role: 'assistant',
      content: '👋 مرحباً! أنا مساعد المبيعات (Algorithm 2 فقط)\n\n'
               'جرب: اعطني نصائح',
    ));
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;

    final userMessage = _controller.text.trim();
    print('[OLD SCREEN] 📤 User message: $userMessage');

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: userMessage));
      _isLoading = true;
    });
    _controller.clear();

    try {
      print('[OLD SCREEN] 🤖 Calling getSalesAdvice...');
      final response = await _dataSource.getSalesAdvice(userMessage);

      print('[OLD SCREEN] ✅ Got response: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');

      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: response));
        _isLoading = false;
      });
    } catch (e) {
      print('[OLD SCREEN] ❌ ERROR: $e');
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: 'خطأ: $e',
        ));
        _isLoading = false;
      });
    }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('TEST: Algorithm 2 Only'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Warning banner
          Container(
            color: Colors.orange.shade100,
            padding: EdgeInsets.all(8),
            child: Text(
              '⚠️ TEST MODE: Algorithm 2 (Sales Advice) فقط',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.role == 'user';
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
                      msg.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          // Input
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'اكتب: اعطني نصائح',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
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

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});
}
