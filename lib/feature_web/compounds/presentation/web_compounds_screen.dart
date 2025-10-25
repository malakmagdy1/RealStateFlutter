import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature_web/widgets/web_compound_card.dart';
import 'package:real/l10n/app_localizations.dart';

class WebCompoundsScreen extends StatefulWidget {
  const WebCompoundsScreen({Key? key}) : super(key: key);

  @override
  State<WebCompoundsScreen> createState() => _WebCompoundsScreenState();
}

class _WebCompoundsScreenState extends State<WebCompoundsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedLocation = 'all';
  String _sortBy = 'recent';
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

    // Status filter
    if (_selectedStatus != 'all') {
      compounds = compounds.where((compound) =>
        compound.status.toLowerCase() == _selectedStatus.toLowerCase()
      ).toList();
    }

    // Location filter
    if (_selectedLocation != 'all') {
      compounds = compounds.where((compound) =>
        compound.location.toLowerCase().contains(_selectedLocation.toLowerCase())
      ).toList();
    }

    // Sort
    if (_sortBy == 'name') {
      compounds.sort((a, b) => a.project.compareTo(b.project));
    } else if (_sortBy == 'location') {
      compounds.sort((a, b) => a.location.compareTo(b.location));
    } else if (_sortBy == 'units') {
      compounds.sort((a, b) {
        final aUnits = int.tryParse(b.totalUnits) ?? 0;
        final bUnits = int.tryParse(a.totalUnits) ?? 0;
        return aUnits.compareTo(bUnits);
      });
    }

    return compounds;
  }

  Set<String> get _availableLocations {
    final locations = _allCompounds.map((c) => c.location).toSet();
    return locations;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedStatus = 'all';
      _selectedLocation = 'all';
      _sortBy = 'recent';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Color(0xFFF8F9FA),
      child: Row(
        children: [
          // Main Content Area
          Expanded(
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
          ),

          // Filter Sidebar
          Container(
            width: 320,
            color: Colors.white,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                        TextButton(
                          onPressed: _clearFilters,
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: AppColors.mainColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Sort By
                    _buildFilterSection(
                      'Sort By',
                      Column(
                        children: [
                          _buildRadioOption('recent', 'Most Recent', _sortBy, (value) {
                            setState(() => _sortBy = value);
                          }),
                          _buildRadioOption('name', 'Name (A-Z)', _sortBy, (value) {
                            setState(() => _sortBy = value);
                          }),
                          _buildRadioOption('location', 'Location', _sortBy, (value) {
                            setState(() => _sortBy = value);
                          }),
                          _buildRadioOption('units', 'Most Units', _sortBy, (value) {
                            setState(() => _sortBy = value);
                          }),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),
                    Divider(),
                    SizedBox(height: 24),

                    // Status Filter
                    _buildFilterSection(
                      'Status',
                      Column(
                        children: [
                          _buildRadioOption('all', 'All Status', _selectedStatus, (value) {
                            setState(() => _selectedStatus = value);
                          }),
                          _buildRadioOption('delivered', 'Delivered', _selectedStatus, (value) {
                            setState(() => _selectedStatus = value);
                          }),
                          _buildRadioOption('under construction', 'Under Construction', _selectedStatus, (value) {
                            setState(() => _selectedStatus = value);
                          }),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),
                    Divider(),
                    SizedBox(height: 24),

                    // Location Filter
                    _buildFilterSection(
                      'Location',
                      Column(
                        children: [
                          _buildRadioOption('all', 'All Locations', _selectedLocation, (value) {
                            setState(() => _selectedLocation = value);
                          }),
                          ..._availableLocations.take(5).map((location) =>
                            _buildRadioOption(location, location, _selectedLocation, (value) {
                              setState(() => _selectedLocation = value);
                            }),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildRadioOption(String value, String label, String groupValue, Function(String) onChanged) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.mainColor : Color(0xFFCCCCCC),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.mainColor,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Color(0xFF333333) : Color(0xFF666666),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
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
