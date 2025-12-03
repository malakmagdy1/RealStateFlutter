import 'package:flutter/material.dart';
import 'package:real/core/animations/animated_list_item.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/presentation/widget/unit_card.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';
import 'package:real/feature/search/data/services/view_history_service.dart';
import 'package:real/l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ViewHistoryService _viewHistoryService = ViewHistoryService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _historyItems = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, compounds, units
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final items = await _viewHistoryService.getAllViewedItems();
    setState(() {
      _historyItems = items;
      _isLoading = false;
    });
  }

  Future<void> _clearAllHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: CustomText18(l10n.clearHistory, bold: true),
        content: Text(l10n.confirmClearHistory),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clear, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _viewHistoryService.clearAllHistory();
      _loadHistory();
    }
  }

  Future<void> _removeItem(Map<String, dynamic> item) async {
    if (item['itemType'] == 'compound') {
      await _viewHistoryService.removeCompound(item['id'] as int);
    } else {
      await _viewHistoryService.removeUnit(item['id'] as int);
    }
    _loadHistory();
  }

  List<Map<String, dynamic>> get _filteredItems {
    var items = _historyItems;

    // Filter by type
    if (_filter == 'compounds') {
      items = items.where((item) => item['itemType'] == 'compound').toList();
    } else if (_filter == 'units') {
      items = items.where((item) => item['itemType'] == 'unit').toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final searchLower = _searchQuery.toLowerCase();

        if (item['itemType'] == 'compound') {
          final compound = Compound.fromJson(item);
          return compound.project.toLowerCase().contains(searchLower) ||
                 compound.location.toLowerCase().contains(searchLower) ||
                 compound.companyName.toLowerCase().contains(searchLower);
        } else {
          final unit = Unit.fromJson(item);
          return (unit.unitNumber != null && unit.unitNumber!.toLowerCase().contains(searchLower)) ||
                 unit.unitType.toLowerCase().contains(searchLower) ||
                 unit.status.toLowerCase().contains(searchLower);
        }
      }).toList();
    }

    return items;
  }

  String _getTimeAgo(String dateTimeString, AppLocalizations l10n) {
    try {
      final viewedAt = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(viewedAt);

      if (difference.inMinutes < 1) {
        return l10n.justNow;
      } else if (difference.inHours < 1) {
        return l10n.minutesAgo(difference.inMinutes);
      } else if (difference.inDays < 1) {
        return l10n.hoursAgo(difference.inHours);
      } else if (difference.inDays < 7) {
        return l10n.daysAgo(difference.inDays);
      } else {
        return l10n.weeksAgo((difference.inDays / 7).floor());
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText24(l10n.viewHistory, bold: true, color: AppColors.black),
                  if (_historyItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearAllHistory,
                      icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      label: CustomText14(l10n.clearAll, color: Colors.red),
                    ),
                ],
              ),
              SizedBox(height: 8),
              CustomText14(l10n.recentlyViewedProperties, color: AppColors.greyText),
              SizedBox(height: 16),

              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: l10n.searchInHistory,
                  hintStyle: TextStyle(color: AppColors.greyText),
                  prefixIcon: Icon(Icons.search, color: AppColors.greyText),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.greyText),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Filter tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterTab('all', l10n.all, _historyItems.length),
                    SizedBox(width: 8),
                    _buildFilterTab(
                      'compounds',
                      l10n.compounds,
                      _historyItems.where((i) => i['itemType'] == 'compound').length,
                    ),
                    SizedBox(width: 8),
                    _buildFilterTab(
                      'units',
                      l10n.units,
                      _historyItems.where((i) => i['itemType'] == 'unit').length,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // History list
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _filteredItems.isEmpty
                        ? _buildEmptyState()
                        : _buildHistoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String value, String label, int count) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final hasSearch = _searchQuery.isNotEmpty;
    final hasFilter = _filter != 'all';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.history,
            size: 64,
            color: AppColors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          CustomText20(
            hasSearch
                ? l10n.noResults
                : _filter == 'all'
                    ? l10n.noViewingHistoryYet
                    : _filter == 'compounds'
                        ? l10n.noCompoundViewsYet
                        : l10n.noUnitViewsYet,
            bold: true,
            color: AppColors.grey,
          ),
          SizedBox(height: 8),
          CustomText14(
            hasSearch
                ? l10n.tryAdjustingYourSearch
                : l10n.propertiesYouViewWillAppearHere,
            color: AppColors.greyText,
          ),
          if (hasSearch || hasFilter) ...[
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _filter = 'all';
                });
              },
              icon: Icon(Icons.clear_all, size: 18),
              label: Text(l10n.clearFilters),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final double iconSize = 16.0; // Fixed icon size
    final double buttonSize = 32.0; // Fixed button size

    return GridView.builder(
      padding: const EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: 120, // Extra space at bottom for AI button and card visibility
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.63,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final viewedAt = item['viewedAt'] as String?;

        if (item['itemType'] == 'compound') {
          final compound = Compound.fromJson(item);
          return AnimatedListItem(
            index: index,
            delay: Duration(milliseconds: 50),
            child: Stack(
              children: [
                CompoundsName(compound: compound),
                // Time badge overlay - positioned on image area (top-left, below action buttons)
              if (viewedAt != null)
                Positioned(
                  top: 55, // Position below the top action buttons
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _getTimeAgo(viewedAt, l10n),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Remove button - positioned at top right
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeItem({'itemType': 'compound', 'id': int.tryParse(compound.id.toString()) ?? 0}),
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.red,
                      size: iconSize,
                    ),
                  ),
                ),
              ),
              ],
            ),
          );
        } else {
          final unit = Unit.fromJson(item);
          return AnimatedListItem(
            index: index,
            delay: Duration(milliseconds: 50),
            child: Stack(
              children: [
                UnitCard(unit: unit),
                // Time badge overlay - positioned on image area (top-left, below action buttons)
              if (viewedAt != null)
                Positioned(
                  top: 55, // Position below the top action buttons
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _getTimeAgo(viewedAt, l10n),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Remove button for unit - positioned at top right
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeItem({'itemType': 'unit', 'id': int.tryParse(unit.id.toString()) ?? 0}),
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.red,
                      size: iconSize,
                    ),
                  ),
                ),
              ),
              ],
            ),
          );
        }
      },
    );
  }

}