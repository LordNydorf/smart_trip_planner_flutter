import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/profile/profile_page.dart';

class TokenCounter {
  // Approximate token counting based on text length
  // This is a simplified version - for production, use the actual API's token counting
  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;

    // Rough estimation: 1 token ≈ 4 characters for English text
    // This includes spaces, punctuation, etc.
    return (text.length / 4).ceil();
  }

  static int countPromptTokens(String userPrompt, String systemPrompt) {
    return estimateTokens(userPrompt) + estimateTokens(systemPrompt);
  }

  static int countResponseTokens(String response) {
    return estimateTokens(response);
  }

  // Pricing estimation (based on OpenAI GPT-3.5-turbo pricing as of 2024)
  static double estimateCost(
    int inputTokens,
    int outputTokens, {
    String model = 'gpt-3.5-turbo',
  }) {
    const double inputCostPer1K = 0.0015; // $0.0015 per 1K input tokens
    const double outputCostPer1K = 0.002; // $0.002 per 1K output tokens

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
    String model = 'gpt-3.5-turbo',
  }) async {
    try {
      final analysis = TokenCounter.analyzeUsage(
        userPrompt,
        systemPrompt,
        response,
      );

      await ref
          .read(usageStatsProvider.notifier)
          .incrementUsage(
            tokens: analysis['totalTokens'],
            cost: analysis['estimatedCost'],
          );

      debugPrint(
        'Usage tracked: ${analysis['totalTokens']} tokens, \$${analysis['estimatedCost'].toStringAsFixed(4)}',
      );
    } catch (e) {
      debugPrint('Error tracking usage: $e');
    }
  }

  Future<void> trackError({
    required WidgetRef ref,
    required String userPrompt,
    required String systemPrompt,
  }) async {
    try {
      // Count tokens for failed requests (input only)
      final inputTokens = TokenCounter.countPromptTokens(
        userPrompt,
        systemPrompt,
      );
      final estimatedCost = TokenCounter.estimateCost(inputTokens, 0);

      await ref
          .read(usageStatsProvider.notifier)
          .incrementUsage(tokens: inputTokens, cost: estimatedCost);

      debugPrint(
        'Error usage tracked: $inputTokens input tokens, \$${estimatedCost.toStringAsFixed(4)}',
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
