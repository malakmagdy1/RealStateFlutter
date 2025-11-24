# دليل تكامل مساعد المبيعات مع تطبيقك
# Sales Assistant Integration Guide

## 📋 الخطوات المطلوبة / Required Steps

### الخطوة 1️⃣: إضافة الملفات الجديدة
### Step 1: Add New Files

```
lib/
└── feature/
    └── sales_assistant/           ← مجلد جديد / New folder
        ├── data/
        │   └── sales_assistant_remote_data_source.dart
        ├── domain/
        │   └── sales_assistant_prompt.dart
        └── presentation/
            └── screen/
                └── sales_assistant_screen.dart
```

---

### الخطوة 2️⃣: تحديث Config
### Step 2: Update Config

في ملف `lib/feature/ai_chat/domain/config.dart`:

```dart
class AIConfig {
  // الموجود حالياً / Existing
  static const String geminiApiKey = 'AIzaSyDAAktGvB3W6MTsoJQ1uT08NVB0_O48_7Q';
  static const String geminiModel = 'gemini-2.0-flash';
  
  // جديد للـ Sales Assistant / New for Sales Assistant
  static const String salesAssistantModel = 'gemini-2.0-flash';
}
```

---

### الخطوة 3️⃣: إنشاء Data Source
### Step 3: Create Data Source

انسخ الملف `sales_assistant_remote_data_source.dart` إلى:
```
lib/feature/sales_assistant/data/
```

أو اعمل الكود يدوياً:

```dart
import 'package:google_generative_ai/google_generative_ai.dart';
import '../domain/config.dart'; // إذا عايز تستخدم AIConfig

class SalesAssistantRemoteDataSource {
  late GenerativeModel _salesModel;
  late ChatSession _chatSession;

  SalesAssistantRemoteDataSource() {
    _salesModel = GenerativeModel(
      model: AIConfig.salesAssistantModel,
      apiKey: AIConfig.geminiApiKey,
      systemInstruction: Content.system(_salesAssistantSystemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 500,
      ),
    );
    _chatSession = _salesModel.startChat();
  }

  Future<String> getSalesAdvice(String userMessage) async {
    try {
      final response = await _chatSession.sendMessage(
        Content.text(userMessage),
      );
      return response.text ?? 'عذراً، حدث خطأ.';
    } catch (e) {
      return 'عذراً، حدث خطأ في الاتصال.';
    }
  }

  void resetChat() {
    _chatSession = _salesModel.startChat();
  }

  static const String _salesAssistantSystemPrompt = '''
  [نسخ الـ System Prompt من الملف السابق]
  ''';
}
```

---

### الخطوة 4️⃣: إنشاء الشاشة
### Step 4: Create Screen

انشئ ملف `sales_assistant_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../data/sales_assistant_remote_data_source.dart';

class SalesAssistantScreen extends StatefulWidget {
  const SalesAssistantScreen({Key? key}) : super(key: key);

  @override
  State<SalesAssistantScreen> createState() => _SalesAssistantScreenState();
}

class _SalesAssistantScreenState extends State<SalesAssistantScreen> {
  late SalesAssistantRemoteDataSource _dataSource;
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataSource = SalesAssistantRemoteDataSource();
    
    // رسالة ترحيبية / Welcome message
    _messages.add(ChatMessage(
      role: 'assistant',
      content: '👋 مرحباً! أنا مساعدك للمبيعات 🚀\n\n'
               'اسألني بسرعة عن:\n'
               '💰 الأسعار والحسابات\n'
               '🗣️ كيف ترد على عميل\n'
               '📞 سكريبت مكالمة\n'
               '⚖️ القوانين\n\n'
               'اكتب سؤالك بالعربي أو English',
    ));
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: userMessage));
      _isLoading = true;
    });
    _controller.clear();

    final response = await _dataSource.getSalesAdvice(userMessage);

    setState(() {
      _messages.add(ChatMessage(role: 'assistant', content: response));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مساعد المبيعات 🚀'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _dataSource.resetChat();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick buttons
          _buildQuickButtons(),
          
          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          
          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildQuickButtons() {
    final quickPrompts = [
      'العميل يقول السعر غالي',
      'احسب عمولة 3% على 2 مليون',
      'عميل زعلان من التأخير',
      'ازاي أقفل الصفقة دلوقتي؟',
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickPrompts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(quickPrompts[index]),
              onPressed: () {
                _controller.text = quickPrompts[index];
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
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
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
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
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: Colors.blue,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});
}
```

