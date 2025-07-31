import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'config_service.dart';

class ApiTestService {
  /// Test if the Gemini API key is working
  static Future<bool> testGeminiConnection() async {
    try {
      final apiKey = ConfigService.geminiApiKey;
      debugPrint('Testing Gemini API with key: ${apiKey.substring(0, 10)}...');

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      final prompt =
          'Say "Hello World" in JSON format like {"message": "Hello World"}';
      final content = [Content.text(prompt)];

      final response = await model.generateContent(content);
      final text = response.text;

      debugPrint('Gemini API test response: $text');

      if (text != null && text.isNotEmpty) {
        debugPrint('✅ Gemini API connection successful!');
        return true;
      } else {
        debugPrint('❌ Gemini API returned empty response');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Gemini API test failed: $e');

      // Check for specific error types
      if (e.toString().contains('503') || e.toString().contains('overloaded')) {
        debugPrint(
          '💡 Note: This is a temporary server overload. The API key is valid.',
        );
      }

      return false;
    }
  }

  /// Test environment variable loading
  static bool testEnvironmentLoading() {
    try {
      final key = ConfigService.geminiApiKey;
      debugPrint('✅ Environment variables loaded successfully');
      debugPrint('Gemini API key found: ${key.substring(0, 10)}...');
      return true;
    } catch (e) {
      debugPrint('❌ Environment loading failed: $e');
      return false;
    }
  }
}
