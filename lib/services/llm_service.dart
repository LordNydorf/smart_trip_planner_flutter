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
Return ONLY a valid JSON object without any markdown formatting, code blocks, or additional text.
Do NOT wrap the response in ```json or ``` blocks.
Use this exact format:
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
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    const models = ['gemini-1.5-flash', 'gemini-1.5-pro']; // Fallback models
    int modelIndex = 0;

    while (retryCount < maxRetries) {
      try {
        final model = GenerativeModel(
          model: models[modelIndex],
          apiKey: apiKey,
        );

        debugPrint(
          'Trying model: ${models[modelIndex]} (attempt ${retryCount + 1})',
        );

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

        // If we get here, the request was successful
        return;
      } catch (e) {
        retryCount++;
        debugPrint(
          'Gemini API attempt $retryCount failed with ${models[modelIndex]}: $e',
        );

        // Check if it's a server overload error (503)
        if (e.toString().contains('503') ||
            e.toString().contains('overloaded')) {
          if (retryCount < maxRetries) {
            // Try a different model if available
            if (modelIndex < models.length - 1) {
              modelIndex++;
              debugPrint('Switching to fallback model: ${models[modelIndex]}');
              yield 'Server busy, trying alternative model...';
            } else {
              debugPrint(
                'Server overloaded, retrying in ${retryDelay.inSeconds} seconds... ($retryCount/$maxRetries)',
              );
              yield 'Server is busy, retrying... (attempt $retryCount/$maxRetries)';
              await Future.delayed(retryDelay);
              modelIndex = 0; // Reset to first model
            }
            continue;
          } else {
            yield 'Error: Gemini servers are currently overloaded. Please try again in a few minutes.';
            return;
          }
        } else {
          // For other errors, don't retry
          throw Exception('Gemini API error: $e');
        }
      }
    }
  }

  Future<Itinerary?> parseItineraryFromJson(String jsonString) async {
    try {
      // Clean the JSON string by removing markdown code blocks
      String cleanedJson = _extractJsonFromMarkdown(jsonString);

      final data = jsonDecode(cleanedJson);

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
      debugPrint('Raw response: $jsonString');
      return null;
    }
  }

  /// Extracts JSON content from markdown code blocks or returns the original string
  String _extractJsonFromMarkdown(String text) {
    // Remove any leading/trailing whitespace
    text = text.trim();

    debugPrint(
      'Extracting JSON from response (first 200 chars): ${text.length > 200 ? "${text.substring(0, 200)}..." : text}',
    );

    // Check if the text starts with ```json or ``` and ends with ```
    if (text.startsWith('```json')) {
      // Extract content between ```json and ```
      final startIndex = text.indexOf('```json') + 7; // 7 = length of "```json"
      final endIndex = text.lastIndexOf('```');
      if (endIndex > startIndex) {
        final extracted = text.substring(startIndex, endIndex).trim();
        debugPrint('Extracted JSON from ```json blocks');
        return extracted;
      }
    } else if (text.startsWith('```')) {
      // Extract content between ``` and ```
      final startIndex = text.indexOf('```') + 3; // 3 = length of "```"
      final endIndex = text.lastIndexOf('```');
      if (endIndex > startIndex) {
        final extracted = text.substring(startIndex, endIndex).trim();
        debugPrint('Extracted JSON from ``` blocks');
        return extracted;
      }
    }

    // If no markdown code blocks found, return original text
    debugPrint('No markdown blocks found, using original text');
    return text;
  }
}
