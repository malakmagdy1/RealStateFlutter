import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comparison_item.dart';

/// Service for managing comparison list (singleton)
class ComparisonListService extends ChangeNotifier {
  static final ComparisonListService _instance = ComparisonListService._internal();
  factory ComparisonListService() => _instance;
  ComparisonListService._internal() {
    _streamController = StreamController<List<ComparisonItem>>.broadcast();
    init();
  }

  static const String _storageKey = 'comparison_list';
  static const int _maxItems = 5;

  final List<ComparisonItem> _items = [];
  late final StreamController<List<ComparisonItem>> _streamController;

  List<ComparisonItem> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get canAddMore => _items.length < _maxItems;
  bool get isFull => _items.length >= _maxItems;

  /// Get items (alias for items getter)
  List<ComparisonItem> getItems() => items;

  /// Stream of comparison items for reactive UI
  Stream<List<ComparisonItem>> get comparisonStream => _streamController.stream;

  /// Get current items (for initialData in StreamBuilder)
  List<ComparisonItem> get currentItems => List.unmodifiable(_items);

  /// Initialize and load from storage
  Future<void> init() async {
    await _loadFromStorage();
  }

  /// Check if an item is in the list
  bool contains(String id, String type) {
    return _items.any((item) => item.id == id && item.type == type);
  }

  /// Check if a ComparisonItem is in the list
  bool containsItem(ComparisonItem item) {
    return contains(item.id, item.type);
  }

  /// Add item to comparison list (alias)
  Future<bool> addItem(ComparisonItem item) => add(item);

  /// Remove item from comparison list (alias)
  Future<void> removeItem(ComparisonItem item) => remove(item.id, item.type);

  /// Add item to comparison list
  Future<bool> add(ComparisonItem item) async {
    if (_items.length >= _maxItems) {
      return false;
    }

    if (contains(item.id, item.type)) {
      return false;
    }

    _items.add(item);
    await _saveToStorage();
    _notifyChanges();
    return true;
  }

  /// Remove item from comparison list
  Future<void> remove(String id, String type) async {
    _items.removeWhere((item) => item.id == id && item.type == type);
    await _saveToStorage();
    _notifyChanges();
  }

  /// Remove item by index
  Future<void> removeAt(int index) async {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      await _saveToStorage();
      _notifyChanges();
    }
  }

  /// Toggle item in comparison list
  Future<bool> toggle(ComparisonItem item) async {
    if (contains(item.id, item.type)) {
      await remove(item.id, item.type);
      return false;
    } else {
      return await add(item);
    }
  }

  /// Clear all items
  Future<void> clear() async {
    _items.clear();
    await _saveToStorage();
    _notifyChanges();
  }

  void _notifyChanges() {
    notifyListeners();
    _streamController.add(List.unmodifiable(_items));
  }

  /// Load from shared preferences
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List;
        _items.clear();
        _items.addAll(
          jsonList.map((json) => ComparisonItem.fromJson(json as Map<String, dynamic>)),
        );
        _notifyChanges();
      }
    } catch (e) {
      print('[ComparisonListService] Error loading: $e');
    }
  }

  /// Save to shared preferences
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _items.map((item) => item.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      print('[ComparisonListService] Error saving: $e');
    }
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }
}
