import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../features/profile/profile_page.dart';
import 'config_service.dart';
import 'token_config.dart';

class TokenCounter {
  // Cache for GenerativeModel instance to avoid recreating
  static GenerativeModel? _model;

  static GenerativeModel get _geminiModel {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: ConfigService.geminiApiKey,
    );
    return _model!;
  }

  // Approximate token counting based on text length
  // This is a simplified version - for production, use the actual API's token counting
  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;

    // Rough estimation: 1 token ≈ 4 characters for English text
    // This includes spaces, punctuation, etc.
    return (text.length / 4).ceil();
  }

  // Real Gemini token counting using the API with caching
  static Future<int> countTokensWithGemini(List<Content> content) async {
    try {
      // Create cache key from content
      String cacheKey = '';
      for (final contentItem in content) {
        for (final part in contentItem.parts) {
          if (part is TextPart) {
            cacheKey += part.text;
          }
        }
      }

      // Check cache first if enabled
      if (TokenCountingConfig.enableTokenCaching) {
        final cached = TokenCache.get(cacheKey);
        if (cached != null) {
          if (TokenCountingConfig.enableDetailedLogging) {
            debugPrint('Token count retrieved from cache: $cached tokens');
          }
          return cached;
        }
      }

      // Get real token count from API
      final tokenCount = await _geminiModel.countTokens(content);
      final result = tokenCount.totalTokens;

      // Cache the result
      if (TokenCountingConfig.enableTokenCaching) {
        TokenCache.set(cacheKey, result);
      }

      if (TokenCountingConfig.enableDetailedLogging) {
        debugPrint('Real token count from Gemini API: $result tokens');
      }

      return result;
    } catch (e) {
      debugPrint('Error counting tokens with Gemini API: $e');
      // Fallback to estimation - extract text from content
      String text = '';
      for (final contentItem in content) {
        for (final part in contentItem.parts) {
          if (part is TextPart) {
            text += part.text;
          }
        }
      }
      final estimated = estimateTokens(text);

      if (TokenCountingConfig.enableDetailedLogging) {
        debugPrint('Fallback token estimation: $estimated tokens');
      }

      return estimated;
    }
  }

  // Real token counting for prompts using Gemini API
  static Future<int> countPromptTokensWithGemini(
    String userPrompt,
    String systemPrompt,
  ) async {
    try {
      final content = [Content.text(systemPrompt), Content.text(userPrompt)];
      return await countTokensWithGemini(content);
    } catch (e) {
      debugPrint('Error counting prompt tokens: $e');
      // Fallback to estimation
      return estimateTokens(userPrompt) + estimateTokens(systemPrompt);
    }
  }

  // Real token counting for responses using Gemini API
  static Future<int> countResponseTokensWithGemini(String response) async {
    try {
      final content = [Content.text(response)];
      return await countTokensWithGemini(content);
    } catch (e) {
      debugPrint('Error counting response tokens: $e');
      // Fallback to estimation
      return estimateTokens(response);
    }
  }

  static int countPromptTokens(String userPrompt, String systemPrompt) {
    return estimateTokens(userPrompt) + estimateTokens(systemPrompt);
  }

  static int countResponseTokens(String response) {
    return estimateTokens(response);
  }

  // Pricing estimation (updated for Gemini pricing as of 2024)
  static double estimateCost(
    int inputTokens,
    int outputTokens, {
    String model = 'gemini-1.5-flash',
  }) {
    // Gemini 1.5 Flash pricing (as of 2024)
    double inputCostPer1K;
    double outputCostPer1K;

    switch (model) {
      case 'gemini-1.5-pro':
        inputCostPer1K = 0.00125; // $0.00125 per 1K input tokens
        outputCostPer1K = 0.00375; // $0.00375 per 1K output tokens
        break;
      case 'gemini-1.5-flash':
      default:
        inputCostPer1K = 0.000075; // $0.000075 per 1K input tokens
        outputCostPer1K = 0.0003; // $0.0003 per 1K output tokens
        break;
    }

    final inputCost = (inputTokens / 1000) * inputCostPer1K;
    final outputCost = (outputTokens / 1000) * outputCostPer1K;

    return inputCost + outputCost;
  }

  static Map<String, dynamic> analyzeUsage(
    String userPrompt,
    String systemPrompt,
    String response,
  ) {
    final inputTokens = countPromptTokens(userPrompt, systemPrompt);
    final outputTokens = countResponseTokens(response);
    final totalTokens = inputTokens + outputTokens;
    final estimatedCost = estimateCost(inputTokens, outputTokens);

    return {
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'estimatedCost': estimatedCost,
    };
  }

  // Enhanced analysis using real Gemini token counting
  static Future<Map<String, dynamic>> analyzeUsageWithGemini(
    String userPrompt,
    String systemPrompt,
    String response, {
    String model = 'gemini-1.5-flash',
  }) async {
    try {
      final inputTokens = await countPromptTokensWithGemini(
        userPrompt,
        systemPrompt,
      );
      final outputTokens = await countResponseTokensWithGemini(response);
      final totalTokens = inputTokens + outputTokens;
      final estimatedCost = estimateCost(
        inputTokens,
        outputTokens,
        model: model,
      );

      return {
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'totalTokens': totalTokens,
        'estimatedCost': estimatedCost,
        'method': 'gemini_api', // Indicates real API was used
      };
    } catch (e) {
      debugPrint(
        'Error in Gemini token analysis, falling back to estimation: $e',
      );
      // Fallback to estimation
      final result = analyzeUsage(userPrompt, systemPrompt, response);
      result['method'] = 'estimation_fallback';
      return result;
    }
  }

  // Batch token counting for multiple texts
  static Future<List<int>> countTokensBatch(List<String> texts) async {
    final results = <int>[];

    for (final text in texts) {
      try {
        final content = [Content.text(text)];
        final tokenCount = await countTokensWithGemini(content);
        results.add(tokenCount);
      } catch (e) {
        debugPrint('Error counting tokens for text: $e');
        results.add(estimateTokens(text));
      }
    }

    return results;
  }
}

