import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/itinerary_model.dart';
import 'error_handler.dart';

class LLMService {
  static const String _openAIBaseUrl = 'https://api.openai.com/v1';

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
    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

      final prompt = '$systemPrompt\n\nUser request: $userPrompt';
      final content = [Content.text(prompt)];

      // Use streaming for better user experience
      final response = model.generateContentStream(content);

      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null) {
          yield text;
        }
      }
    } catch (e) {
      throw Exception('Gemini API error: $e');
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
