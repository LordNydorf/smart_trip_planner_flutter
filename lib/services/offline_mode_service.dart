import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/itinerary_model.dart';
import 'error_handler.dart';

class OfflineQueue {
  final String id;
  final String userPrompt;
  final String systemPrompt;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  OfflineQueue({
    required this.id,
    required this.userPrompt,
    required this.systemPrompt,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userPrompt': userPrompt,
      'systemPrompt': systemPrompt,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory OfflineQueue.fromMap(Map<String, dynamic> map) {
    return OfflineQueue(
      id: map['id'],
      userPrompt: map['userPrompt'],
      systemPrompt: map['systemPrompt'],
      timestamp: DateTime.parse(map['timestamp']),
      metadata: map['metadata'],
    );
  }
}

class OfflineModeState {
  final bool isOnline;
  final bool isOfflineModeEnabled;
  final List<OfflineQueue> pendingRequests;
  final List<Itinerary> cachedItineraries;
  final bool isProcessingQueue;

  const OfflineModeState({
    required this.isOnline,
    required this.isOfflineModeEnabled,
    required this.pendingRequests,
    required this.cachedItineraries,
    required this.isProcessingQueue,
  });

  OfflineModeState copyWith({
    bool? isOnline,
    bool? isOfflineModeEnabled,
    List<OfflineQueue>? pendingRequests,
    List<Itinerary>? cachedItineraries,
    bool? isProcessingQueue,
  }) {
    return OfflineModeState(
      isOnline: isOnline ?? this.isOnline,
      isOfflineModeEnabled: isOfflineModeEnabled ?? this.isOfflineModeEnabled,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      cachedItineraries: cachedItineraries ?? this.cachedItineraries,
      isProcessingQueue: isProcessingQueue ?? this.isProcessingQueue,
    );
  }
}

class OfflineModeController extends StateNotifier<OfflineModeState> {
  late final Connectivity _connectivity;
  Box? _offlineBox;
  Box? _cachedItinerariesBox;

  OfflineModeController()
    : super(
        const OfflineModeState(
          isOnline: true,
          isOfflineModeEnabled: true,
          pendingRequests: [],
          cachedItineraries: [],
          isProcessingQueue: false,
        ),
      ) {
    _connectivity = Connectivity();
    _initializeOfflineMode();
    _monitorConnectivity();
  }

  Future<void> _initializeOfflineMode() async {
    try {
      _offlineBox = await Hive.openBox('offlineQueue');
      _cachedItinerariesBox = await Hive.openBox('cachedItineraries');

      await _loadPendingRequests();
      await _loadCachedItineraries();

      final isOnline = await ErrorHandler.isOnline();
      state = state.copyWith(isOnline: isOnline);

      if (isOnline && state.pendingRequests.isNotEmpty) {
        _processOfflineQueue();
      }
    } catch (e) {
      debugPrint('Error initializing offline mode: $e');
    }
  }

  void _monitorConnectivity() {
    _connectivity.onConnectivityChanged.listen((result) {
      final isOnline = !result.contains(ConnectivityResult.none);
      state = state.copyWith(isOnline: isOnline);

      if (isOnline &&
          state.pendingRequests.isNotEmpty &&
          !state.isProcessingQueue) {
        _processOfflineQueue();
      }
    });
  }

  Future<void> _loadPendingRequests() async {
    try {
      final requestsData = _offlineBox?.values.toList() ?? [];
      final requests = requestsData
          .map((data) => OfflineQueue.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      state = state.copyWith(pendingRequests: requests);
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
    }
  }

  Future<void> _loadCachedItineraries() async {
    try {
      final cachedData = _cachedItinerariesBox?.values.toList() ?? [];
      final itineraries = cachedData.cast<Itinerary>().toList();

      state = state.copyWith(cachedItineraries: itineraries);
    } catch (e) {
      debugPrint('Error loading cached itineraries: $e');
    }
  }

  Future<String> queueOfflineRequest(
    String userPrompt,
    String systemPrompt,
  ) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final request = OfflineQueue(
      id: id,
      userPrompt: userPrompt,
      systemPrompt: systemPrompt,
      timestamp: DateTime.now(),
    );

    try {
      await _offlineBox?.put(id, request.toMap());

      final updatedRequests = [...state.pendingRequests, request];
      state = state.copyWith(pendingRequests: updatedRequests);

      return id;
    } catch (e) {
      debugPrint('Error queuing offline request: $e');
      throw AppError(
        type: ErrorType.storage,
        message: 'Failed to queue request for later processing',
        originalError: e,
      );
    }
  }

  Future<void> _processOfflineQueue() async {
    if (state.isProcessingQueue || !state.isOnline) return;

    state = state.copyWith(isProcessingQueue: true);

    try {
      for (final request in state.pendingRequests) {
        try {
          // This would typically call your LLM service
          // For now, we'll just remove the request from the queue
          await _removeFromQueue(request.id);

          // Add a small delay to prevent overwhelming the API
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          debugPrint('Error processing queued request ${request.id}: $e');
          // Continue with next request
        }
      }
    } finally {
      state = state.copyWith(isProcessingQueue: false);
    }
  }

  Future<void> _removeFromQueue(String requestId) async {
    try {
      await _offlineBox?.delete(requestId);

      final updatedRequests = state.pendingRequests
          .where((request) => request.id != requestId)
          .toList();

      state = state.copyWith(pendingRequests: updatedRequests);
    } catch (e) {
      debugPrint('Error removing request from queue: $e');
    }
  }

  Future<void> cacheItinerary(Itinerary itinerary) async {
    try {
      final key = '${itinerary.title}_${DateTime.now().millisecondsSinceEpoch}';
      await _cachedItinerariesBox?.put(key, itinerary);

      final updatedCache = [...state.cachedItineraries, itinerary];
      state = state.copyWith(cachedItineraries: updatedCache);
    } catch (e) {
      debugPrint('Error caching itinerary: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await _cachedItinerariesBox?.clear();
      state = state.copyWith(cachedItineraries: []);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  void toggleOfflineMode() {
    state = state.copyWith(isOfflineModeEnabled: !state.isOfflineModeEnabled);
  }

  int get pendingRequestsCount => state.pendingRequests.length;
  int get cachedItinerariesCount => state.cachedItineraries.length;

  bool get canMakeRequests => state.isOnline || state.isOfflineModeEnabled;

  String getOfflineMessage() {
    if (!state.isOnline && state.pendingRequests.isNotEmpty) {
      return 'You have ${state.pendingRequests.length} requests queued for when you\'re back online.';
    } else if (!state.isOnline) {
      return 'You\'re offline. Requests will be queued until connection is restored.';
    }
    return '';
  }

  List<Itinerary> getRecentItineraries({int limit = 10}) {
    return state.cachedItineraries.take(limit).toList();
  }

  Future<void> retryFailedRequests() async {
    if (state.isOnline && !state.isProcessingQueue) {
      await _processOfflineQueue();
    }
  }

  @override
  void dispose() {
    _offlineBox?.close();
    _cachedItinerariesBox?.close();
    super.dispose();
  }
}

// Provider for offline mode
final offlineModeProvider =
    StateNotifierProvider<OfflineModeController, OfflineModeState>((ref) {
      return OfflineModeController();
    });

// Helper widget for offline status
class OfflineStatusBanner extends StatelessWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final offlineState = ref.watch(offlineModeProvider);

        if (offlineState.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.orange[100],
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange[800], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  offlineState.pendingRequests.isNotEmpty
                      ? '${offlineState.pendingRequests.length} requests queued'
                      : 'You\'re offline',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (offlineState.pendingRequests.isNotEmpty)
                Text(
                  'Will sync when online',
                  style: TextStyle(color: Colors.orange[600], fontSize: 10),
                ),
            ],
          ),
        );
      },
    );
  }
}
