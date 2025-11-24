import 'lib/feature/sales_assistant/data/unified_ai_data_source.dart';

void main() async {
  print('🧪 Testing UnifiedAIDataSource...\n');

  try {
    final dataSource = UnifiedAIDataSource();

    // Test 1: Sales Advice
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('TEST 1: Sales Advice (اعطني نصائح)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    final response1 = await dataSource.sendMessage('اعطني نصائح للبيع');

    print('\n✅ Response Type: ${response1.type}');
    print('✅ Text Response: ${response1.textResponse}');
    print('✅ Units: ${response1.units?.length ?? 0}');

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('Stack trace: $stackTrace');
  }
}
