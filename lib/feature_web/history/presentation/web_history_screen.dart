import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/search/data/services/view_history_service.dart';
import 'package:real/feature_web/widgets/web_compound_card.dart';
import 'package:real/feature_web/widgets/web_unit_card.dart';
import 'package:real/l10n/app_localizations.dart';

class WebHistoryScreen extends StatefulWidget {
  WebHistoryScreen({Key? key}) : super(key: key);

  @override
  State<WebHistoryScreen> createState() => _WebHistoryScreenState();
}

class _WebHistoryScreenState extends State<WebHistoryScreen> {
  final ViewHistoryService _viewHistoryService = ViewHistoryService();
  List<Map<String, dynamic>> _historyItems = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, compounds, units
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'recent'; // recent, name, status

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
        title: Text('Clear History'),
        content: Text('Are you sure you want to clear all viewing history?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
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
          return (unit.unitNumber?.toLowerCase().contains(searchLower) ?? false) ||
                 unit.unitType.toLowerCase().contains(searchLower) ||
                 (unit.status?.toLowerCase().contains(searchLower) ?? false);
        }
      }).toList();
    }

    // Sort items
    if (_sortBy == 'name') {
      items.sort((a, b) {
        final aName = a['itemType'] == 'compound'
            ? (a['project'] as String? ?? '')
            : (a['unit_number'] as String? ?? '');
        final bName = b['itemType'] == 'compound'
            ? (b['project'] as String? ?? '')
            : (b['unit_number'] as String? ?? '');
        return aName.compareTo(bName);
      });
    } else if (_sortBy == 'status') {
      items.sort((a, b) {
        final aStatus = a['status'] as String? ?? '';
        final bStatus = b['status'] as String? ?? '';
        return aStatus.compareTo(bStatus);
      });
    }
    // 'recent' is already sorted by viewedAt in the service

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Color(0xFFF8F9FA),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32),
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 32,
                      color: AppColors.mainColor,
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Viewing History',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Spacer(),
                    if (_historyItems.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _clearAllHistory,
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        label: Text('Clear All', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Your recently viewed properties and compounds',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 24),

                // Search and Filters Row
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search in history...',
                          hintStyle: TextStyle(color: Color(0xFF999999)),
                          prefixIcon: Icon(Icons.search, color: AppColors.mainColor),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Color(0xFF999999)),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Color(0xFFE6E6E6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Color(0xFFE6E6E6)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Sort Dropdown
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xFFE6E6E6)),
                      ),
                      child: DropdownButton<String>(
                        value: _sortBy,
                        underline: SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: AppColors.mainColor),
                        items: [
                          DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(value: 'status', child: Text('Status')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortBy = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Filter tabs
                Row(
                  children: [
                    _buildFilterTab('all', 'All', _historyItems.length),
                    SizedBox(width: 12),
                    _buildFilterTab(
                      'compounds',
                      'Compounds',
                      _historyItems.where((i) => i['itemType'] == 'compound').length,
                    ),
                    SizedBox(width: 12),
                    _buildFilterTab(
                      'units',
                      'Units',
                      _historyItems.where((i) => i['itemType'] == 'unit').length,
                    ),
                  ],
                ),

                SizedBox(height: 24),

                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _filteredItems.isEmpty
                      ? _buildEmptyState()
                      : SingleChildScrollView(
                    child: _buildHistoryGrid(),
                  ),
                ),

              ],
            ),
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.mainColor : Color(0xFFE6E6E6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFF666666),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // prevent nested scroll
      padding: EdgeInsets.only(bottom: 50),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.9, // balanced card proportions
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];

        return AspectRatio(
          aspectRatio: 1.2, // enforce consistent height/width
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ✅ ensure card (and its background image) fills the stack
              Positioned.fill(
                child: item['itemType'] == 'compound'
                    ? WebCompoundCard(compound: Compound.fromJson(item))
                    : WebUnitCard(unit: Unit.fromJson(item)),
              ),

              // 🗑 delete button — top-right outside card
              Positioned(
                top: -6,
                right: -6,
                child: InkWell(
                  onTap: () => _removeItem(item),
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.close, color: Colors.red, size: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  String _getTimeAgo(String dateTimeString) {
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
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 24),
          Text(
            hasSearch
                ? 'No results found'
                : _filter == 'all'
                    ? 'No viewing history yet'
                    : _filter == 'compounds'
                        ? 'No compound views yet'
                        : 'No unit views yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 12),
          Text(
            hasSearch
                ? 'Try adjusting your search terms'
                : 'Properties you view will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF999999),
            ),
          ),
          if (hasSearch || hasFilter) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _filter = 'all';
                });
              },
              icon: Icon(Icons.clear_all),
              label: Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
