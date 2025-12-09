import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';

/// Weekly recommendations service
/// Note: AI processing moved to backend for security
class AIWeeklyRecommendationsService {
  static const String _lastUpdateKey = 'ai_weekly_recommendations_last_update';
  static const String _recommendedIdsKey = 'ai_weekly_recommended_compound_ids';
  static const int _daysInWeek = 7;
  static const int _recommendationCount = 10;

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
      print('[AI WEEKLY RECOMMENDATIONS] Error checking last update: $e');
      return true; // On error, refresh
    }
  }

  /// Save the current timestamp as last update
  static Future<void> saveLastUpdateTimestamp() async {
    try {
      final now = DateTime.now().toIso8601String();
      await CasheNetwork.insertToCashe(key: _lastUpdateKey, value: now);
      print('[AI WEEKLY RECOMMENDATIONS] Saved last update: $now');
    } catch (e) {
      print('[AI WEEKLY RECOMMENDATIONS] Error saving timestamp: $e');
    }
  }

  /// Save recommended compound IDs to cache
  static Future<void> saveRecommendedIds(List<String> ids) async {
    try {
      final idsString = ids.join(',');
      await CasheNetwork.insertToCashe(key: _recommendedIdsKey, value: idsString);
      print('[AI WEEKLY RECOMMENDATIONS] Saved ${ids.length} recommended IDs');
    } catch (e) {
      print('[AI WEEKLY RECOMMENDATIONS] Error saving IDs: $e');
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
      print('[AI WEEKLY RECOMMENDATIONS] Error getting saved IDs: $e');
      return [];
    }
  }

  /// Clear saved recommendations (for testing or manual refresh)
  static Future<void> clearRecommendations() async {
    try {
      await CasheNetwork.insertToCashe(key: _lastUpdateKey, value: '');
      await CasheNetwork.insertToCashe(key: _recommendedIdsKey, value: '');
      print('[AI WEEKLY RECOMMENDATIONS] Cleared all recommendations');
    } catch (e) {
      print('[AI WEEKLY RECOMMENDATIONS] Error clearing: $e');
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
      print('[AI WEEKLY RECOMMENDATIONS] Error calculating days: $e');
      return 0;
    }
  }

  /// Generate recommendations using smart selection
  /// Note: Full AI processing should be done on backend
  static Future<List<String>> generateAIRecommendations(List<Compound> allCompounds) async {
    try {
      print('[AI WEEKLY RECOMMENDATIONS] Starting selection from ${allCompounds.length} compounds');

      if (allCompounds.isEmpty) {
        return [];
      }

      // If we have 10 or fewer compounds, return all of them
      if (allCompounds.length <= _recommendationCount) {
        return allCompounds.map((c) => c.id.toString()).toList();
      }

      // Smart selection based on compound attributes
      return _smartSelection(allCompounds);
    } catch (e) {
      print('[AI WEEKLY RECOMMENDATIONS] Error: $e');
      return _fallbackRandomSelection(allCompounds);
    }
  }

  /// Smart selection based on compound attributes
  static List<String> _smartSelection(List<Compound> allCompounds) {
    // Score each compound
    final scoredCompounds = allCompounds.map((compound) {
      int score = 0;

      // Prefer compounds with images
      if (compound.images.isNotEmpty) score += 3;

      // Prefer compounds with available units
      final availableUnits = int.tryParse(compound.availableUnits) ?? 0;
      if (availableUnits > 0) score += 2;

      // Prefer compounds with club/amenities
      if (compound.club == '1' || compound.club.toLowerCase() == 'yes') {
        score += 1;
      }

      // Prefer compounds with finish specs
      if (compound.finishSpecs != null && compound.finishSpecs!.isNotEmpty) {
        score += 1;
      }

      return {'compound': compound, 'score': score};
    }).toList();

    // Sort by score descending
    scoredCompounds.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // Take top scored, but also add some randomness for variety
    final topScored = scoredCompounds.take(_recommendationCount ~/ 2).toList();
    final remaining = scoredCompounds.skip(_recommendationCount ~/ 2).toList();
    remaining.shuffle();

    final selected = <String>[];

    // Add top scored
    for (var item in topScored) {
      selected.add((item['compound'] as Compound).id.toString());
    }

    // Add random from remaining
    for (var item in remaining.take(_recommendationCount - selected.length)) {
      selected.add((item['compound'] as Compound).id.toString());
    }

    print('[AI WEEKLY RECOMMENDATIONS] Selected ${selected.length} compounds');
    return selected;
  }

  /// Fallback to random selection
  static List<String> _fallbackRandomSelection(List<Compound> allCompounds) {
    final shuffled = List<Compound>.from(allCompounds)..shuffle();
    return shuffled
        .take(_recommendationCount)
        .map((c) => c.id.toString())
        .toList();
  }
}
