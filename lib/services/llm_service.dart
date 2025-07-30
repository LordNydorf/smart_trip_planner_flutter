import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/itinerary_model.dart';
import 'error_handler.dart';

class LLMService {
  static const String _openAIBaseUrl = 'https://api.openai.com/v1';
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  final String apiKey;
  final String provider; // 'openai' or 'gemini'

  LLMService({required this.apiKey, this.provider = 'openai'});

  Stream<String> generateItineraryStream(String prompt) async* {
    // Check if online before making request
    final isOnline = await ErrorHandler.isOnline();
    if (!isOnline) {
      yield 'Error: No internet connection available';
      return;
    }

    final systemPrompt = '''
You are a travel planner AI. Create a detailed travel itinerary based on the user's request.
Return ONLY a valid JSON object in this exact format:
{
  "title": "Trip Title",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "days": [
    {
      "date": "YYYY-MM-DD",
      "summary": "Day summary",
      "items": [
        {
          "time": "HH:MM",
          "activity": "Activity description",
          "location": "Location name"
        }
      ]
    }
  ]
}
''';

    try {
      if (provider == 'openai') {
        yield* _streamOpenAI(systemPrompt, prompt);
      } else {
        yield* _streamGemini(systemPrompt, prompt);
      }
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      yield 'Error: ${ErrorHandler.getErrorMessage(appError)}';
    }
  }

  Stream<String> _streamOpenAI(String systemPrompt, String userPrompt) async* {
    final response = await http.post(
      Uri.parse('$_openAIBaseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'stream': true,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final lines = response.body.split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ') && !line.contains('[DONE]')) {
          try {
            final data = jsonDecode(line.substring(6));
            final content = data['choices'][0]['delta']['content'];
            if (content != null) {
              yield content;
            }
          } catch (e) {
            // Skip malformed chunks
          }
        }
      }
    } else {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
  }

  Stream<String> _streamGemini(String systemPrompt, String userPrompt) async* {
    // For now, we'll implement a simple non-streaming version for Gemini
    // You can enhance this with actual Gemini streaming later
    final response = await http.post(
      Uri.parse(
        '$_geminiBaseUrl/models/gemini-pro:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': '$systemPrompt\n\nUser request: $userPrompt'},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['candidates'][0]['content']['parts'][0]['text'];

      // Simulate streaming by yielding chunks
      for (int i = 0; i < content.length; i += 10) {
        yield content.substring(i, (i + 10).clamp(0, content.length));
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } else {
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }

  Future<Itinerary?> parseItineraryFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);

      // Validate required fields
      if (data['title'] == null ||
          data['startDate'] == null ||
          data['endDate'] == null ||
          data['days'] == null) {
        throw Exception('Missing required fields in JSON response');
      }

      final days = (data['days'] as List).map((dayData) {
        final items = (dayData['items'] as List).map((itemData) {
          return ItineraryItem(
            time: itemData['time'],
            activity: itemData['activity'],
            location: itemData['location'],
          );
        }).toList();

        return ItineraryDay(
          date: DateTime.parse(dayData['date']),
          summary: dayData['summary'],
          items: items,
        );
      }).toList();

      return Itinerary(
        title: data['title'],
        startDate: DateTime.parse(data['startDate']),
        endDate: DateTime.parse(data['endDate']),
        days: days,
      );
    } catch (e) {
      debugPrint('Error parsing itinerary JSON: $e');
      return null;
    }
  }
}
