import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:real/feature/ai_chat/domain/config.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';

/// AI-powered weekly recommendations service using Gemini
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

  /// Use Gemini AI to intelligently select recommended compounds
  static Future<List<String>> generateAIRecommendations(List<Compound> allCompounds) async {
    try {
      print('[AI WEEKLY RECOMMENDATIONS] Starting AI-powered selection from ${allCompounds.length} compounds');

      if (allCompounds.isEmpty) {
        return [];
      }

      // If we have 10 or fewer compounds, return all of them
      if (allCompounds.length <= _recommendationCount) {
        return allCompounds.map((c) => c.id.toString()).toList();
      }

      // Prepare compound data for AI analysis
      final compoundsJson = allCompounds.map((compound) {
        return {
          'id': compound.id,
          'project': compound.project,
          'location': compound.location,
          'company': compound.companyName,
          'total_units': compound.totalUnits,
          'available_units': compound.availableUnits,
          'status': compound.status,
          'images_count': compound.images.length,
          'has_club': compound.club == '1' || compound.club.toLowerCase() == 'yes',
          'finish_specs': compound.finishSpecs ?? 'N/A',
        };
      }).toList();

      final model = GenerativeModel(
        model: AppConfig.geminiModel,
        apiKey: AppConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.8, // Higher temperature for more variety
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1000,
        ),
      );

      // Create a prompt for the AI to select diverse and interesting compounds
      final prompt = '''
You are a real estate recommendation expert. Your task is to select exactly $_recommendationCount diverse and interesting compounds from the following list.

Selection Criteria:
1. Choose compounds with diverse locations to provide geographical variety
2. Select compounds from different companies to avoid bias
3. Prefer compounds with multiple images and good finish specifications
4. Consider compounds with clubs/amenities for better appeal
5. Mix of different statuses and unit availability
6. Pick compounds that would appeal to different buyer personas

Available Compounds (${allCompounds.length} total):
${jsonEncode(compoundsJson)}

IMPORTANT: Respond with ONLY a JSON array of exactly $_recommendationCount compound IDs. No explanations, no extra text.
Format: [id1, id2, id3, ...]

Example response: [1, 5, 12, 23, 34, 45, 56, 67, 78, 89]
''';

      print('[AI WEEKLY RECOMMENDATIONS] Sending request to Gemini AI...');

      // Get AI response
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        print('[AI WEEKLY RECOMMENDATIONS] AI returned empty response, falling back to random selection');
        return _fallbackRandomSelection(allCompounds);
      }

      // Parse AI response
      final responseText = response.text!.trim();
      print('[AI WEEKLY RECOMMENDATIONS] AI response: $responseText');

      // Try to extract JSON array from response
      final jsonMatch = RegExp(r'\[[\d,\s]+\]').firstMatch(responseText);
      if (jsonMatch == null) {
        print('[AI WEEKLY RECOMMENDATIONS] Could not parse AI response, falling back to random selection');
        return _fallbackRandomSelection(allCompounds);
      }

      final jsonArray = jsonDecode(jsonMatch.group(0)!) as List<dynamic>;
      final selectedIds = jsonArray.map((id) => id.toString()).toList();

      // Validate that all IDs exist in our compound list
      final validIds = <String>[];
      final compoundIdsSet = allCompounds.map((c) => c.id.toString()).toSet();

      for (final id in selectedIds) {
        if (compoundIdsSet.contains(id)) {
          validIds.add(id);
        }
      }

      // If we don't have enough valid IDs, fill with random selection
      if (validIds.length < _recommendationCount) {
        print('[AI WEEKLY RECOMMENDATIONS] AI returned ${validIds.length} valid IDs, filling remaining with random selection');
        final remaining = _recommendationCount - validIds.length;
        final availableCompounds = allCompounds
            .where((c) => !validIds.contains(c.id.toString()))
            .toList();
        availableCompounds.shuffle();
        validIds.addAll(
          availableCompounds
              .take(remaining)
              .map((c) => c.id.toString())
        );
      }

      print('[AI WEEKLY RECOMMENDATIONS] AI selected ${validIds.length} compounds');
      return validIds.take(_recommendationCount).toList();

    } catch (e) {
      print('[AI WEEKLY RECOMMENDATIONS] Error using AI: $e');
      print('[AI WEEKLY RECOMMENDATIONS] Falling back to random selection');
      return _fallbackRandomSelection(allCompounds);
    }
  }

  /// Fallback to random selection if AI fails
  static List<String> _fallbackRandomSelection(List<Compound> allCompounds) {
    final shuffled = List<Compound>.from(allCompounds)..shuffle();
    return shuffled
        .take(_recommendationCount)
        .map((c) => c.id.toString())
        .toList();
  }
}
