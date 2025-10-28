import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature_web/widgets/web_compound_card.dart';
import 'package:real/feature_web/widgets/web_unit_card.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/feature/search/data/repositories/search_repository.dart';
import 'package:real/feature/search/data/services/search_history_service.dart';
import 'package:real/feature/search/data/models/search_filter_model.dart';
import 'package:real/feature/search/presentation/bloc/search_bloc.dart';
import 'package:real/feature/search/presentation/bloc/search_event.dart';
import 'package:real/feature/search/presentation/bloc/search_state.dart';
import 'package:real/feature/search/data/models/search_result_model.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/presentation/screen/unit_detail_screen.dart';
import 'package:real/feature/home/presentation/CompoundScreen.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature_web/company/presentation/web_company_detail_screen.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/core/utils/text_style.dart';

class WebCompoundsScreen extends StatefulWidget {
  const WebCompoundsScreen({Key? key}) : super(key: key);

  @override
  State<WebCompoundsScreen> createState() => _WebCompoundsScreenState();
}

class _WebCompoundsScreenState extends State<WebCompoundsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late SearchBloc _searchBloc;
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  bool _showSearchResults = false;
  bool _showSearchHistory = false;
  Timer? _debounceTimer;
  List<String> _searchHistory = [];
  SearchFilter _currentFilter = SearchFilter.empty();

  // Pagination variables
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _pageLimit = 10;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;
  List<Compound> _allCompounds = [];

  // Filter controllers
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();

  String? _selectedPropertyType;
  int? _selectedBedrooms;
  String? _selectedFinishing;
  bool _hasClub = false;
  bool _hasRoof = false;
  bool _hasGarden = false;
  String? _selectedSortBy;

  final List<String> propertyTypes = [
    'Villa',
    'Apartment',
    'Duplex',
    'Studio',
    'Penthouse',
    'Townhouse',
  ];

  final List<int> bedroomOptions = [1, 2, 3, 4, 5, 6];

  final List<String> finishingOptions = [
    'Finished',
    'Semi Finished',
    'Not Finished',
  ];

  final Map<String, String> sortOptions = {
    'price_asc': 'Price: Low to High',
    'price_desc': 'Price: High to Low',
    'date_asc': 'Date: Oldest First',
    'date_desc': 'Date: Newest First',
  };

  // Track expanded state for search results
  bool _showAllCompanies = false;
  bool _showAllCompounds = false;
  bool _showAllUnits = false;

  @override
  void initState() {
    super.initState();
    _searchBloc = SearchBloc(repository: SearchRepository());
    _loadSearchHistory();

    // Listen to focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _showSearchHistory = _searchFocusNode.hasFocus &&
            _searchController.text.isEmpty &&
            _searchHistory.isNotEmpty;
      });
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Load first page with 10 items
    context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: _pageLimit));
  }

  void _onScroll() {
    if (_showSearchResults) return; // Don't paginate during search

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0; // Trigger when 200px from bottom

    if (maxScroll - currentScroll <= delta) {
      if (!_isLoadingMore && _hasMorePages) {
        _loadMoreCompounds();
      }
    }
  }

  void _loadMoreCompounds() {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    context.read<CompoundBloc>().add(
          FetchCompoundsEvent(page: _currentPage, limit: _pageLimit),
        );
  }

  Future<void> _loadSearchHistory() async {
    final history = await _searchHistoryService.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchBloc.close();
    _debounceTimer?.cancel();
    _locationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _deliveryDateController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty && _currentFilter.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _showSearchHistory = false;
      });
      _searchBloc.add(ClearSearchEvent());
      return;
    }

    setState(() {
      _showSearchResults = true;
      _showSearchHistory = false;
      _showAllCompanies = false;
      _showAllCompounds = false;
      _showAllUnits = false;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _saveToHistory(query);
      }

      _searchBloc.add(SearchQueryEvent(
        query: query.trim(),
        filter: _currentFilter.isEmpty ? null : _currentFilter,
      ));
    });
  }

  void _applyFilters() {
    final filter = SearchFilter(
      location: _locationController.text.isEmpty
          ? null
          : _locationController.text,
      minPrice: _minPriceController.text.isEmpty
          ? null
          : double.tryParse(_minPriceController.text),
      maxPrice: _maxPriceController.text.isEmpty
          ? null
          : double.tryParse(_maxPriceController.text),
      propertyType: _selectedPropertyType,
      bedrooms: _selectedBedrooms,
      finishing: _selectedFinishing,
      deliveryDate: _deliveryDateController.text.isEmpty
          ? null
          : _deliveryDateController.text,
      hasClub: _hasClub,
      hasRoof: _hasRoof,
      hasGarden: _hasGarden,
      sortBy: _selectedSortBy,
    );

    setState(() {
      _currentFilter = filter;
    });

    _performSearch(_searchController.text);
  }

  void _clearAllFilters() {
    setState(() {
      _locationController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _deliveryDateController.clear();
      _selectedPropertyType = null;
      _selectedBedrooms = null;
      _selectedFinishing = null;
      _hasClub = false;
      _hasRoof = false;
      _hasGarden = false;
      _selectedSortBy = null;
      _currentFilter = SearchFilter.empty();

      // Reset pagination when clearing filters
      _currentPage = 1;
      _allCompounds.clear();
      _hasMorePages = true;
    });
    _performSearch(_searchController.text);
  }

  Future<void> _saveToHistory(String query) async {
    await _searchHistoryService.addToHistory(query);
    await _loadSearchHistory();
  }

  Future<void> _deleteFromHistory(String query) async {
    await _searchHistoryService.removeFromHistory(query);
    await _loadSearchHistory();
    setState(() {
      _showSearchHistory = _searchFocusNode.hasFocus &&
          _searchController.text.isEmpty &&
          _searchHistory.isNotEmpty;
    });
  }

  Future<void> _clearAllHistory() async {
    await _searchHistoryService.clearHistory();
    await _loadSearchHistory();
    setState(() {
      _showSearchHistory = false;
    });
  }

  void _selectHistoryItem(String query) {
    _searchController.text = query;
    setState(() {
      _showSearchHistory = false;
      _showSearchResults = true;
      _showAllCompanies = false;
      _showAllCompounds = false;
      _showAllUnits = false;
    });
    _searchBloc.add(SearchQueryEvent(
      query: query,
      filter: _currentFilter.isEmpty ? null : _currentFilter,
    ));
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showSearchResults = false;
      // Reset pagination when clearing search
      _currentPage = 1;
      _allCompounds.clear();
      _hasMorePages = true;
    });
    _searchBloc.add(ClearSearchEvent());
    _searchFocusNode.unfocus();

    // Reload first page of compounds
    context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: _pageLimit));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT SIDEBAR - FILTERS
          _buildFilterSidebar(l10n),

          // MAIN CONTENT
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.apartment,
                        size: 32,
                        color: AppColors.mainColor,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        l10n.compounds ?? 'Compounds',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse all available compounds',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Search Bar
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _performSearch,
                      decoration: InputDecoration(
                        hintText: 'Search for compounds...',
                        prefixIcon: Icon(Icons.search, size: 24, color: AppColors.mainColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: _clearSearch,
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Active Filters Display
                  if (_currentFilter.activeFiltersCount > 0)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_currentFilter.location != null)
                          _buildFilterChip('Location: ${_currentFilter.location}'),
                        if (_currentFilter.minPrice != null)
                          _buildFilterChip('Min: ${_currentFilter.minPrice} EGP'),
                        if (_currentFilter.maxPrice != null)
                          _buildFilterChip('Max: ${_currentFilter.maxPrice} EGP'),
                        if (_currentFilter.propertyType != null)
                          _buildFilterChip(_currentFilter.propertyType!),
                        if (_currentFilter.bedrooms != null)
                          _buildFilterChip('${_currentFilter.bedrooms} Beds'),
                        if (_currentFilter.finishing != null)
                          _buildFilterChip(_currentFilter.finishing!),
                        if (_currentFilter.hasClub == true)
                          _buildFilterChip('Has Club'),
                        if (_currentFilter.hasRoof == true)
                          _buildFilterChip('Has Roof'),
                        if (_currentFilter.hasGarden == true)
                          _buildFilterChip('Has Garden'),
                      ],
                    ),

                  if (_currentFilter.activeFiltersCount > 0)
                    const SizedBox(height: 24),

                  // Search Results or Compounds Grid
                  _showSearchResults
                      ? _buildSearchResults(l10n)
                      : _buildCompoundsGrid(l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSidebar(AppLocalizations l10n) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText20('Filters', bold: true, color: AppColors.black),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: CustomText14('Clear All', color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Card
            _buildFilterCard(
              title: 'Location',
              icon: Icons.location_on,
              child: TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'e.g., New Cairo',
                  hintStyle: TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => _applyFilters(),
              ),
            ),

            const SizedBox(height: 12),

            // Price Range Card
            _buildFilterCard(
              title: 'Price Range',
              icon: Icons.attach_money,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Min',
                        hintStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => _applyFilters(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Max',
                        hintStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => _applyFilters(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Property Type Card
            _buildFilterCard(
              title: 'Property Type',
              icon: Icons.home_work,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: propertyTypes.map((type) {
                  final isSelected = _selectedPropertyType == type;
                  return ChoiceChip(
                    label: Text(type, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPropertyType = selected ? type : null;
                      });
                      _applyFilters();
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: AppColors.mainColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.mainColor : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Bedrooms Card
            _buildFilterCard(
              title: 'Bedrooms',
              icon: Icons.bed,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: bedroomOptions.map((beds) {
                  final isSelected = _selectedBedrooms == beds;
                  return ChoiceChip(
                    label: Text('$beds', style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedBedrooms = selected ? beds : null;
                      });
                      _applyFilters();
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: AppColors.mainColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.mainColor : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Finishing Card
            _buildFilterCard(
              title: 'Finishing',
              icon: Icons.format_paint,
              child: Column(
                children: finishingOptions.map((finishing) {
                  final isSelected = _selectedFinishing == finishing;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFinishing = isSelected ? null : finishing;
                        });
                        _applyFilters();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.mainColor.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.mainColor
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? AppColors.mainColor : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              finishing,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? AppColors.mainColor : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Delivery Date Card
            _buildFilterCard(
              title: 'Delivery Date',
              icon: Icons.calendar_today,
              child: TextField(
                controller: _deliveryDateController,
                decoration: InputDecoration(
                  hintText: 'e.g., 2025',
                  hintStyle: TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => _applyFilters(),
              ),
            ),

            const SizedBox(height: 12),

            // Amenities Card
            _buildFilterCard(
              title: 'Amenities',
              icon: Icons.star,
              child: Column(
                children: [
                  _buildAmenityCheckbox('Has Club', _hasClub, Icons.sports_tennis, (value) {
                    setState(() {
                      _hasClub = value ?? false;
                    });
                    _applyFilters();
                  }),
                  const SizedBox(height: 8),
                  _buildAmenityCheckbox('Has Roof', _hasRoof, Icons.roofing, (value) {
                    setState(() {
                      _hasRoof = value ?? false;
                    });
                    _applyFilters();
                  }),
                  const SizedBox(height: 8),
                  _buildAmenityCheckbox('Has Garden', _hasGarden, Icons.yard, (value) {
                    setState(() {
                      _hasGarden = value ?? false;
                    });
                    _applyFilters();
                  }),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Sort By Card
            _buildFilterCard(
              title: 'Sort By',
              icon: Icons.sort,
              child: Column(
                children: sortOptions.entries.map((entry) {
                  final isSelected = _selectedSortBy == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSortBy = isSelected ? null : entry.key;
                        });
                        _applyFilters();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.mainColor.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.mainColor
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? AppColors.mainColor : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? AppColors.mainColor : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.mainColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildAmenityCheckbox(
    String label,
    bool value,
    IconData icon,
    Function(bool?) onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? AppColors.mainColor.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value
                ? AppColors.mainColor
                : Colors.grey.shade300,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? AppColors.mainColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 16, color: value ? AppColors.mainColor : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: value ? AppColors.mainColor : Colors.black87,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomText16(title, bold: true, color: AppColors.black);
  }

  Widget _buildFilterChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.mainColor.withOpacity(0.1),
      labelStyle: TextStyle(color: AppColors.mainColor),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () => _clearAllFilters(),
    );
  }

  Widget _buildCompoundsGrid(AppLocalizations l10n) {
    return BlocConsumer<CompoundBloc, CompoundState>(
      listener: (context, state) {
        if (state is CompoundSuccess) {
          setState(() {
            if (_currentPage == 1) {
              // First page - replace all compounds
              _allCompounds = List.from(state.response.data);
            } else {
              // Subsequent pages - append new compounds
              _allCompounds.addAll(state.response.data);
            }

            // Check if there are more pages
            _hasMorePages = state.response.page < state.response.totalPages;
            _isLoadingMore = false;
          });
        } else if (state is CompoundError) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      },
      builder: (context, state) {
        // Show loading only on first page
        if (state is CompoundLoading && _currentPage == 1) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show error if no data loaded yet
        if (state is CompoundError && _allCompounds.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentPage = 1;
                        _allCompounds.clear();
                        _hasMorePages = true;
                      });
                      context.read<CompoundBloc>().add(
                            FetchCompoundsEvent(page: 1, limit: _pageLimit),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show empty state if no compounds
        if (_allCompounds.isEmpty && state is! CompoundLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                children: [
                  Icon(Icons.apartment, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noCompounds ?? 'No compounds found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        // Show grid with compounds
        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 0.85,
              ),
              itemCount: _allCompounds.length,
              itemBuilder: (context, index) {
                return WebCompoundCard(compound: _allCompounds[index]);
              },
            ),

            // Loading indicator at bottom when loading more
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // End of results message
            if (!_hasMorePages && _allCompounds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No more compounds to load',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n) {
    return BlocBuilder<SearchBloc, SearchState>(
      bloc: _searchBloc,
      builder: (context, state) {
        if (state is SearchLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is SearchSuccess) {
          final results = state.response.results;

          if (results.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No results found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Separate results by type
          final companyResults = results.where((r) => r.type == 'company').toList();
          final compoundResults = results.where((r) => r.type == 'compound').toList();
          final unitResults = results.where((r) => r.type == 'unit').toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Found ${results.length} results',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              // Display company results
              if (companyResults.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.business, size: 20, color: AppColors.mainColor),
                    const SizedBox(width: 8),
                    Text(
                      'Companies (${companyResults.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _showAllCompanies
                      ? companyResults.length
                      : (companyResults.length > 3 ? 3 : companyResults.length),
                  itemBuilder: (context, index) {
                    final result = companyResults[index];
                    final data = result.data as CompanySearchData;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: data.logo != null && data.logo!.isNotEmpty
                            ? ClipOval(
                                child: RobustNetworkImage(
                                  imageUrl: data.logo!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, url) => Icon(
                                    Icons.business,
                                    size: 24,
                                    color: AppColors.mainColor,
                                  ),
                                ),
                              )
                            : Icon(Icons.business, color: AppColors.mainColor),
                        title: Text(data.name),
                        subtitle: Text('${data.compoundsCount} compounds'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          final company = _convertToCompany(data, result.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebCompanyDetailScreen(
                                company: company,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                if (companyResults.length > 3)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllCompanies = !_showAllCompanies;
                      });
                    },
                    child: Text(
                      _showAllCompanies ? 'Show less' : 'Show all companies',
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // Display compound results
              if (compoundResults.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.apartment, size: 20, color: AppColors.mainColor),
                    const SizedBox(width: 8),
                    Text(
                      'Compounds (${compoundResults.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _showAllCompounds
                      ? compoundResults.length
                      : (compoundResults.length > 6 ? 6 : compoundResults.length),
                  itemBuilder: (context, index) {
                    final result = compoundResults[index];
                    final data = result.data as CompoundSearchData;
                    final compound = _convertToCompound(data, result.id);
                    return WebCompoundCard(compound: compound);
                  },
                ),
                if (compoundResults.length > 6)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllCompounds = !_showAllCompounds;
                      });
                    },
                    child: Text(
                      _showAllCompounds ? 'Show less' : 'Show all compounds',
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // Display unit results
              if (unitResults.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.home, size: 20, color: AppColors.mainColor),
                    const SizedBox(width: 8),
                    Text(
                      'Properties (${unitResults.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _showAllUnits
                      ? unitResults.length
                      : (unitResults.length > 6 ? 6 : unitResults.length),
                  itemBuilder: (context, index) {
                    final result = unitResults[index];
                    final data = result.data as UnitSearchData;
                    final unit = _convertToUnit(data);
                    return WebUnitCard(unit: unit);
                  },
                ),
                if (unitResults.length > 6)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllUnits = !_showAllUnits;
                      });
                    },
                    child: Text(
                      _showAllUnits ? 'Show less' : 'Show all properties',
                    ),
                  ),
              ],
            ],
          );
        } else if (state is SearchError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Compound _convertToCompound(CompoundSearchData data, String id) {
    return Compound(
      id: id,
      companyId: data.company.id,
      project: data.name,
      location: data.location,
      images: data.images,
      builtUpArea: '0',
      howManyFloors: '0',
      completionProgress: data.completionProgress,
      club: '0',
      isSold: '0',
      status: data.status,
      totalUnits: data.unitsCount,
      createdAt: data.createdAt,
      updatedAt: data.createdAt,
      companyName: data.company.name,
      companyLogo: data.company.logo,
      soldUnits: '0',
      availableUnits: data.unitsCount,
      sales: [],
    );
  }

  Unit _convertToUnit(UnitSearchData data) {
    // Use unit images, fallback to compound images if unit images are empty
    final images = data.images.isNotEmpty ? data.images : data.compound.images;

    // Use the proper price: discounted price if available, otherwise normal price, otherwise fall back
    final unitPrice = data.discountedPrice?.isNotEmpty == true
        ? data.discountedPrice!
        : (data.normalPrice?.isNotEmpty == true
            ? data.normalPrice!
            : (data.totalPrice.isNotEmpty ? data.totalPrice : (data.price ?? '0')));

    return Unit(
      id: data.id,
      compoundId: data.compound.id,
      unitType: data.unitType,
      area: data.area ?? '0',
      price: unitPrice,
      bedrooms: data.numberOfBeds ?? '0',
      bathrooms: data.numberOfBaths ?? '0',
      floor: data.floor ?? '0',
      status: data.status,
      unitNumber: data.unitName?.isNotEmpty == true ? data.unitName! : (data.name.isNotEmpty ? data.name : data.code),
      createdAt: '',
      updatedAt: '',
      images: images,
      usageType: data.usageType,
      companyName: data.compound.company.name,
      companyLogo: data.compound.company.logo,
      companyId: data.compound.company.id,
      compoundName: data.compound.name,
    );
  }

  Company _convertToCompany(CompanySearchData data, String id) {
    return Company(
      id: id,
      name: data.name,
      logo: data.logo,
      email: data.email,
      numberOfCompounds: data.numberOfCompounds,
      numberOfAvailableUnits: data.numberOfAvailableUnits,
      createdAt: data.createdAt ?? '',
      sales: [],
      salesCount: 0,
      compounds: [],
    );
  }
}
