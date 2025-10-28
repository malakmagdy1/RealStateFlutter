import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/feature/search/data/web_services/history_web_services.dart';

class ViewHistoryService {
  static const String _baseCompoundsKey = 'viewed_compounds_history';
  static const String _baseUnitsKey = 'viewed_units_history';
  static const int _maxHistoryItems = 50;

  final HistoryWebServices _historyWebServices = HistoryWebServices();

  // Get user-specific keys based on token
  String get _compoundsKey {
    if (token != null && token!.isNotEmpty) {
      final tokenHash = token!.length > 20 ? token!.substring(0, 20) : token!;
      return '${_baseCompoundsKey}_$tokenHash';
    }
    return _baseCompoundsKey;
  }

  String get _unitsKey {
    if (token != null && token!.isNotEmpty) {
      final tokenHash = token!.length > 20 ? token!.substring(0, 20) : token!;
      return '${_baseUnitsKey}_$tokenHash';
    }
    return _baseUnitsKey;
  }

  // Save viewed compound
  Future<void> addViewedCompound(Compound compound) async {
    try {
      // Save to backend
      await _historyWebServices.addToHistory(
        actionType: 'view_compound',
        compoundId: int.parse(compound.id),
      );
    } catch (e) {
      print('[VIEW HISTORY] Error saving compound to backend: $e');
    }

    // Also save locally as cache
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_compoundsKey) ?? '[]';
    final List<dynamic> history = json.decode(historyJson);

    // Remove if already exists (to move to top)
    history.removeWhere((item) => item['id'] == compound.id);

    // Add to beginning with timestamp
    history.insert(0, {
      ...compound.toJson(),
      'viewedAt': DateTime.now().toIso8601String(),
    });

    // Keep only last N items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    await prefs.setString(_compoundsKey, json.encode(history));
  }

  // Save viewed unit
  Future<void> addViewedUnit(Unit unit) async {
    try {
      // Save to backend
      await _historyWebServices.addToHistory(
        actionType: 'view_unit',
        unitId: int.parse(unit.id),
      );
    } catch (e) {
      print('[VIEW HISTORY] Error saving unit to backend: $e');
    }

    // Also save locally as cache
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_unitsKey) ?? '[]';
    final List<dynamic> history = json.decode(historyJson);

    // Remove if already exists (to move to top)
    history.removeWhere((item) => item['id'] == unit.id);

    // Add to beginning with timestamp
    history.insert(0, {
      ...unit.toJson(),
      'viewedAt': DateTime.now().toIso8601String(),
    });

    // Keep only last N items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    await prefs.setString(_unitsKey, json.encode(history));
  }

  // Get viewed compounds
  Future<List<Map<String, dynamic>>> getViewedCompounds() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_compoundsKey) ?? '[]';
    final List<dynamic> history = json.decode(historyJson);
    return history.cast<Map<String, dynamic>>();
  }

  // Get viewed units
  Future<List<Map<String, dynamic>>> getViewedUnits() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_unitsKey) ?? '[]';
    final List<dynamic> history = json.decode(historyJson);
    return history.cast<Map<String, dynamic>>();
  }

  // Get all viewed items sorted by time
  Future<List<Map<String, dynamic>>> getAllViewedItems() async {
    try {
      // Try to fetch from backend first
      final response = await _historyWebServices.getHistory();

      if (response['success'] == true && response['data'] != null && response['data']['history'] != null) {
        final List<dynamic> historyData = response['data']['history'];
        final allItems = <Map<String, dynamic>>[];

        for (var item in historyData) {
          final Map<String, dynamic> historyItem = item as Map<String, dynamic>;

          // Determine item type and add to list
          if (historyItem['unit'] != null) {
            final unitData = historyItem['unit'] as Map<String, dynamic>;
            allItems.add({
              ...unitData,
              'itemType': 'unit',
              'viewedAt': historyItem['created_at'] ?? DateTime.now().toIso8601String(),
            });
          } else if (historyItem['compound'] != null) {
            final compoundData = historyItem['compound'] as Map<String, dynamic>;
            allItems.add({
              ...compoundData,
              'itemType': 'compound',
              'viewedAt': historyItem['created_at'] ?? DateTime.now().toIso8601String(),
            });
          }
        }

        // Update local cache
        _updateLocalCache(allItems);

        return allItems;
      }
    } catch (e) {
      print('[VIEW HISTORY] Error fetching from backend, using local cache: $e');
    }

    // Fallback to local storage
    final compounds = await getViewedCompounds();
    final units = await getViewedUnits();

    // Combine and mark type
    final allItems = <Map<String, dynamic>>[];

    for (var compound in compounds) {
      allItems.add({...compound, 'itemType': 'compound'});
    }

    for (var unit in units) {
      allItems.add({...unit, 'itemType': 'unit'});
    }

    // Sort by viewedAt timestamp
    allItems.sort((a, b) {
      final aTime = DateTime.parse(a['viewedAt'] as String);
      final bTime = DateTime.parse(b['viewedAt'] as String);
      return bTime.compareTo(aTime); // Most recent first
    });

    return allItems;
  }

  // Helper method to update local cache
  Future<void> _updateLocalCache(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();

    final compounds = items.where((i) => i['itemType'] == 'compound').toList();
    final units = items.where((i) => i['itemType'] == 'unit').toList();

    await prefs.setString(_compoundsKey, json.encode(compounds));
    await prefs.setString(_unitsKey, json.encode(units));
  }

  // Clear all history
  Future<void> clearAllHistory() async {
    try {
      // Clear from backend
      await _historyWebServices.clearAllHistory();
    } catch (e) {
      print('[VIEW HISTORY] Error clearing history from backend: $e');
    }

    // Also clear local cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_compoundsKey);
    await prefs.remove(_unitsKey);
  }

  // Remove specific compound from history
  Future<void> removeCompound(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_compoundsKey) ?? '[]';
    final List<dynamic> history = json.decode(historyJson);

    history.removeWhere((item) => item['id'] == id);

    await prefs.setString(_compoundsKey, json.encode(history));
  }

  // Remove specific unit from history
  Future<void> removeUnit(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_unitsKey) ?? '[]';
    final List<dynamic> history = json.decode(historyJson);

    history.removeWhere((item) => item['id'] == id);

    await prefs.setString(_unitsKey, json.encode(history));
  }
}
