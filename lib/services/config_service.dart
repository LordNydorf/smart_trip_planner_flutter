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
    return dotenv.env['FIREBASE_WEB_API_KEY'] ??
        'AIzaSyCi1ginTmZ8mFhoP5GHYbzMbuijEds_tc4';
  }

  static String get firebaseAndroidApiKey {
    return dotenv.env['FIREBASE_ANDROID_API_KEY'] ??
        'AIzaSyBX8IwcEF00JKednTMYvRKPtmqiVbQ-Qp4';
  }

  static String get firebaseIosApiKey {
    return dotenv.env['FIREBASE_IOS_API_KEY'] ??
        'AIzaSyBxVxP5sIVREaHBKpmovqZEpayLmL1hDeI';
  }

  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  /// Check if API keys are properly configured
  static bool get hasGeminiKey =>
      dotenv.env['GEMINI_API_KEY']?.isNotEmpty ?? false;
  static bool get hasOpenAiKey =>
      dotenv.env['OPENAI_API_KEY']?.isNotEmpty ?? false;

  /// Get available providers based on configured API keys
  static List<String> get availableProviders {
    final providers = <String>[];
    if (hasGeminiKey) providers.add('gemini');
    if (hasOpenAiKey) providers.add('openai');
    return providers;
  }
}
