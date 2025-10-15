import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _searchHistoryKey = 'search_history';
  static const int maxHistoryItems = 10;

  /// Get all search history
  Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_searchHistoryKey) ?? [];
      return history;
    } catch (e) {
      print('[SEARCH HISTORY] Error getting history: $e');
      return [];
    }
  }

  /// Add a search query to history
  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];

      // Remove if already exists (to move it to top)
      history.remove(query);

      // Add to beginning of list
      history.insert(0, query);

      // Keep only the most recent items
      if (history.length > maxHistoryItems) {
        history = history.sublist(0, maxHistoryItems);
      }

      await prefs.setStringList(_searchHistoryKey, history);
      print('[SEARCH HISTORY] Added: $query');
    } catch (e) {
      print('[SEARCH HISTORY] Error adding to history: $e');
    }
  }

  /// Remove a specific search query from history
  Future<void> removeFromHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];

      history.remove(query);

      await prefs.setStringList(_searchHistoryKey, history);
      print('[SEARCH HISTORY] Removed: $query');
    } catch (e) {
      print('[SEARCH HISTORY] Error removing from history: $e');
    }
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
      print('[SEARCH HISTORY] Cleared all history');
    } catch (e) {
      print('[SEARCH HISTORY] Error clearing history: $e');
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
