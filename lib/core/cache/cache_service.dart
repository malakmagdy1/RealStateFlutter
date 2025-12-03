import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Cache service for storing API responses locally
/// Reduces API calls and improves app startup time
class CacheService {
  static const String _compoundsBox = 'compounds_cache';
  static const String _companiesBox = 'companies_cache';
  static const String _unitsBox = 'units_cache';
  static const String _metadataBox = 'cache_metadata';

  static Box? _compoundsBoxInstance;
  static Box? _companiesBoxInstance;
  static Box? _unitsBoxInstance;
  static Box? _metadataBoxInstance;

  static bool _isInitialized = false;

  /// Cache expiry durations
  static const Duration compoundsCacheExpiry = Duration(hours: 6);
  static const Duration companiesCacheExpiry = Duration(hours: 12);
  static const Duration unitsCacheExpiry = Duration(hours: 3);

  /// Initialize Hive and open boxes
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      _compoundsBoxInstance = await Hive.openBox(_compoundsBox);
      _companiesBoxInstance = await Hive.openBox(_companiesBox);
      _unitsBoxInstance = await Hive.openBox(_unitsBox);
      _metadataBoxInstance = await Hive.openBox(_metadataBox);

      _isInitialized = true;
      print('[CACHE SERVICE] Initialized successfully');
    } catch (e) {
      print('[CACHE SERVICE] Error initializing: $e');
    }
  }

  /// Check if cache is valid based on key and expiry
  static bool isCacheValid(String key, Duration expiry) {
    if (_metadataBoxInstance == null) return false;

    final timestamp = _metadataBoxInstance!.get('${key}_timestamp');
    if (timestamp == null) return false;

    final cacheTime = DateTime.parse(timestamp);
    return DateTime.now().difference(cacheTime) < expiry;
  }

  /// Update cache timestamp
  static Future<void> _updateTimestamp(String key) async {
    await _metadataBoxInstance?.put(
      '${key}_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  // ===================== COMPOUNDS CACHE =====================

  /// Get cached compounds list
  static List<Map<String, dynamic>>? getCompounds({int? page}) {
    if (_compoundsBoxInstance == null) return null;

    final key = page != null ? 'compounds_page_$page' : 'compounds_all';
    if (!isCacheValid(key, compoundsCacheExpiry)) return null;

    final data = _compoundsBoxInstance!.get(key);
    if (data == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('[CACHE SERVICE] Error decoding compounds: $e');
      return null;
    }
  }

  /// Cache compounds list
  static Future<void> cacheCompounds(
    List<Map<String, dynamic>> compounds, {
    int? page,
  }) async {
    if (_compoundsBoxInstance == null) return;

    final key = page != null ? 'compounds_page_$page' : 'compounds_all';
    await _compoundsBoxInstance!.put(key, jsonEncode(compounds));
    await _updateTimestamp(key);
    print('[CACHE SERVICE] Cached ${compounds.length} compounds (key: $key)');
  }

  /// Get single compound by ID
  static Map<String, dynamic>? getCompound(int id) {
    if (_compoundsBoxInstance == null) return null;

    final key = 'compound_$id';
    if (!isCacheValid(key, compoundsCacheExpiry)) return null;

    final data = _compoundsBoxInstance!.get(key);
    if (data == null) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      print('[CACHE SERVICE] Error decoding compound $id: $e');
      return null;
    }
  }

  /// Cache single compound
  static Future<void> cacheCompound(int id, Map<String, dynamic> compound) async {
    if (_compoundsBoxInstance == null) return;

    final key = 'compound_$id';
    await _compoundsBoxInstance!.put(key, jsonEncode(compound));
    await _updateTimestamp(key);
  }

  // ===================== COMPANIES CACHE =====================

  /// Get cached companies list
  static List<Map<String, dynamic>>? getCompanies() {
    if (_companiesBoxInstance == null) return null;

    const key = 'companies_all';
    if (!isCacheValid(key, companiesCacheExpiry)) return null;

    final data = _companiesBoxInstance!.get(key);
    if (data == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('[CACHE SERVICE] Error decoding companies: $e');
      return null;
    }
  }

  /// Cache companies list
  static Future<void> cacheCompanies(List<Map<String, dynamic>> companies) async {
    if (_companiesBoxInstance == null) return;

    const key = 'companies_all';
    await _companiesBoxInstance!.put(key, jsonEncode(companies));
    await _updateTimestamp(key);
    print('[CACHE SERVICE] Cached ${companies.length} companies');
  }

  /// Get single company by ID
  static Map<String, dynamic>? getCompany(int id) {
    if (_companiesBoxInstance == null) return null;

    final key = 'company_$id';
    if (!isCacheValid(key, companiesCacheExpiry)) return null;

    final data = _companiesBoxInstance!.get(key);
    if (data == null) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      print('[CACHE SERVICE] Error decoding company $id: $e');
      return null;
    }
  }

  /// Cache single company
  static Future<void> cacheCompany(int id, Map<String, dynamic> company) async {
    if (_companiesBoxInstance == null) return;

    final key = 'company_$id';
    await _companiesBoxInstance!.put(key, jsonEncode(company));
    await _updateTimestamp(key);
  }

  // ===================== UNITS CACHE =====================

  /// Get cached units for a compound
  static List<Map<String, dynamic>>? getUnitsForCompound(int compoundId) {
    if (_unitsBoxInstance == null) return null;

    final key = 'units_compound_$compoundId';
    if (!isCacheValid(key, unitsCacheExpiry)) return null;

    final data = _unitsBoxInstance!.get(key);
    if (data == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('[CACHE SERVICE] Error decoding units for compound $compoundId: $e');
      return null;
    }
  }

  /// Cache units for a compound
  static Future<void> cacheUnitsForCompound(
    int compoundId,
    List<Map<String, dynamic>> units,
  ) async {
    if (_unitsBoxInstance == null) return;

    final key = 'units_compound_$compoundId';
    await _unitsBoxInstance!.put(key, jsonEncode(units));
    await _updateTimestamp(key);
    print('[CACHE SERVICE] Cached ${units.length} units for compound $compoundId');
  }

  /// Get single unit by ID
  static Map<String, dynamic>? getUnit(int id) {
    if (_unitsBoxInstance == null) return null;

    final key = 'unit_$id';
    if (!isCacheValid(key, unitsCacheExpiry)) return null;

    final data = _unitsBoxInstance!.get(key);
    if (data == null) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      print('[CACHE SERVICE] Error decoding unit $id: $e');
      return null;
    }
  }

  /// Cache single unit
  static Future<void> cacheUnit(int id, Map<String, dynamic> unit) async {
    if (_unitsBoxInstance == null) return;

    final key = 'unit_$id';
    await _unitsBoxInstance!.put(key, jsonEncode(unit));
    await _updateTimestamp(key);
  }

  // ===================== UTILITY METHODS =====================

  /// Clear all caches
  static Future<void> clearAll() async {
    await _compoundsBoxInstance?.clear();
    await _companiesBoxInstance?.clear();
    await _unitsBoxInstance?.clear();
    await _metadataBoxInstance?.clear();
    print('[CACHE SERVICE] All caches cleared');
  }

  /// Clear compounds cache
  static Future<void> clearCompounds() async {
    await _compoundsBoxInstance?.clear();
    // Clear related timestamps
    final keys = _metadataBoxInstance?.keys
        .where((k) => k.toString().startsWith('compounds'))
        .toList();
    for (final key in keys ?? []) {
      await _metadataBoxInstance?.delete(key);
    }
    print('[CACHE SERVICE] Compounds cache cleared');
  }

  /// Clear companies cache
  static Future<void> clearCompanies() async {
    await _companiesBoxInstance?.clear();
    final keys = _metadataBoxInstance?.keys
        .where((k) => k.toString().startsWith('compan'))
        .toList();
    for (final key in keys ?? []) {
      await _metadataBoxInstance?.delete(key);
    }
    print('[CACHE SERVICE] Companies cache cleared');
  }

  /// Clear units cache
  static Future<void> clearUnits() async {
    await _unitsBoxInstance?.clear();
    final keys = _metadataBoxInstance?.keys
        .where((k) => k.toString().startsWith('unit'))
        .toList();
    for (final key in keys ?? []) {
      await _metadataBoxInstance?.delete(key);
    }
    print('[CACHE SERVICE] Units cache cleared');
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'compounds_entries': _compoundsBoxInstance?.length ?? 0,
      'companies_entries': _companiesBoxInstance?.length ?? 0,
      'units_entries': _unitsBoxInstance?.length ?? 0,
      'is_initialized': _isInitialized,
    };
  }
}
