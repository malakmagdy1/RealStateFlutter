import 'package:google_generative_ai/google_generative_ai.dart';

// ========================================
// Sales Assistant Remote Data Source
// ========================================

class SalesAssistantRemoteDataSource {
  late GenerativeModel _salesModel;
  late ChatSession _chatSession;

  SalesAssistantRemoteDataSource({required String apiKey}) {
    _salesModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_salesAssistantSystemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 500, // Short responses for quick calls
      ),
    );
    _chatSession = _salesModel.startChat();
  }

  /// Send a message and get sales advice
  Future<String> getSalesAdvice(String userMessage) async {
    try {
      final response = await _chatSession.sendMessage(
        Content.text(userMessage),
      );
      return response.text ?? 'عذراً، حدث خطأ. حاول مرة تانية.';
    } catch (e) {
      print('Error in getSalesAdvice: $e');
      return 'عذراً، حدث خطأ في الاتصال.';
    }
  }

  /// Reset chat session (for new conversation)
  void resetChat() {
    _chatSession = _salesModel.startChat();
  }

  /// System prompt for sales assistant
  static const String _salesAssistantSystemPrompt = '''
أنت مساعد ذكي للمبيعات العقارية في مصر. هدفك مساعدة البائع أثناء المكالمة مع العميل.

You are a smart assistant for real estate sales in Egypt. Your goal is to help the salesperson during phone calls with clients.

**CRITICAL LANGUAGE RULE:**
- إذا سأل المستخدم بالعربي فقط → رد بالعربي فقط
- If user asks in English only → Respond in English only  
- DO NOT mix languages or respond in both unless specifically asked
- Detect the language from the user's question and respond ONLY in that language

**YOUR EXPERTISE:**

1. **حسابات سريعة / Quick Calculations:**
   - حساب الأسعار والعمولات
   - عروض بدون خسارة
   - خطط التقسيط

2. **ردود جاهزة / Ready Responses:**
   - كيف ترد على الاعتراضات
   - سكريبتات مكالمات قصيرة
   - جمل إقناع سريعة

3. **حلول سريعة / Quick Solutions:**
   - التعامل مع عميل غاضب
   - عميل يقول السعر غالي
   - عميل متردد

4. **قوانين مصرية / Egyptian Laws:**
   - عقود البيع
   - الضرائب
   - حقوق المشتري والبائع

**RESPONSE STYLE - مهم جداً:**

✅ إجابات قصيرة ومباشرة (2-4 جمل فقط)
✅ Short and direct answers (2-4 sentences only)
✅ جمل جاهزة للاستخدام فوراً
✅ Ready-to-use phrases immediately
✅ بدون شرح طويل
✅ No long explanations
✅ مناسب للمكالمات السريعة
✅ Suitable for quick phone calls

**EXAMPLES:**

❌ Wrong (طويل جداً):
"التفاوض مهارة معقدة تحتاج إلى فهم عميق لعلم النفس والسلوك البشري. هناك عدة تقنيات يمكن استخدامها..."

✅ Correct (قصير ومباشر):
"قل له: 'أفهم قلقك من السعر. خليني أوريك المميزات اللي هتخلي السعر ده معقول جداً.' ثم اذكر 3 مميزات بسرعة."

المستخدم لديه قاعدة بيانات تحتوي على: شركات، كمبوندات، وحدات.
User has database with: companies, compounds, units.
''';
}

// ========================================
// Example Integration with Existing Code
// ========================================

/// Add this to your existing chat repository or create a new one
/// 
/// Example usage in a screen:
/// 
/// ```dart
/// class SalesAssistantScreen extends StatefulWidget {
///   @override
///   _SalesAssistantScreenState createState() => _SalesAssistantScreenState();
/// }
/// 
/// class _SalesAssistantScreenState extends State<SalesAssistantScreen> {
///   late SalesAssistantRemoteDataSource _dataSource;
///   List<Map<String, String>> messages = [];
///   TextEditingController _controller = TextEditingController();
///   
///   @override
///   void initState() {
///     super.initState();
///     _dataSource = SalesAssistantRemoteDataSource(
///       apiKey: 'AIzaSyDAAktGvB3W6MTsoJQ1uT08NVB0_O48_7Q',
///     );
///     
///     // Initial message
///     messages.add({
///       'role': 'assistant',
///       'content': '👋 مرحباً! أنا مساعدك للمبيعات 🚀\n\n'
///                  'اسألني بسرعة عن:\n'
///                  '💰 الأسعار والحسابات\n'
///                  '🗣️ كيف ترد على عميل\n'
///                  '📞 سكريبت مكالمة\n'
///                  '⚖️ القوانين\n\n'
///                  'اكتب سؤالك بالعربي أو English'
///     });
///   }
///   
///   Future<void> _sendMessage() async {
///     if (_controller.text.isEmpty) return;
///     
///     final userMessage = _controller.text;
///     setState(() {
///       messages.add({'role': 'user', 'content': userMessage});
///     });
///     _controller.clear();
///     
///     final response = await _dataSource.getSalesAdvice(userMessage);
///     
///     setState(() {
///       messages.add({'role': 'assistant', 'content': response});
///     });
///   }
///   
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: Text('مساعد المبيعات'),
///       ),
///       body: Column(
///         children: [
///           Expanded(
///             child: ListView.builder(
///               itemCount: messages.length,
///               itemBuilder: (context, index) {
///                 final message = messages[index];
///                 final isUser = message['role'] == 'user';
///                 return Align(
///                   alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
///                   child: Container(
///                     margin: EdgeInsets.all(8),
///                     padding: EdgeInsets.all(12),
///                     decoration: BoxDecoration(
///                       color: isUser ? Colors.blue : Colors.grey[300],
///                       borderRadius: BorderRadius.circular(12),
///                     ),
///                     child: Text(
///                       message['content'] ?? '',
///                       style: TextStyle(
///                         color: isUser ? Colors.white : Colors.black,
///                       ),
///                     ),
///                   ),
///                 );
///               },
///             ),
///           ),
///           Padding(
///             padding: EdgeInsets.all(8),
///             child: Row(
///               children: [
///                 Expanded(
///                   child: TextField(
///                     controller: _controller,
///                     decoration: InputDecoration(
///                       hintText: 'اكتب سؤالك...',
///                       border: OutlineInputBorder(),
///                     ),
///                   ),
///                 ),
///                 SizedBox(width: 8),
///                 IconButton(
///                   icon: Icon(Icons.send),
///                   onPressed: _sendMessage,
///                 ),
///               ],
///             ),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```