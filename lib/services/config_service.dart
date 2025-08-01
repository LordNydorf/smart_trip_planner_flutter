import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration service to manage environment variables and app settings
class ConfigService {
  static String get geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY not found in environment variables. '
        'Please check your .env file.',
      );
    }
    return key;
  }

  static String get openAiApiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'OPENAI_API_KEY not found in environment variables. '
        'Please check your .env file.',
      );
    }
    return key;
  }

  // Firebase API Keys
  static String get firebaseWebApiKey {
    final key = dotenv.env['FIREBASE_WEB_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'FIREBASE_WEB_API_KEY not found in environment variables. '
        'Please check your .env file.',
      );
    }
    return key;
  }

  static String get firebaseAndroidApiKey {
    final key = dotenv.env['FIREBASE_ANDROID_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'FIREBASE_ANDROID_API_KEY not found in environment variables. '
        'Please check your .env file.',
      );
    }
    return key;
  }

  static String get firebaseIosApiKey {
    final key = dotenv.env['FIREBASE_IOS_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'FIREBASE_IOS_API_KEY not found in environment variables. '
        'Please check your .env file.',
      );
    }
    return key;
  }

  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  /// Check if API keys are properly configured
  static bool get hasGeminiKey =>
      dotenv.env['GEMINI_API_KEY']?.isNotEmpty ?? false;
  static bool get hasOpenAiKey =>
      dotenv.env['OPENAI_API_KEY']?.isNotEmpty ?? false;
  static bool get hasFirebaseWebKey =>
      dotenv.env['FIREBASE_WEB_API_KEY']?.isNotEmpty ?? false;
  static bool get hasFirebaseAndroidKey =>
      dotenv.env['FIREBASE_ANDROID_API_KEY']?.isNotEmpty ?? false;
  static bool get hasFirebaseIosKey =>
      dotenv.env['FIREBASE_IOS_API_KEY']?.isNotEmpty ?? false;
  static bool get hasGoogleMapsKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY']?.isNotEmpty ?? false;

  /// Get available providers based on configured API keys
  static List<String> get availableProviders {
    final providers = <String>[];
    if (hasGeminiKey) providers.add('gemini');
    if (hasOpenAiKey) providers.add('openai');
    return providers;
  }
}
