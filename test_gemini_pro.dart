import 'package:google_generative_ai/google_generative_ai.dart';

/// Test gemini-pro model (Gemini 1.0)
void main() async {
  print('🧪 Testing gemini-pro (Gemini 1.0)...\n');

  final apiKey = 'AIzaSyDPqe54op4APQDIANK4UZriK--DCvfpuPA';

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Test: gemini-pro');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  try {
    final model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1200,
      ),
    );

    final response = await model.generateContent([
      Content.text('مرحباً، أنا وسيط عقاري، كيف أتعامل مع عميل جديد؟'),
    ]);

    print('✅ SUCCESS!');
    print('Response: ${response.text}');
  } catch (e) {
    print('❌ FAILED: $e');
  }

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🎯 Testing Complete!');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}
