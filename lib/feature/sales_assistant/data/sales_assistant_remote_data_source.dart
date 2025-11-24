import 'package:google_generative_ai/google_generative_ai.dart';
import '../../ai_chat/domain/config.dart';

// ========================================
// Sales Assistant Remote Data Source
// ========================================

class SalesAssistantRemoteDataSource {
  late GenerativeModel _salesModel;
  late ChatSession _chatSession;

  SalesAssistantRemoteDataSource() {
    _salesModel = GenerativeModel(
      model: AppConfig.salesAssistantModel,
      apiKey: AppConfig.geminiApiKey,
      systemInstruction: Content.system(_salesAssistantSystemPrompt),
      generationConfig: GenerationConfig(
        temperature: AppConfig.temperature,
        topK: AppConfig.topK,
        topP: AppConfig.topP,
        maxOutputTokens: AppConfig.salesMaxOutputTokens,
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
