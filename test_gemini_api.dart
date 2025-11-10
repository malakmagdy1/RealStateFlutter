import 'dart:io';
import 'dart:convert';

void main() async {
  const apiKey = 'AIzaSyCfNYlgDP_V9qZOSyuMNHVtB5j3l_eAySc';

  print('Testing Gemini API...');
  print('API Key: ${apiKey.substring(0, 10)}...');

  try {
    // List available models
    print('\nListing available models...');
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('https://generativelanguage.googleapis.com/v1/models?key=$apiKey'),
    );
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('\nResponse:');
    final json = jsonDecode(responseBody);
    if (json['models'] != null) {
      print('\nAvailable models:');
      for (var model in json['models']) {
        print('- ${model['name']}');
        print('  Supports: ${model['supportedGenerationMethods']}');
      }
    } else {
      print(responseBody);
    }

  } catch (e) {
    print('\nError occurred:');
    print(e.toString());
  }
}
