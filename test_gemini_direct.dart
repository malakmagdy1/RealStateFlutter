import 'package:google_generative_ai/google_generative_ai.dart';

/// Test Gemini API directly
void main() async {
  print('🧪 Testing Gemini API...\n');

  final apiKey = 'AIzaSyDPqe54op4APQDIANK4UZriK--DCvfpuPA';

  // Test 1: gemini-2.0-flash-exp
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Test 1: gemini-2.0-flash-exp');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  try {
    final model1 = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: apiKey,
    );
    final response1 = await model1.generateContent([Content.text('Hello')]);
    print('✅ SUCCESS: ${response1.text?.substring(0, 50)}...');
  } catch (e) {
    print('❌ FAILED: $e');
  }

  print('\n');

  // Test 2: gemini-1.5-flash
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Test 2: gemini-1.5-flash');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  try {
    final model2 = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final response2 = await model2.generateContent([Content.text('Hello')]);
    print('✅ SUCCESS: ${response2.text?.substring(0, 50)}...');
  } catch (e) {
    print('❌ FAILED: $e');
  }

  print('\n');

  // Test 3: gemini-1.5-pro
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Test 3: gemini-1.5-pro');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  try {
    final model3 = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);
    final response3 = await model3.generateContent([Content.text('Hello')]);
    print('✅ SUCCESS: ${response3.text?.substring(0, 50)}...');
  } catch (e) {
    print('❌ FAILED: $e');
  }

  print('\n');

  // Test 4: With system instruction (like our app)
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Test 4: gemini-1.5-flash with system instruction');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  try {
    final model4 = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1200,
      ),
      systemInstruction: Content.system(
        'You are a helpful real estate broker named Abu Khalid.',
      ),
    );
    final chat = model4.startChat();
    final response4 = await chat.sendMessage(
      Content.text('إزاي أتعامل مع عميل جديد؟'),
    );
    print('✅ SUCCESS: ${response4.text?.substring(0, 100)}...');
  } catch (e) {
    print('❌ FAILED: $e');
  }

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🎯 Testing Complete!');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}
