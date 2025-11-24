import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../models/comparison_item.dart';

/// 🛒 Global Comparison List Service
/// Manages a persistent list of items selected for comparison
/// Works across the entire app - items can be added from anywhere
class ComparisonListService extends ChangeNotifier {
  // Singleton pattern
  static final ComparisonListService _instance = ComparisonListService._internal();
  factory ComparisonListService() => _instance;
  ComparisonListService._internal();

  // The comparison list (max 4 items)
  final List<ComparisonItem> _items = [];

  // Stream for reactive updates
  final _comparisonStreamController = BehaviorSubject<List<ComparisonItem>>.seeded([]);

  /// Get stream of comparison items
  Stream<List<ComparisonItem>> get comparisonStream => _comparisonStreamController.stream;

  // Getters
  List<ComparisonItem> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get isFull => _items.length >= 4;
  bool get canCompare => _items.length >= 2;

  /// Add item to comparison list
  /// Returns true if added successfully, false if already exists or list is full
  bool addItem(ComparisonItem item) {
    // Check if already exists
    if (_items.any((i) => i.id == item.id && i.type == item.type)) {
      print('[COMPARISON LIST] ⚠️ Item already in list: ${item.name}');
      return false;
    }

    // Check if full
    if (_items.length >= 4) {
      print('[COMPARISON LIST] ⚠️ List is full (max 4 items)');
      return false;
    }

    // Add item
    _items.add(item);
    print('[COMPARISON LIST] ✅ Added: ${item.name} (${item.type}) - Total: ${_items.length}');
    _comparisonStreamController.add(List.from(_items));
    notifyListeners();
    return true;
  }

  /// Remove item from comparison list
  void removeItem(ComparisonItem item) {
    final lengthBefore = _items.length;
    _items.removeWhere((i) => i.id == item.id && i.type == item.type);
    if (_items.length < lengthBefore) {
      print('[COMPARISON LIST] ❌ Removed: ${item.name} - Total: ${_items.length}');
      _comparisonStreamController.add(List.from(_items));
      notifyListeners();
    }
  }

  /// Remove item by index
  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      final item = _items.removeAt(index);
      print('[COMPARISON LIST] ❌ Removed at index $index: ${item.name} - Total: ${_items.length}');
      _comparisonStreamController.add(List.from(_items));
      notifyListeners();
    }
  }

  /// Check if item is in the list
  bool contains(ComparisonItem item) {
    return _items.any((i) => i.id == item.id && i.type == item.type);
  }

  /// Clear all items
  void clear() {
    _items.clear();
    print('[COMPARISON LIST] 🗑️ Cleared all items');
    _comparisonStreamController.add(List.from(_items));
    notifyListeners();
  }

  /// Get all items and clear the list (used when sending to AI)
  List<ComparisonItem> getAndClear() {
    final itemsCopy = List<ComparisonItem>.from(_items);
    _items.clear();
    print('[COMPARISON LIST] 📤 Sent ${itemsCopy.length} items to AI and cleared list');
    _comparisonStreamController.add(List.from(_items));
    notifyListeners();
    return itemsCopy;
  }

  /// Get items without clearing
  List<ComparisonItem> getItems() {
    return List<ComparisonItem>.from(_items);
  }

  /// Get summary text for display
  String getSummary() {
    if (_items.isEmpty) return 'No items selected';

    final counts = <String, int>{};
    for (var item in _items) {
      counts[item.type] = (counts[item.type] ?? 0) + 1;
    }

    final parts = <String>[];
    if (counts['unit'] != null) parts.add('${counts['unit']} unit${counts['unit']! > 1 ? 's' : ''}');
    if (counts['compound'] != null) parts.add('${counts['compound']} compound${counts['compound']! > 1 ? 's' : ''}');
    if (counts['company'] != null) parts.add('${counts['company']} compan${counts['company']! > 1 ? 'ies' : 'y'}');

    return parts.join(', ');
  }

  @override
  void dispose() {
    _comparisonStreamController.close();
    super.dispose();
  }
}
