import 'dart:convert';
import 'package:real/core/utils/constant.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/search/data/web_services/history_web_services.dart';

class SearchHistoryService {
  final HistoryWebServices _historyApi = HistoryWebServices();
  static String _baseSearchHistoryKey = 'search_history';
  static int maxHistoryItems = 10;

  // Get user-specific key based on token
  String get _searchHistoryKey {
    if (token != null && token!.isNotEmpty) {
      // Use first 20 chars of token as identifier to keep key reasonable length
      final tokenHash = token!.length > 20 ? token!.substring(0, 20) : token!;
      return '${_baseSearchHistoryKey}_$tokenHash';
    }
    return _baseSearchHistoryKey; // Fallback for no token
  }

  /// Get all search history
  Future<List<String>> getSearchHistory() async {
    try {
      // Load from cache FIRST for instant results (non-blocking)
      print('[SEARCH HISTORY] Loading search history from cache...');
      final historyJson = await CasheNetwork.getCasheDataAsync(key: _searchHistoryKey);

      if (historyJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(historyJson);
        final history = decoded.map((item) => item.toString()).toList();
        print('[SEARCH HISTORY] Loaded ${history.length} items from cache');

        // Sync from API in background (non-blocking)
        _syncFromAPI();

        return history;
      } else {
        print('[SEARCH HISTORY] No cached history found');

        // Try API as fallback only if no cache exists
        try {
          final response = await _historyApi.getSearchHistory(limit: maxHistoryItems);
          print('[SEARCH HISTORY] API response received');
          print('[SEARCH HISTORY] API response: $response');

          if (response['success'] == true && response['data'] != null) {
            // Check if data is a List or a Map with a list inside
            List<dynamic> historyData;
            if (response['data'] is List) {
              historyData = response['data'] as List<dynamic>;
            } else if (response['data'] is Map) {
              final data = response['data'] as Map<String, dynamic>;
              historyData = data['history'] as List<dynamic>? ?? data['searches'] as List<dynamic>? ?? [];
            } else {
              historyData = [];
            }

            final List<String> searches = [];
            for (var item in historyData) {
              if (item['metadata'] != null && item['metadata']['query'] != null) {
                searches.add(item['metadata']['query'] as String);
              }
            }

            print('[SEARCH HISTORY] Loaded ${searches.length} searches from API');
            await _saveToCache(searches);
            return searches;
          }
        } catch (apiError) {
          print('[SEARCH HISTORY] API error: $apiError');
        }

        return [];
      }
    } catch (e) {
      print('[SEARCH HISTORY] Error getting history: $e');
      return [];
    }
  }

  /// Sync from API in the background without blocking
  Future<void> _syncFromAPI() async {
    try {
      // Only sync if user is authenticated
      if (token == null || token!.isEmpty) {
        print('[SEARCH HISTORY] No token - skipping API sync, using cache only');
        return;
      }

      final response = await _historyApi.getSearchHistory(limit: maxHistoryItems);
      print('[SEARCH HISTORY] Background sync response: $response');

      if (response['success'] == true && response['data'] != null) {
        // Check if data is a List or a Map with a list inside
        List<dynamic> historyData;
        if (response['data'] is List) {
          historyData = response['data'] as List<dynamic>;
        } else if (response['data'] is Map) {
          final data = response['data'] as Map<String, dynamic>;
          historyData = data['history'] as List<dynamic>? ?? data['searches'] as List<dynamic>? ?? [];
        } else {
          historyData = [];
        }

        final List<String> searches = [];
        for (var item in historyData) {
          if (item['metadata'] != null && item['metadata']['query'] != null) {
            searches.add(item['metadata']['query'] as String);
          }
        }

        print('[SEARCH HISTORY] API returned ${searches.length} searches');
        print('[SEARCH HISTORY] Synced ${searches.length} searches from API');
        await _saveToCache(searches);
      } else {
        print('[SEARCH HISTORY] API returned no data or error - keeping cached data');
      }
    } catch (apiError) {
      print('[SEARCH HISTORY] Background sync error: $apiError - keeping cached data');
    }
  }

