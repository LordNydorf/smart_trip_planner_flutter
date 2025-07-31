// Token counting configuration
class TokenCountingConfig {
  // Whether to use real Gemini API token counting or estimation
  static const bool useRealTokenCounting = true;

  // Whether to cache token counts to reduce API calls
  static const bool enableTokenCaching = true;

  // Maximum cache size for token counts
  static const int maxCacheSize = 1000;

  // Whether to enable detailed token usage logging
  static const bool enableDetailedLogging = true;

  // Fallback to estimation if API fails
  static const bool fallbackToEstimation = true;

  // Batch size for token counting operations
  static const int batchSize = 10;
}

// Token cache for reducing API calls
class TokenCache {
  static final Map<String, int> _cache = {};

  static int? get(String text) {
    return _cache[text];
  }

  static void set(String text, int tokens) {
    if (_cache.length >= TokenCountingConfig.maxCacheSize) {
      // Remove oldest entries (simple LRU)
      final keys = _cache.keys.take(_cache.length ~/ 2).toList();
      for (final key in keys) {
        _cache.remove(key);
      }
    }
    _cache[text] = tokens;
  }

  static void clear() {
    _cache.clear();
  }

  static int get size => _cache.length;
}
