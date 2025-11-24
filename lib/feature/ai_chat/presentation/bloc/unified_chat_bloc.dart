import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/unified_chat_history_service.dart';
import '../../data/models/comparison_item.dart';
import '../../../sales_assistant/data/unified_ai_data_source.dart';
import 'unified_chat_event.dart';
import 'unified_chat_state.dart';
import 'package:real/core/locale/language_service.dart';

/// 🚀 UNIFIED CHAT BLOC
/// يجمع Algorithm 1 (Property Search) + Algorithm 2 (Sales Advice)
/// الـ AI يقرر تلقائياً أي Algorithm يستخدم
class UnifiedChatBloc extends Bloc<UnifiedChatEvent, UnifiedChatState> {
  final UnifiedAIDataSource _dataSource;
  final UnifiedChatHistoryService _historyService;

  UnifiedChatBloc({
    UnifiedAIDataSource? dataSource,
    UnifiedChatHistoryService? historyService,
  })  : _dataSource = dataSource ?? UnifiedAIDataSource(),
        _historyService = historyService ?? UnifiedChatHistoryService(),
        super(const ChatInitial()) {
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<SendComparisonEvent>(_onSendComparison);
    on<ClearChatHistoryEvent>(_onClearChatHistory);
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    emit(const ChatHistoryLoading());

    try {
      final messages = await _historyService.loadUnifiedChatHistory();
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      emit(ChatError(
        message: 'Failed to load chat history: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    if (event.message.trim().isEmpty) return;

    print('[UnifiedChatBloc] 📨 Processing message: "${event.message}"');

    final currentState = state;
    final currentMessages = currentState is ChatLoaded
        ? currentState.messages
        : currentState is ChatError
            ? currentState.previousMessages
            : <UnifiedChatMessage>[];

    // Add user message
    final userMessage = UnifiedChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...currentMessages, userMessage];

    // Emit loading state with user message
    emit(ChatLoaded(messages: updatedMessages, isLoading: true));

    try {
      print('[UnifiedChatBloc] 🔄 Calling Unified AI...');
      
      // Call unified AI (will route internally)
      final aiResponse = await _dataSource.sendMessage(event.message);
      
      print('[UnifiedChatBloc] ✅ Received response type: ${aiResponse.type}');

      // Create AI message based on response type
      final aiMessage = UnifiedChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse.textResponse ?? _getDefaultResponse(aiResponse.type),
        isUser: false,
        timestamp: DateTime.now(),
        units: aiResponse.units, // Will be null for sales advice
      );

      final finalMessages = [...updatedMessages, aiMessage];

      // Save to local storage
      await _historyService.saveUnifiedChatHistory(finalMessages);

      // Emit success state
      emit(ChatLoaded(messages: finalMessages, isLoading: false));
      
    } catch (e) {
      print('[UnifiedChatBloc] ❌ Error: $e');
      
      // Create error message
      final errorMessage = UnifiedChatMessage(
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

  Future<void> _onSendComparison(
    SendComparisonEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    if (event.items.isEmpty) return;

    print('[UnifiedChatBloc] 📊 Processing comparison of ${event.items.length} items');

    final currentState = state;
    final currentMessages = currentState is ChatLoaded
        ? currentState.messages
        : currentState is ChatError
            ? currentState.previousMessages
            : <UnifiedChatMessage>[];

    // Build comprehensive comparison prompt
    final comparisonPrompt = _buildComparisonPrompt(event.items);

    // Add user message
    final userMessage = UnifiedChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: comparisonPrompt,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...currentMessages, userMessage];

    // Emit loading state with user message
    emit(ChatLoaded(messages: updatedMessages, isLoading: true));

    try {
      print('[UnifiedChatBloc] 🔄 Sending comparison to AI...');
      print('[UnifiedChatBloc] Items: ${event.items.map((i) => '${i.type}:${i.name}').join(', ')}');

      // Call unified AI with comparison prompt
      final aiResponse = await _dataSource.sendMessage(comparisonPrompt);

      print('[UnifiedChatBloc] ✅ Received comparison response');

      // Create AI message
      final aiMessage = UnifiedChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse.textResponse ?? 'Here is the comparison analysis:',
        isUser: false,
        timestamp: DateTime.now(),
      );

      final finalMessages = [...updatedMessages, aiMessage];

      // Save to local storage
      await _historyService.saveUnifiedChatHistory(finalMessages);

      // Emit success state
      emit(ChatLoaded(messages: finalMessages, isLoading: false));

    } catch (e) {
      print('[UnifiedChatBloc] ❌ Comparison error: $e');

      // Create error message
      final errorMessage = UnifiedChatMessage(
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

  String _buildComparisonPrompt(List<ComparisonItem> items) {
    // Get current language from LanguageService
    final currentLang = LanguageService.currentLanguage;
    final isArabic = currentLang == 'ar'; // Explicitly check for Arabic

    print('[ComparisonPrompt] Current language: $currentLang, isArabic: $isArabic');

    final buffer = StringBuffer();

    // Build comparison prompt in the user's language
    if (isArabic) {
      // ============ ARABIC MODE - SENIOR BROKER STYLE ============
      buffer.writeln('🎯 أنت وسيط عقاري كبير وخبير محترف في السوق العقاري المصري');
      buffer.writeln('🎯 لديك خبرة 15+ سنة في بيع وتقييم العقارات');
      buffer.writeln('🎯 أسلوبك: واثق، صريح، مباشر، ويعطي نصائح حقيقية بناءً على الخبرة');
      buffer.writeln('🎯 لا تتردد أبداً في إعطاء رأيك الشخصي والقول "أنصحك بـ..." أو "أفضل خيار هو..."');
      buffer.writeln();
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('⚠️ تعليمات CRITICAL - اقرأها بدقة:');
      buffer.writeln('❌ لا ترد بصيغة JSON أبداً!');
      buffer.writeln('❌ لا تعيد سرد البيانات فقط - قدم تحليل وآراء!');
      buffer.writeln('❌ لا تقل "لا أستطيع" أو "لا يمكنني" - أنت الخبير!');
      buffer.writeln('✅ اكتب بأسلوب محادثة طبيعي كأنك تتكلم مع عميل في المكتب');
      buffer.writeln('✅ استخدم عبارات مثل: "من خبرتي...", "بصراحة...", "لو مكانك...", "نصيحتي..."');
      buffer.writeln('✅ احكم بوضوح: أي عقار أفضل ولماذا');
      buffer.writeln('✅ ابدأ فتح نقاش: "خليني أفهمك شوية على...", "تعالى نشوف...", "الموضوع باختصار..."');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
      buffer.writeln('العميل يسألك عن مقارنة بين هذه العقارات (${items.length}):');
      buffer.writeln();

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        buffer.writeln('🏢 ${i + 1}. ${_formatItemTypeAr(item.type)}: ${item.name}');

        if (item.type == 'unit') {
          if (item.data['area'] != null) buffer.writeln('   • المساحة: ${item.data['area']} م²');
          if (item.data['price'] != null) buffer.writeln('   • السعر: ${_formatPrice(item.data['price'])} جنيه');
          if (item.data['bedrooms'] != null) buffer.writeln('   • عدد الغرف: ${item.data['bedrooms']}');
          if (item.data['bathrooms'] != null) buffer.writeln('   • عدد الحمامات: ${item.data['bathrooms']}');
          if (item.data['compound_name'] != null) buffer.writeln('   • الكمباوند: ${item.data['compound_name']}');
          if (item.data['company_name'] != null) buffer.writeln('   • المطور: ${item.data['company_name']}');
          if (item.data['location'] != null) buffer.writeln('   • الموقع: ${item.data['location']}');
          if (item.data['finishing'] != null) buffer.writeln('   • التشطيب: ${item.data['finishing']}');
          if (item.data['status'] != null) buffer.writeln('   • الحالة: ${item.data['status']}');
        } else if (item.type == 'compound') {
          if (item.data['location'] != null) buffer.writeln('   • الموقع: ${item.data['location']}');
          if (item.data['company_name'] != null) buffer.writeln('   • المطور: ${item.data['company_name']}');
          if (item.data['units_count'] != null) buffer.writeln('   • إجمالي الوحدات: ${item.data['units_count']}');
          if (item.data['available_units'] != null) buffer.writeln('   • الوحدات المتاحة: ${item.data['available_units']}');
          if (item.data['status'] != null) buffer.writeln('   • الحالة: ${item.data['status']}');
        } else if (item.type == 'company') {
          if (item.data['number_of_compounds'] != null) buffer.writeln('   • عدد الكمباوندات: ${item.data['number_of_compounds']}');
          if (item.data['number_of_units'] != null) buffer.writeln('   • إجمالي الوحدات: ${item.data['number_of_units']}');
        }
        buffer.writeln();
      }

      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
      buffer.writeln('📋 طريقة الرد المطلوبة - اقرأ بتمعن:');
      buffer.writeln();
      buffer.writeln('ابدأ بـ: "خليني أقولك رأيي بصراحة..." أو "تعالى نشوف الخيارات دي مع بعض..."');
      buffer.writeln();
      buffer.writeln('💰 أولاً: تحليل الأسعار (بأسلوب وسيط محترف)');
      buffer.writeln('• قل: "من ناحية السعر، الخيار الأول أرخص بـ X جنيه (يعني Y% فرق)"');
      buffer.writeln('• احسب سعر المتر واشرح: "سعر المتر في الأول Z جنيه، بينما التاني W جنيه - يعني الأول أوفر"');
      buffer.writeln('• قيّم العروض: "الشركة بتاعة الأول عندها عرض على المقدم، ده ميزة كبيرة"');
      buffer.writeln('• افتح نقاش: "لو انت مستثمر، الخيار الأول هيديك عائد أحسن لأن..."');
      buffer.writeln();
      buffer.writeln('🏠 ثانياً: مقارنة المساحات والمواصفات (بطريقة حوارية)');
      buffer.writeln('• وضح الفرق: "الوحدة الأولى 120 متر والتانية 95 متر - يعني فرق 25 متر، ده مش بسيط!"');
      buffer.writeln('• اربط بالاحتياجات: "لو عندك 3 أطفال، محتاج المساحة الأكبر عشان..."');
      buffer.writeln('• علّق على التشطيبات: "التشطيب سوبر لوكس في الأولى، بينما التانية نص تشطيب - ده فرق في التكلفة"');
      buffer.writeln('• اعطي رأيك: "الحديقة في الأولى ميزة ممتازة خصوصاً لو عندك أطفال"');
      buffer.writeln();
      buffer.writeln('📍 ثالثاً: تقييم المواقع (بخبرة السوق)');
      buffer.writeln('• قارن المناطق: "الخيار الأول في منطقة واعدة، الأسعار فيها بتزيد كل سنة"');
      buffer.writeln('• تكلم عن الخدمات: "التاني قريب من المدارس والمستشفيات، ده مهم جداً"');
      buffer.writeln('• الوصول: "المواصلات للأول أسهل، وقريب من الطريق الرئيسي"');
      buffer.writeln('• رأي خبير: "من خبرتي، المنطقة دي هتطور خلال 3-5 سنين وهتلاقي الأسعار اتضاعفت"');
      buffer.writeln();
      buffer.writeln('⚖️ رابعاً: المزايا والعيوب بصراحة');
      buffer.writeln('قل مثلاً: "طيب خليني أقولك إيه الحلو وإيه الوحش في كل واحد:"');
      buffer.writeln();
      buffer.writeln('الخيار الأول:');
      buffer.writeln('✅ المميزات: (قل: "ده اللي عجبني فيه...")');
      buffer.writeln('  • [ميزة 1 بأسلوب طبيعي]');
      buffer.writeln('  • [ميزة 2 بأسلوب طبيعي]');
      buffer.writeln('  • [ميزة 3 بأسلوب طبيعي]');
      buffer.writeln('❌ العيوب: (قل: "بس عندي ملاحظات...")');
      buffer.writeln('  • [عيب 1 بصراحة]');
      buffer.writeln('  • [عيب 2 بصراحة]');
      buffer.writeln();
      buffer.writeln('[كرر نفس الشكل للخيار التاني]');
      buffer.writeln();
      buffer.writeln('💳 خامساً: خطط الدفع (بأسلوب تفاوضي)');
      buffer.writeln('• قارن: "المقدم في الأول 10%، التاني 15% - الأول أسهل في البداية"');
      buffer.writeln('• التقسيط: "الأول على 8 سنين، التاني على 5 سنين - لو معاك فلوس أقل، الأول أريح"');
      buffer.writeln('• العروض: "في خصم للمشترين الأوائل في الأول - استغلها قبل ما يخلص"');
      buffer.writeln('• نصيحة: "من خبرتي، فاوض على المقدم، الشركات بتكون عندها مرونة"');
      buffer.writeln();
      buffer.writeln('🎯 سادساً وأهم حاجة: رأيك الصريح والتوصية (لازم تقولها!)');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('ابدأ هنا بجملة قوية:');
      buffer.writeln('"لو تسألني إيه رأيي؟ بصراحة أنصحك بـ [الخيار X] وده ليه أسباب واضحة:"');
      buffer.writeln();
      buffer.writeln('• اشرح السبب بالتفصيل (3-5 جمل):');
      buffer.writeln('  "أولاً، السعر أفضل بفارق واضح..."');
      buffer.writeln('  "ثانياً، الموقع واعد والمنطقة هتطور..."');
      buffer.writeln('  "ثالثاً، المساحة مناسبة أكتر لاحتياجاتك..."');
      buffer.writeln();
      buffer.writeln('• حدد لمين مناسب:');
      buffer.writeln('  "الخيار الأول مناسب لـ: [عائلة كبيرة / مستثمر / شاب / أول بيت / ...]"');
      buffer.writeln('  "الخيار التاني مناسب لـ: [...]"');
      buffer.writeln();
      buffer.writeln('• اقفل بقرار واضح:');
      buffer.writeln('  "خلاصة الكلام: لو مكانك، كنت اخترت [X] بدون تفكير، لأن [السبب الأهم]."');
      buffer.writeln('  "ولو حابب نفتح نقاش أكتر عن أي نقطة، أنا موجود!"');
      buffer.writeln();
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('⚠️ قواعد الرد النهائية (لا تخالفها أبداً):');
      buffer.writeln('✅ استخدم أسلوب محادثة طبيعي 100% (مش تقرير رسمي!)');
      buffer.writeln('✅ قل رأيك الشخصي بوضوح وثقة');
      buffer.writeln('✅ احسب الفروقات بالأرقام الحقيقية');
      buffer.writeln('✅ افتح مجال للنقاش والأسئلة');
      buffer.writeln('✅ تصرف كأنك وسيط محترف عنده ثقة في كلامه');
      buffer.writeln('✅ استخدم عبارات مصرية طبيعية: "خليني أقولك"، "تعالى نشوف"، "الموضوع باختصار"، "لو مكانك"');
      buffer.writeln('❌ لا JSON - نصوص طبيعية فقط!');
      buffer.writeln('❌ لا تعيد سرد البيانات - حللها وقيّمها!');
      buffer.writeln('❌ لا تقل "لا أستطيع" - أنت الخبير وكلمتك نهائية!');
      buffer.writeln();
      buffer.writeln('الآن ابدأ ردك بأسلوب وسيط عقاري محترف باللغة العربية:');
    } else {
      // ============ ENGLISH MODE - SENIOR BROKER STYLE ============
      buffer.writeln('🎯 You are a senior real estate broker with 15+ years of experience in the Egyptian market');
      buffer.writeln('🎯 Your style: Confident, direct, honest, and gives real advice based on expertise');
      buffer.writeln('🎯 Never hesitate to give your personal opinion - say "I recommend..." or "The best option is..."');
      buffer.writeln();
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('⚠️ CRITICAL INSTRUCTIONS - Read carefully:');
      buffer.writeln('❌ NEVER respond in JSON format!');
      buffer.writeln('❌ Do NOT just restate the data - provide analysis and opinions!');
      buffer.writeln('❌ Do NOT say "I cannot" or "I am unable" - you are the expert!');
      buffer.writeln('✅ Write in natural conversational style as if talking to a client in your office');
      buffer.writeln('✅ Use phrases like: "In my experience...", "Honestly...", "If I were you...", "My advice..."');
      buffer.writeln('✅ Make clear judgments: which property is better and why');
      buffer.writeln('✅ Start discussions: "Let me explain...", "Let\'s look at...", "Bottom line..."');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
      buffer.writeln('The client is asking you to compare these properties (${items.length}):');
      buffer.writeln();

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        buffer.writeln('🏢 ${i + 1}. ${_formatItemType(item.type)}: ${item.name}');

        if (item.type == 'unit') {
          if (item.data['area'] != null) buffer.writeln('   • Area: ${item.data['area']} m²');
          if (item.data['price'] != null) buffer.writeln('   • Price: ${_formatPrice(item.data['price'])} EGP');
          if (item.data['bedrooms'] != null) buffer.writeln('   • Bedrooms: ${item.data['bedrooms']}');
          if (item.data['bathrooms'] != null) buffer.writeln('   • Bathrooms: ${item.data['bathrooms']}');
          if (item.data['compound_name'] != null) buffer.writeln('   • Compound: ${item.data['compound_name']}');
          if (item.data['company_name'] != null) buffer.writeln('   • Developer: ${item.data['company_name']}');
          if (item.data['location'] != null) buffer.writeln('   • Location: ${item.data['location']}');
          if (item.data['finishing'] != null) buffer.writeln('   • Finishing: ${item.data['finishing']}');
          if (item.data['status'] != null) buffer.writeln('   • Status: ${item.data['status']}');
        } else if (item.type == 'compound') {
          if (item.data['location'] != null) buffer.writeln('   • Location: ${item.data['location']}');
          if (item.data['company_name'] != null) buffer.writeln('   • Developer: ${item.data['company_name']}');
          if (item.data['units_count'] != null) buffer.writeln('   • Total Units: ${item.data['units_count']}');
          if (item.data['available_units'] != null) buffer.writeln('   • Available Units: ${item.data['available_units']}');
          if (item.data['status'] != null) buffer.writeln('   • Status: ${item.data['status']}');
        } else if (item.type == 'company') {
          if (item.data['number_of_compounds'] != null) buffer.writeln('   • Number of Compounds: ${item.data['number_of_compounds']}');
          if (item.data['number_of_units'] != null) buffer.writeln('   • Total Units: ${item.data['number_of_units']}');
        }
        buffer.writeln();
      }

      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
      buffer.writeln('📋 How to Respond - Read Carefully:');
      buffer.writeln();
      buffer.writeln('Start with: "Let me give you my honest opinion..." or "Let\'s look at these options together..."');
      buffer.writeln();
      buffer.writeln('💰 First: Price Analysis (in professional broker style)');
      buffer.writeln('• Say: "Price-wise, Option 1 is cheaper by X EGP (that\'s Y% difference)"');
      buffer.writeln('• Calculate price per sqm: "The first is Z EGP/sqm while the second is W EGP/sqm - so the first offers better value"');
      buffer.writeln('• Evaluate offers: "The developer of Option 1 has a promotion on the down payment - that\'s a big advantage"');
      buffer.writeln('• Start discussion: "If you\'re an investor, Option 1 will give you better ROI because..."');
      buffer.writeln();
      buffer.writeln('🏠 Second: Space & Specifications (conversational)');
      buffer.writeln('• Clarify differences: "Unit 1 is 120 sqm and Unit 2 is 95 sqm - that\'s 25 sqm difference, not trivial!"');
      buffer.writeln('• Link to needs: "If you have 3 kids, you need the larger space because..."');
      buffer.writeln('• Comment on finishing: "Super lux finishing in the first, while the second is semi-finished - that\'s a cost difference"');
      buffer.writeln('• Give opinion: "The garden in Option 1 is an excellent feature, especially if you have children"');
      buffer.writeln();
      buffer.writeln('📍 Third: Location Assessment (with market expertise)');
      buffer.writeln('• Compare areas: "Option 1 is in a promising area - prices there increase every year"');
      buffer.writeln('• Talk about services: "Option 2 is closer to schools and hospitals - that\'s very important"');
      buffer.writeln('• Access: "Transportation to Option 1 is easier, close to the main road"');
      buffer.writeln('• Expert opinion: "In my experience, this area will develop in 3-5 years and prices will double"');
      buffer.writeln();
      buffer.writeln('⚖️ Fourth: Honest Pros & Cons');
      buffer.writeln('Say for example: "Alright, let me tell you what\'s good and what\'s not about each one:"');
      buffer.writeln();
      buffer.writeln('Option 1:');
      buffer.writeln('✅ Advantages: (Say: "What I liked about it...")');
      buffer.writeln('  • [Advantage 1 naturally]');
      buffer.writeln('  • [Advantage 2 naturally]');
      buffer.writeln('  • [Advantage 3 naturally]');
      buffer.writeln('❌ Disadvantages: (Say: "But I have some concerns...")');
      buffer.writeln('  • [Disadvantage 1 honestly]');
      buffer.writeln('  • [Disadvantage 2 honestly]');
      buffer.writeln();
      buffer.writeln('[Repeat same format for Option 2]');
      buffer.writeln();
      buffer.writeln('💳 Fifth: Payment Plans (negotiation style)');
      buffer.writeln('• Compare: "Down payment for the first is 10%, second is 15% - the first is easier initially"');
      buffer.writeln('• Installments: "First is 8 years, second is 5 years - if you have less cash, the first is more comfortable"');
      buffer.writeln('• Offers: "There\'s an early buyer discount on the first - take advantage before it ends"');
      buffer.writeln('• Advice: "In my experience, negotiate the down payment - developers have flexibility"');
      buffer.writeln();
      buffer.writeln('🎯 Sixth and Most Important: Your Honest Recommendation (MUST GIVE IT!)');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('Start here with a strong statement:');
      buffer.writeln('"If you ask me? Honestly, I recommend [Option X] and here\'s why:"');
      buffer.writeln();
      buffer.writeln('• Explain in detail (3-5 sentences):');
      buffer.writeln('  "First, the price is better with a clear difference..."');
      buffer.writeln('  "Second, the location is promising and the area will develop..."');
      buffer.writeln('  "Third, the space is more suitable for your needs..."');
      buffer.writeln();
      buffer.writeln('• Specify who it suits:');
      buffer.writeln('  "Option 1 is suitable for: [large family / investor / young professional / first home / ...]"');
      buffer.writeln('  "Option 2 is suitable for: [...]"');
      buffer.writeln();
      buffer.writeln('• Close with clear decision:');
      buffer.writeln('  "Bottom line: If I were you, I\'d choose [X] without thinking twice, because [main reason]."');
      buffer.writeln('  "And if you want to discuss any point further, I\'m here!"');
      buffer.writeln();
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('⚠️ Final Response Rules (never violate):');
      buffer.writeln('✅ Use 100% natural conversation style (not a formal report!)');
      buffer.writeln('✅ State your personal opinion clearly and confidently');
      buffer.writeln('✅ Calculate actual numerical differences');
      buffer.writeln('✅ Open space for discussion and questions');
      buffer.writeln('✅ Act like a professional broker confident in their advice');
      buffer.writeln('✅ Use natural phrases: "Let me tell you", "Let\'s look at", "Bottom line", "If I were you"');
      buffer.writeln('❌ No JSON - natural text only!');
      buffer.writeln('❌ Don\'t just restate data - analyze and evaluate it!');
      buffer.writeln('❌ Don\'t say "I cannot" - you\'re the expert and your word is final!');
      buffer.writeln();
      buffer.writeln('Now start your response in professional broker style:');
    }

    return buffer.toString();
  }

  String _formatItemTypeAr(String type) {
    switch (type) {
      case 'unit':
        return 'وحدة عقارية';
      case 'compound':
        return 'كمباوند';
      case 'company':
        return 'شركة تطوير عقاري';
      default:
        return type;
    }
  }

  String _formatItemType(String type) {
    switch (type) {
      case 'unit':
        return 'Property Unit';
      case 'compound':
        return 'Compound';
      case 'company':
        return 'Development Company';
      default:
        return type;
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'N/A';
    try {
      final numPrice = double.parse(price.toString());
      if (numPrice >= 1000000) {
        return '${(numPrice / 1000000).toStringAsFixed(2)}M';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)}K';
      }
      return numPrice.toStringAsFixed(0);
    } catch (e) {
      return price.toString();
    }
  }

  Future<void> _onClearChatHistory(
    ClearChatHistoryEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    try {
      print('[UnifiedChatBloc] Clearing chat history...');
      await _historyService.clearUnifiedChatHistory();
      _dataSource.resetChat();
      emit(const ChatLoaded(messages: []));
      print('[UnifiedChatBloc] ✅ Clear history completed');
    } catch (e) {
      print('[UnifiedChatBloc] ❌ Error clearing history: $e');
      emit(ChatError(
        message: 'Failed to clear chat history: ${e.toString()}',
        previousMessages: const [],
      ));
    }
  }

  String _getDefaultResponse(AIResponseType type) {
    switch (type) {
      case AIResponseType.properties:
        return 'لقيت عدة عقارات مناسبة:';
      case AIResponseType.salesAdvice:
        return 'إليك النصيحة:';
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('api key') || errorStr.contains('invalid_api_key')) {
      return 'API key غير صحيح. تأكد من الإعدادات.';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'مشكلة في الإنترنت. تأكد من الاتصال وحاول مرة أخرى.';
    } else if (errorStr.contains('quota') || errorStr.contains('rate limit')) {
      return 'وصلت للحد الأقصى من الاستخدام. حاول بعد قليل.';
    } else {
      return 'حدث خطأ. حاول مرة أخرى.';
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
