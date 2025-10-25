import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/core/utils/constant.dart';

class ViewHistoryService {
  static const String _baseCompoundsKey = 'viewed_compounds_history';
  static const String _baseUnitsKey = 'viewed_units_history';
  static const int _maxHistoryItems = 50;

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

  // Clear all history
  Future<void> clearAllHistory() async {
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
