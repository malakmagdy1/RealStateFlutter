import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature_web/widgets/web_compound_card.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/search/data/models/search_filter_model.dart';
import 'package:real/feature/search/presentation/widget/search_filter_bottom_sheet.dart';

class WebCompoundsScreen extends StatefulWidget {
  const WebCompoundsScreen({Key? key}) : super(key: key);

  @override
  State<WebCompoundsScreen> createState() => _WebCompoundsScreenState();
}

class _WebCompoundsScreenState extends State<WebCompoundsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SearchFilter _currentFilter = SearchFilter.empty();
  List<Compound> _allCompounds = [];

  @override
  void initState() {
    super.initState();
    context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: 100));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Compound> get _filteredCompounds {
    var compounds = List<Compound>.from(_allCompounds);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      compounds = compounds.where((compound) {
        final searchLower = _searchQuery.toLowerCase();
        return compound.project.toLowerCase().contains(searchLower) ||
               compound.location.toLowerCase().contains(searchLower) ||
               compound.companyName.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Location filter from SearchFilter
    if (_currentFilter.location != null && _currentFilter.location!.isNotEmpty) {
      compounds = compounds.where((compound) =>
        compound.location.toLowerCase().contains(_currentFilter.location!.toLowerCase())
      ).toList();
    }

    // Status filter from SearchFilter
    if (_currentFilter.status != null && _currentFilter.status!.isNotEmpty) {
      compounds = compounds.where((compound) =>
        compound.status.toLowerCase() == _currentFilter.status!.toLowerCase()
      ).toList();
    }

    // Sort
    if (_currentFilter.sortBy != null) {
      if (_currentFilter.sortBy == 'date_desc') {
        // Most recent first (default)
      } else if (_currentFilter.sortBy == 'date_asc') {
        // Oldest first
        compounds = compounds.reversed.toList();
      }
    }

    return compounds;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _currentFilter = SearchFilter.empty();
    });
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterBottomSheet(
        initialFilter: _currentFilter,
        onApplyFilters: (filter) {
          setState(() {
            _currentFilter = filter;
          });
        },
      ),
    );
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
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.apartment,
                      size: 32,
                      color: AppColors.mainColor,
                    ),
                    SizedBox(width: 16),
                    Text(
                      l10n.compounds ?? 'Compounds',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Spacer(),
                    // Filter Button with badge
                    if (!_currentFilter.isEmpty)
                      Container(
                        margin: EdgeInsets.only(right: 16),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 16,
                              color: AppColors.mainColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${_currentFilter.activeFiltersCount} active',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.mainColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            InkWell(
                              onTap: _clearFilters,
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.mainColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: _openFilterBottomSheet,
                      icon: Icon(Icons.tune, size: 20),
                      label: Text('Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      '${_filteredCompounds.length} ${l10n.compounds ?? 'compounds'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Browse all available compounds',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 24),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search compounds...',
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

                SizedBox(height: 24),

                // Compounds Grid
                Expanded(
                  child: BlocBuilder<CompoundBloc, CompoundState>(
                    builder: (context, state) {
                      if (state is CompoundLoading) {
                        return Center(child: CircularProgressIndicator());
                      } else if (state is CompoundSuccess) {
                        _allCompounds = state.response.data;
                        final filtered = _filteredCompounds;

                        if (filtered.isEmpty) {
                          return _buildEmptyState();
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return WebCompoundCard(compound: filtered[index]);
                          },
                        );
                      } else if (state is CompoundError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                state.message,
                                style: TextStyle(fontSize: 16, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      }
                      return SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 24),
          Text(
            'No compounds found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF999999),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Clear Filters'),
          ),
        ],
      ),
    );
  }
}
