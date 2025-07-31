import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../services/llm_service.dart';
import '../../services/config_service.dart';
import '../../models/itinerary_model.dart';
import '../../services/error_handler.dart';
import '../../services/offline_mode_service.dart';

// LLM Service Provider
final llmServiceProvider = Provider<LLMService>((ref) {
  return LLMService(apiKey: ConfigService.geminiApiKey, provider: 'gemini');
});

// Itinerary Generation State
class ItineraryGenerationState {
  final bool isLoading;
  final String streamedContent;
  final Itinerary? generatedItinerary;
  final String? error;

  const ItineraryGenerationState({
    this.isLoading = false,
    this.streamedContent = '',
    this.generatedItinerary,
    this.error,
  });

  ItineraryGenerationState copyWith({
    bool? isLoading,
    String? streamedContent,
    Itinerary? generatedItinerary,
    String? error,
  }) {
    return ItineraryGenerationState(
      isLoading: isLoading ?? this.isLoading,
      streamedContent: streamedContent ?? this.streamedContent,
      generatedItinerary: generatedItinerary ?? this.generatedItinerary,
      error: error ?? this.error,
    );
  }
}

// Itinerary Generation Controller
class ItineraryGenerationController
    extends StateNotifier<ItineraryGenerationState> {
  final LLMService _llmService;

  ItineraryGenerationController(this._llmService)
    : super(const ItineraryGenerationState());

  Future<void> generateItinerary(String prompt) async {
    state = state.copyWith(
      isLoading: true,
      streamedContent: '',
      generatedItinerary: null,
      error: null,
    );

    try {
      // Check if we're online
      final isOnline = await ErrorHandler.isOnline();
      if (!isOnline) {
        // Queue the request for later processing
        final offlineService = OfflineModeController();
        final systemPrompt = '''
You are a travel planner AI. Create a detailed travel itinerary based on the user's request.
Return ONLY a valid JSON object in the exact format specified.
''';

        await offlineService.queueOfflineRequest(prompt, systemPrompt);

        state = state.copyWith(
          isLoading: false,
          error:
              'You\'re offline. Your request has been queued and will be processed when you\'re back online.',
        );
        return;
      }

      String fullContent = '';

      await for (final chunk in _llmService.generateItineraryStream(prompt)) {
        if (chunk.startsWith('Error:')) {
          state = state.copyWith(isLoading: false, error: chunk);
          return;
        }

        fullContent += chunk;
        state = state.copyWith(streamedContent: fullContent);
      }

      // Try to parse the complete JSON
      final itinerary = await _llmService.parseItineraryFromJson(fullContent);

      if (itinerary != null) {
        // TODO: Track usage with token counting when WidgetRef is available

        state = state.copyWith(isLoading: false, generatedItinerary: itinerary);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to parse itinerary from response. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('Itinerary generation error: $e');
      final appError = ErrorHandler.handleError(e);
      final errorMessage = ErrorHandler.getErrorMessage(appError);

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to generate itinerary: $errorMessage',
      );
    }
  }

  void clearState() {
    state = const ItineraryGenerationState();
  }
}

// Provider for the controller
final itineraryGenerationControllerProvider =
    StateNotifierProvider<
      ItineraryGenerationController,
      ItineraryGenerationState
    >((ref) {
      final llmService = ref.watch(llmServiceProvider);
      return ItineraryGenerationController(llmService);
    });
