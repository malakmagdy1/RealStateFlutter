import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/real_estate_product.dart';

/// Service for managing AI recommendations
class AIRecommendationsService {
  static const String _recommendationsKey = 'ai_recommendations';
  static const int _maxRecommendations = 50; // Increased from 10 to 50

  /// Save a recommendation
  Future<void> saveRecommendation(RealEstateProduct product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recommendations = await getRecommendations();

      // Add new recommendation at the beginning
      recommendations.insert(0, product);

      // Keep only the last N recommendations
      final trimmedList = recommendations.length > _maxRecommendations
          ? recommendations.sublist(0, _maxRecommendations)
          : recommendations;

      final jsonList = trimmedList.map((p) => p.toJson()).toList();
      await prefs.setString(_recommendationsKey, jsonEncode(jsonList));
    } catch (e) {
      print('Failed to save recommendation: $e');
    }
  }

  /// Get all recommendations
  Future<List<RealEstateProduct>> getRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recommendationsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => RealEstateProduct.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Failed to load recommendations: $e');
      return [];
    }
  }

  /// Clear all recommendations
  Future<void> clearRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recommendationsKey);
    } catch (e) {
      print('Failed to clear recommendations: $e');
    }
  }
}