  /// Add a search query to history
  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      print('[SEARCH HISTORY] Adding query to history: $query');

      // ALWAYS save to cache first (ensures history is saved even if API fails)
      final historyJson = await CasheNetwork.getCasheDataAsync(key: _searchHistoryKey);
      List<String> history = [];

      if (historyJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(historyJson);
        history = decoded.map((item) => item.toString()).toList();
      }

      // Remove if already exists (to move it to top)
      history.remove(query);

      // Add to beginning of list
      history.insert(0, query);

      // Keep only the most recent items
      if (history.length > maxHistoryItems) {
        history = history.sublist(0, maxHistoryItems);
      }

      // Save to cache FIRST
      await _saveToCache(history);
      print('[SEARCH HISTORY] ✅ Saved to cache: $query (total: ${history.length})');

      // Then try to sync to API (non-blocking, in background)
      try {
        _historyApi.addToHistory(
          actionType: 'search',
          metadata: {'query': query},
        ).then((response) {
          print('[SEARCH HISTORY] ✅ Synced to API: $query');
        }).catchError((apiError) {
          print('[SEARCH HISTORY] API sync error: $apiError (already saved to cache)');
        });
      } catch (e) {
        print('[SEARCH HISTORY] API sync error: $e (already saved to cache)');
      }
    } catch (e) {
      print('[SEARCH HISTORY] Error adding to history: $e');
    }
  }

  /// Remove a specific search query from history
  Future<void> removeFromHistory(String query) async {
    try {
      print('[SEARCH HISTORY] Removing query from history: $query');

      // Try to remove from API
      try {
        // First, get the full history data with IDs
        final response = await _historyApi.getSearchHistory(limit: maxHistoryItems);

        if (response['status'] == true && response['data'] != null) {
          final List<dynamic> historyData = response['data'] as List<dynamic>;

          // Find the history entry with matching query
          for (var item in historyData) {
            if (item['metadata'] != null &&
                item['metadata']['query'] != null &&
                item['metadata']['query'] == query) {
              // Remove by ID
              await _historyApi.removeFromHistory(item['id'] as int);
              print('[SEARCH HISTORY] ✅ Removed from API: $query');
              break;
            }
          }
        }
      } catch (apiError) {
        print('[SEARCH HISTORY] API error: $apiError - removing from cache');
      }

      // Also remove from cache
      List<String> history = await getSearchHistory();
      history.remove(query);
      await _saveToCache(history);

      print('[SEARCH HISTORY] ✅ Removed from cache: $query (remaining: ${history.length})');
    } catch (e) {
      print('[SEARCH HISTORY] Error removing from history: $e');
    }
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    try {
      print('[SEARCH HISTORY] Clearing all history...');

      // Try to clear from API
      try {
        await _historyApi.clearAllHistory();
        print('[SEARCH HISTORY] ✅ Cleared all history from API');
      } catch (apiError) {
        print('[SEARCH HISTORY] API error: $apiError');
      }

      // Also clear cache
      await CasheNetwork.deletecasheItem(key: _searchHistoryKey);
      print('[SEARCH HISTORY] ✅ Cleared all history from cache');
    } catch (e) {
      print('[SEARCH HISTORY] Error clearing history: $e');
    }
  }

  /// Helper method to save history to cache
  Future<void> _saveToCache(List<String> history) async {
    try {
      final historyJson = json.encode(history);
      await CasheNetwork.insertToCashe(key: _searchHistoryKey, value: historyJson);
    } catch (e) {
      print('[SEARCH HISTORY] Error saving to cache: $e');
    }
  }

  /// Check if a query exists in history
  Future<bool> isInHistory(String query) async {
    try {
      final history = await getSearchHistory();
      return history.contains(query);
    } catch (e) {
      print('[SEARCH HISTORY] Error checking history: $e');
      return false;
    }
  }
}
