import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/presentation/screen/unit_detail_screen.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/home/presentation/CompoundScreen.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import 'package:real/feature/search/data/services/view_history_service.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: CustomText18('Clear History', bold: true),
        content: Text('Are you sure you want to clear all viewing history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: TextStyle(color: Colors.red)),
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

  String _getTimeAgo(String dateTimeString) {
    try {
      final viewedAt = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(viewedAt);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${(difference.inDays / 7).floor()}w ago';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText24("View History", bold: true, color: AppColors.black),
                  if (_historyItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearAllHistory,
                      icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      label: CustomText14('Clear All', color: Colors.red),
                    ),
                ],
              ),
              SizedBox(height: 8),
              CustomText14('Recently viewed properties', color: AppColors.greyText),
              SizedBox(height: 16),

              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: "Search in history...",
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
                    _buildFilterTab('all', 'All', _historyItems.length),
                    SizedBox(width: 8),
                    _buildFilterTab(
                      'compounds',
                      'Compounds',
                      _historyItems.where((i) => i['itemType'] == 'compound').length,
                    ),
                    SizedBox(width: 8),
                    _buildFilterTab(
                      'units',
                      'Units',
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
                ? 'No results found'
                : _filter == 'all'
                    ? 'No viewing history yet'
                    : _filter == 'compounds'
                        ? 'No compound views yet'
                        : 'No unit views yet',
            bold: true,
            color: AppColors.grey,
          ),
          SizedBox(height: 8),
          CustomText14(
            hasSearch
                ? 'Try adjusting your search'
                : 'Properties you view will appear here',
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
              label: Text('Clear Filters'),
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
    return ListView.builder(
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final viewedAt = item['viewedAt'] as String?;

        if (item['itemType'] == 'compound') {
          return _buildCompoundHistoryItem(Compound.fromJson(item), viewedAt);
        } else {
          return _buildUnitHistoryItem(Unit.fromJson(item), viewedAt);
        }
      },
    );
  }

  Widget _buildCompoundHistoryItem(Compound compound, String? viewedAt) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompoundScreen(compound: compound),
            ),
          );
        },
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: compound.images.isNotEmpty
                        ? Image.network(
                            compound.images.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.apartment,
                                  size: 30, color: AppColors.greyText),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: Icon(Icons.apartment,
                                size: 30, color: AppColors.greyText),
                          ),
                  ),
                  SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.apartment,
                                size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'COMPOUND',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          compound.project,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: AppColors.greyText),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                compound.location,
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.greyText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        if (viewedAt != null)
                          Text(
                            'Viewed ${_getTimeAgo(viewedAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.mainColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 20, color: AppColors.greyText),
                ],
              ),
            ),
            // Remove button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeItem({'itemType': 'compound', 'id': compound.id}),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitHistoryItem(Unit unit, String? viewedAt) {
    Color getStatusColor() {
      final status = unit.status.toLowerCase();
      switch (status) {
        case 'available':
          return Colors.green;
        case 'reserved':
          return Colors.orange;
        case 'sold':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UnitDetailScreen(unit: unit),
            ),
          );
        },
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with favorite button
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: unit.images.isNotEmpty
                            ? Image.network(
                                unit.images.first,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.home,
                                      size: 30, color: AppColors.greyText),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: Icon(Icons.home,
                                    size: 30, color: AppColors.greyText),
                              ),
                      ),
                      // Favorite Button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: BlocBuilder<UnitFavoriteBloc, UnitFavoriteState>(
                          builder: (context, state) {
                            final bloc = context.read<UnitFavoriteBloc>();
                            final isFavorite = bloc.isFavorite(unit);

                            return GestureDetector(
                              onTap: () => bloc.toggleFavorite(unit),
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type badge and Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.home, size: 14, color: Colors.orange),
                                SizedBox(width: 4),
                                Text(
                                  'UNIT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: getStatusColor(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unit.status.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        // Unit number
                        Text(
                          unit.unitNumber ?? unit.unitType,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        // Details Row
                        Row(
                          children: [
                            if (unit.usageType != null) ...[
                              Icon(Icons.category,
                                  size: 12, color: AppColors.greyText),
                              SizedBox(width: 4),
                              Text(
                                unit.usageType!,
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.greyText),
                              ),
                              SizedBox(width: 8),
                            ],
                            if (unit.bedrooms != '0') ...[
                              Icon(Icons.bed,
                                  size: 12, color: AppColors.greyText),
                              SizedBox(width: 4),
                              Text(
                                '${unit.bedrooms} Beds',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.greyText),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        // Price
                        Text(
                          'EGP ${unit.price}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainColor,
                          ),
                        ),
                        if (viewedAt != null) ...[
                          SizedBox(height: 4),
                          Text(
                            'Viewed ${_getTimeAgo(viewedAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.mainColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 20, color: AppColors.greyText),
                ],
              ),
            ),
            // Remove button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeItem({'itemType': 'unit', 'id': unit.id}),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}