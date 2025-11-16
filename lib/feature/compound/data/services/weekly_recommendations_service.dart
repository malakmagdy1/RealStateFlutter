import 'package:real/feature/auth/data/network/local_netwrok.dart';

class WeeklyRecommendationsService {
  static const String _lastUpdateKey = 'weekly_recommendations_last_update';
  static const String _recommendedIdsKey = 'weekly_recommended_compound_ids';
  static const int _daysInWeek = 7;

  /// Check if recommendations need to be refreshed (once per week)
  static Future<bool> shouldRefreshRecommendations() async {
    try {
      final lastUpdateStr = await CasheNetwork.getCasheDataAsync(key: _lastUpdateKey);

      if (lastUpdateStr.isEmpty) {
        return true; // First time, need to generate
      }

      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      final difference = now.difference(lastUpdate);

      // Refresh if more than 7 days have passed
      return difference.inDays >= _daysInWeek;
    } catch (e) {
      print('[WEEKLY RECOMMENDATIONS] Error checking last update: $e');
      return true; // On error, refresh
    }
  }

  /// Save the current timestamp as last update
  static Future<void> saveLastUpdateTimestamp() async {
    try {
      final now = DateTime.now().toIso8601String();
      await CasheNetwork.insertToCashe(key: _lastUpdateKey, value: now);
      print('[WEEKLY RECOMMENDATIONS] Saved last update: $now');
    } catch (e) {
      print('[WEEKLY RECOMMENDATIONS] Error saving timestamp: $e');
    }
  }

  /// Save recommended compound IDs to cache
  static Future<void> saveRecommendedIds(List<String> ids) async {
    try {
      final idsString = ids.join(',');
      await CasheNetwork.insertToCashe(key: _recommendedIdsKey, value: idsString);
      print('[WEEKLY RECOMMENDATIONS] Saved ${ids.length} recommended IDs');
    } catch (e) {
      print('[WEEKLY RECOMMENDATIONS] Error saving IDs: $e');
    }
  }

  /// Get saved recommended compound IDs from cache
  static Future<List<String>> getSavedRecommendedIds() async {
    try {
      final idsString = await CasheNetwork.getCasheDataAsync(key: _recommendedIdsKey);

      if (idsString.isEmpty) {
        return [];
      }

      return idsString.split(',');
    } catch (e) {
      print('[WEEKLY RECOMMENDATIONS] Error getting saved IDs: $e');
      return [];
    }
  }

  /// Clear saved recommendations (for testing or manual refresh)
  static Future<void> clearRecommendations() async {
    try {
      await CasheNetwork.insertToCashe(key: _lastUpdateKey, value: '');
      await CasheNetwork.insertToCashe(key: _recommendedIdsKey, value: '');
      print('[WEEKLY RECOMMENDATIONS] Cleared all recommendations');
    } catch (e) {
      print('[WEEKLY RECOMMENDATIONS] Error clearing: $e');
    }
  }

  /// Get days until next refresh
  static Future<int> getDaysUntilRefresh() async {
    try {
      final lastUpdateStr = await CasheNetwork.getCasheDataAsync(key: _lastUpdateKey);

      if (lastUpdateStr.isEmpty) {
        return 0;
      }

      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      final difference = now.difference(lastUpdate);
      final daysLeft = _daysInWeek - difference.inDays;

      return daysLeft > 0 ? daysLeft : 0;
    } catch (e) {
      print('[WEEKLY RECOMMENDATIONS] Error calculating days: $e');
      return 0;
    }
  }
}