// Enhanced Usage Tracking Service
class UsageTrackingService {
  static final UsageTrackingService _instance =
      UsageTrackingService._internal();
  factory UsageTrackingService() => _instance;
  UsageTrackingService._internal();

  Future<void> trackRequest({
    required WidgetRef ref,
    required String userPrompt,
    required String systemPrompt,
    required String response,
    String model = 'gemini-1.5-flash',
    bool useRealTokenCounting = true,
  }) async {
    try {
      Map<String, dynamic> analysis;

      if (useRealTokenCounting) {
        // Use real Gemini token counting
        analysis = await TokenCounter.analyzeUsageWithGemini(
          userPrompt,
          systemPrompt,
          response,
          model: model,
        );
      } else {
        // Use estimation
        analysis = TokenCounter.analyzeUsage(
          userPrompt,
          systemPrompt,
          response,
        );
      }

      await ref
          .read(usageStatsProvider.notifier)
          .incrementUsage(
            tokens: analysis['totalTokens'],
            cost: analysis['estimatedCost'],
          );

      debugPrint(
        'Usage tracked (${analysis['method'] ?? 'estimation'}): ${analysis['totalTokens']} tokens, \$${analysis['estimatedCost'].toStringAsFixed(4)}',
      );
    } catch (e) {
      debugPrint('Error tracking usage: $e');
    }
  }

  Future<void> trackError({
    required WidgetRef ref,
    required String userPrompt,
    required String systemPrompt,
    bool useRealTokenCounting = true,
  }) async {
    try {
      int inputTokens;

      if (useRealTokenCounting) {
        // Use real Gemini token counting for failed requests (input only)
        inputTokens = await TokenCounter.countPromptTokensWithGemini(
          userPrompt,
          systemPrompt,
        );
      } else {
        // Use estimation
        inputTokens = TokenCounter.countPromptTokens(userPrompt, systemPrompt);
      }

      final estimatedCost = TokenCounter.estimateCost(inputTokens, 0);

      await ref
          .read(usageStatsProvider.notifier)
          .incrementUsage(tokens: inputTokens, cost: estimatedCost);

      debugPrint(
        'Error usage tracked (${useRealTokenCounting ? 'gemini_api' : 'estimation'}): $inputTokens input tokens, \$${estimatedCost.toStringAsFixed(4)}',
      );
    } catch (e) {
      debugPrint('Error tracking error usage: $e');
    }
  }

  Map<String, String> formatUsageDisplay(int totalTokens, double totalCost) {
    String tokensDisplay;
    if (totalTokens >= 1000000) {
      tokensDisplay = '${(totalTokens / 1000000).toStringAsFixed(1)}M';
    } else if (totalTokens >= 1000) {
      tokensDisplay = '${(totalTokens / 1000).toStringAsFixed(1)}K';
    } else {
      tokensDisplay = totalTokens.toString();
    }

    String costDisplay = '\$${totalCost.toStringAsFixed(4)}';
    if (totalCost >= 1.0) {
      costDisplay = '\$${totalCost.toStringAsFixed(2)}';
    }

    return {'tokens': tokensDisplay, 'cost': costDisplay};
  }

  double getAverageTokensPerRequest(int totalRequests, int totalTokens) {
    if (totalRequests == 0) return 0.0;
    return totalTokens / totalRequests;
  }

  double getAverageCostPerRequest(int totalRequests, double totalCost) {
    if (totalRequests == 0) return 0.0;
    return totalCost / totalRequests;
  }

  // Budget warnings
  bool shouldShowBudgetWarning(
    double totalCost, {
    double warningThreshold = 5.0,
  }) {
    return totalCost >= warningThreshold;
  }

  bool shouldBlockRequests(double totalCost, {double blockThreshold = 10.0}) {
    return totalCost >= blockThreshold;
  }

  String getBudgetMessage(double totalCost) {
    if (totalCost >= 10.0) {
      return 'Budget limit reached. Please contact support to continue.';
    } else if (totalCost >= 5.0) {
      return 'You\'re approaching your budget limit. Consider upgrading your plan.';
    } else if (totalCost >= 2.0) {
      return 'You\'ve used a significant portion of your budget this month.';
    }
    return '';
  }
}

// Provider for usage tracking service
final usageTrackingServiceProvider = Provider<UsageTrackingService>((ref) {
  return UsageTrackingService();
});