---

### الخطوة 5️⃣: إضافة Route
### Step 5: Add Route

في ملف الـ routing الرئيسي (مثلاً `main.dart` أو `app_router.dart`):

```dart
// إضافة import
import 'package:your_app/feature/sales_assistant/presentation/screen/sales_assistant_screen.dart';

// إضافة route
'/sales-assistant': (context) => const SalesAssistantScreen(),
```

---

### الخطوة 6️⃣: إضافة زر في القائمة
### Step 6: Add Button in Menu

في أي مكان تحب (مثلاً الـ Home أو Drawer):

```dart
ListTile(
  leading: const Icon(Icons.support_agent),
  title: const Text('مساعد المبيعات'),
  subtitle: const Text('احصل على نصائح سريعة'),
  onTap: () {
    Navigator.pushNamed(context, '/sales-assistant');
  },
),
```

أو كـ FloatingActionButton:

```dart
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SalesAssistantScreen(),
      ),
    );
  },
  child: const Icon(Icons.support_agent),
  tooltip: 'مساعد المبيعات',
)
```

---

## ✅ اختبار التكامل / Testing Integration

### اختبار 1: الحسابات
```
السؤال: احسب عمولة 2.5% على 3 مليون جنيه
التوقع: رد سريع بالحساب
```

### اختبار 2: الردود الجاهزة
```
السؤال: العميل بيقول السعر غالي أوي
التوقع: جملة جاهزة للرد فوراً
```

### اختبار 3: اللغة
```
السؤال بالعربي: كيف أقنع العميل؟
التوقع: رد بالعربي فقط

السؤال بالإنجليزي: How to close the deal?
التوقع: رد بالإنجليزي فقط
```

---

## 🎯 الفرق بين الـ AI الموجود والجديد

| الميزة | AI الموجود (Property Search) | AI الجديد (Sales Assistant) |
|--------|------------------------------|------------------------------|
| الهدف | البحث عن وحدات | مساعدة البائع في المكالمة |
| الردود | طويلة ومفصلة | قصيرة وسريعة (2-4 جمل) |
| الاستخدام | للعميل يبحث | للبائع أثناء البيع |
| البيانات | من Database | نصائح عامة + حسابات |
| System Prompt | Property search focused | Sales training focused |

---

## 🚀 خطوات إضافية (اختيارية)

### 1. دمج مع الـ Search API:
```dart
// إذا عايز الـ Sales Assistant يستخدم بيانات حقيقية:
Future<String> getSalesAdviceWithData(String userMessage) async {
  // 1. جيب بيانات من Database
  final units = await _searchRepository.search(query: 'villa', type: 'unit');
  
  // 2. أضف البيانات للـ prompt
  final enrichedMessage = '''
$userMessage

Available Units in Database:
${units.map((u) => '- ${u.type}: ${u.price} EGP').join('\n')}
''';
  
  // 3. أرسل للـ AI
  return await getSalesAdvice(enrichedMessage);
}
```

### 2. حفظ تاريخ المحادثات:
```dart
// استخدم SharedPreferences أو Database محلي
// لحفظ المحادثات المهمة
```

---

## 📝 ملاحظات مهمة

1. ✅ الـ API Key موجود بالفعل - مش محتاج تغيير
2. ✅ الـ Model نفسه (gemini-2.0-flash) - مجاني
3. ✅ مافيش تكلفة إضافية
4. ✅ شغال offline? لأ، محتاج إنترنت
5. ✅ سريع جداً - response في 1-2 ثانية

---

## 🆘 المساعدة

إذا واجهت مشكلة:
1. تأكد أن الـ API Key شغال
2. تأكد من الـ imports صح
3. شوف الـ console للـ errors
4. جرب الـ examples المرفقة

تمام! 🎉