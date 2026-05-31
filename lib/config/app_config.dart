import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// Gemini API Key loaded from .env file
  static String get geminiApiKey {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY not found in .env file. '
        'Please ensure .env file exists with GEMINI_API_KEY=your_key'
      );
    }
    return apiKey;
  }
}
