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
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature_web/company/presentation/web_company_detail_screen.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import 'package:real/core/widget/robust_network_image.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/animations/animated_list_item.dart';
import 'package:real/core/animations/page_transitions.dart';
import 'package:real/feature/search/presentation/widget/search_filter_bottom_sheet.dart';
import 'package:real/feature/search/data/services/location_service.dart';
import 'package:intl/intl.dart';

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

  // Filter sidebar state variables
  String? _selectedLocation;
  List<String> _availableLocations = [];
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String? _selectedPropertyType;
  int? _selectedBedrooms;
  String? _selectedFinishing;
  DateTime? _selectedDeliveryDate;
  bool _hasClub = false;
  bool _hasRoof = false;
  bool _hasGarden = false;
  String? _selectedSortBy;

  final List<String> propertyTypes = ['Villa', 'Apartment', 'Studio', 'Duplex', 'Penthouse'];
  final List<int> bedroomOptions = [1, 2, 3, 4, 5];
  final List<String> finishingOptions = ['Finished', 'Semi-Finished', 'Core & Shell'];

  // Sort options - will be populated with localized values
  Map<String, String> get sortOptions {
    final l10n = AppLocalizations.of(context)!;
    return {
      'price_asc': l10n.priceAsc,
      'price_desc': l10n.priceDesc,
      'newest': l10n.newestFirst,
    };
  }

  // Track expanded state for search results

  @override
  void initState() {
    super.initState();
    _searchBloc = SearchBloc(repository: SearchRepository());
    _loadSearchHistory();
    _loadLocations();

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

  Future<void> _loadLocations() async {
    final locationService = LocationService();
    final locations = await locationService.getLocations();
    setState(() {
      _availableLocations = locations;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _searchBloc.close();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0; // Trigger when 200px from bottom

    if (maxScroll - currentScroll <= delta) {
      if (_showSearchResults) {
        // Auto-load more search results
        _loadMoreSearchResults();
      } else {
        // Auto-load more compounds
        if (!_isLoadingMore && _hasMorePages) {
          _loadMoreCompounds();
        }
      }
    }
  }

  void _loadMoreSearchResults() {
    // Get current search state
    final currentState = _searchBloc.state;

    // Only load if we have more pages and not currently loading
    if (currentState is SearchSuccess &&
        currentState.hasMorePages &&
        currentState is! SearchLoadingMore) {

      print('[WEB COMPOUNDS] Auto-loading more results - Page ${currentState.currentPage + 1}/${currentState.totalPages}');

      _searchBloc.add(
        LoadMoreSearchResultsEvent(
          query: _searchController.text,
          filter: _currentFilter,
          page: currentState.currentPage + 1,
        ),
      );
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

  void _applyFilters() {
    setState(() {
      _currentFilter = SearchFilter(
        location: _selectedLocation,
        minPrice: _minPriceController.text.isEmpty
            ? null
            : double.tryParse(_minPriceController.text),
        maxPrice: _maxPriceController.text.isEmpty
            ? null
            : double.tryParse(_maxPriceController.text),
        propertyType: _selectedPropertyType,
        bedrooms: _selectedBedrooms,
        finishing: _selectedFinishing,
        deliveryDate: _selectedDeliveryDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDeliveryDate!)
            : null,
        hasClub: _hasClub,
        hasRoof: _hasRoof,
        hasGarden: _hasGarden,
        sortBy: _selectedSortBy,
      );
    });
    _performSearch(_searchController.text);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedLocation = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedPropertyType = null;
      _selectedBedrooms = null;
      _selectedFinishing = null;
      _selectedDeliveryDate = null;
      _hasClub = false;
      _hasRoof = false;
      _hasGarden = false;
      _selectedSortBy = null;
      _currentFilter = SearchFilter.empty();
    });
    _performSearch(_searchController.text);
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
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      print('═══════════════════════════════════════════════');
      print('[WEB COMPOUNDS] Performing Search:');
      print('[WEB] Query: "${query.trim()}"');
      print('[WEB] Current Filter isEmpty: ${_currentFilter.isEmpty}');
      print('[WEB] Current Filter activeCount: ${_currentFilter.activeFiltersCount}');
      print('[WEB] Filter to pass: ${_currentFilter.isEmpty ? 'NULL' : 'FILTER OBJECT'}');
      if (!_currentFilter.isEmpty) {
        print('[WEB] Filter Details: ${_currentFilter.toString()}');
        print('[WEB] Filter Query Params: ${_currentFilter.toQueryParameters()}');
      }
      print('═══════════════════════════════════════════════');

      if (query.trim().isNotEmpty) {
        _saveToHistory(query);
      }

      _searchBloc.add(SearchQueryEvent(
        query: query.trim(),
        type: _currentFilter.isEmpty ? null : 'unit', // Filter-only searches show units only
        filter: _currentFilter.isEmpty ? null : _currentFilter,
      ));
    });
  }

  // Old filter methods removed - now using SearchFilterBottomSheet

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
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT SIDEBAR - FILTERS
            _buildFilterSidebar(l10n),

            // MAIN CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const SizedBox(height: 32),
                  // Header with count
                  BlocBuilder<CompoundBloc, CompoundState>(
                    builder: (context, state) {
                      final compoundCount = state is CompoundSuccess
                          ? int.tryParse(state.response.total) ?? 0
                          : 0;

                      return Row(
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
                          if (compoundCount > 0) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.mainColor, AppColors.mainColor.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$compoundCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.browseAllCompounds,
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
                        hintText: l10n.searchForCompounds,
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
                          Chip(
                            label: Text('${l10n.location}: ${_currentFilter.location}', style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.mainColor),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(location: null);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.minPrice != null)
                          Chip(
                            label: Text('${l10n.minPrice}: ${_currentFilter.minPrice} ${l10n.egp}', style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.mainColor),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(minPrice: null);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.maxPrice != null)
                          Chip(
                            label: Text('${l10n.maxPrice}: ${_currentFilter.maxPrice} ${l10n.egp}', style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.mainColor),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(maxPrice: null);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.propertyType != null)
                          Chip(
                            label: Text(_currentFilter.propertyType!, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.mainColor),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(propertyType: null);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.bedrooms != null)
                          Chip(
                            label: Text('${_currentFilter.bedrooms} ${l10n.beds}', style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.mainColor),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(bedrooms: null);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.finishing != null)
                          Chip(
                            label: Text(_currentFilter.finishing!, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.mainColor),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(finishing: null);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.hasClub == true)
                          Chip(
                            label: Text(l10n.hasClubFilter, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.mainColor),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(hasClub: false);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.hasRoof == true)
                          Chip(
                            label: Text(l10n.hasRoofFilter, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.mainColor),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(hasRoof: false);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.hasGarden == true)
                          Chip(
                            label: Text(l10n.hasGardenFilter, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.mainColor),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(hasGarden: false);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                      ],
                    ),

                  if (_currentFilter.activeFiltersCount > 0)
                    const SizedBox(height: 24),

                  // Search Results or Compounds Grid
                  _showSearchResults
                      ? _buildSearchResults(l10n)
                      : _buildCompoundsGrid(l10n),
                ],
              ),))]
        ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const SizedBox(height: 32),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText20(l10n.filters, bold: true, color: AppColors.black),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: CustomText14(l10n.clearAll, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Dropdown
            _buildFilterCard(
              title: l10n.location,
              icon: Icons.location_on,
              child: DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: InputDecoration(
                  hintText: l10n.selectLocation,
                  hintStyle: TextStyle(fontSize: 13),
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
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(l10n.allLocations, style: TextStyle(fontSize: 13)),
                  ),
                  ..._availableLocations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location, style: TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                  _applyFilters();
                },
              ),
            ),

            const SizedBox(height: 12),

            // Price Range Card
            _buildFilterCard(
              title: l10n.priceRange,
              icon: Icons.attach_money,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: l10n.minPrice,
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
                        hintText: l10n.maxPrice,
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
              title: l10n.propertyType,
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
              title: l10n.bedrooms,
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
              title: l10n.finishing,
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

            // Delivery Date Calendar Picker
            _buildFilterCard(
              title: l10n.deliveryDate,
              icon: Icons.calendar_today,
              child: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDeliveryDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDeliveryDate = picked;
                    });
                    _applyFilters();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedDeliveryDate != null
                              ? DateFormat('dd MMM yyyy').format(_selectedDeliveryDate!)
                              : l10n.selectDeliveryDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedDeliveryDate != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (_selectedDeliveryDate != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDeliveryDate = null;
                            });
                            _applyFilters();
                          },
                          child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Amenities Card
            _buildFilterCard(
              title: l10n.amenities,
              icon: Icons.star,
              child: Column(
                children: [
                  _buildAmenityCheckbox(l10n.hasClubAmenity, _hasClub, Icons.sports_tennis, (value) {
                    setState(() {
                      _hasClub = value ?? false;
                    });
                    _applyFilters();
                  }),
                  const SizedBox(height: 8),
                  _buildAmenityCheckbox(l10n.hasRoofAmenity, _hasRoof, Icons.roofing, (value) {
                    setState(() {
                      _hasRoof = value ?? false;
                    });
                    _applyFilters();
                  }),
                  const SizedBox(height: 8),
                  _buildAmenityCheckbox(l10n.hasGardenAmenity, _hasGarden, Icons.yard, (value) {
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
              title: l10n.sortBy,
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
                    child: Text(l10n.retry),
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
                maxCrossAxisExtent: 320,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.9, // balanced card proportions
              ),
              itemCount: _allCompounds.length,
              itemBuilder: (context, index) {
                return AnimatedListItem(
                  index: index,
                  delay: Duration(milliseconds: 60),
                  child: WebCompoundCard(compound: _allCompounds[index]),
                );
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
                    l10n.noMoreCompounds,
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
        } else if (state is SearchSuccess || state is SearchLoadingMore) {
          // Get the current response (works for both states)
          final response = state is SearchSuccess
              ? state.response
              : (state as SearchLoadingMore).currentResponse;
          final hasMorePages = state is SearchSuccess ? state.hasMorePages : false;
          final currentPage = state is SearchSuccess ? state.currentPage : 1;
          final totalPages = state is SearchSuccess ? state.totalPages : 1;
          final isLoadingMore = state is SearchLoadingMore;
          final results = response.results;

          if (results.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noResultsFound,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.foundResults(response.totalResults),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (hasMorePages)
                    Text(
                      l10n.showingResults(results.length, response.totalResults),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Display company results
              if (companyResults.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.business, size: 20, color: AppColors.mainColor),
                    const SizedBox(width: 8),
                    Text(
                      l10n.companiesCount(companyResults.length),
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
                  itemCount: companyResults.length,
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
                          context.pushSlideFade(
                            WebCompanyDetailScreen(
                              companyId: result.id,
                              company: company,
                            ),
                          );
                        },
                      ),
                    );
                  },
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
                      l10n.compoundsCount(compoundResults.length),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Vertical scrolling grid - same as normal compounds
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.9, // balanced card proportions
                  ),
                  itemCount: compoundResults.length,
                  itemBuilder: (context, index) {
                    final result = compoundResults[index];
                    final data = result.data as CompoundSearchData;
                    final compound = _convertToCompound(data, result.id);
                    return AnimatedListItem(
                      index: index,
                      delay: Duration(milliseconds: 60),
                      child: WebCompoundCard(compound: compound),
                    );
                  },
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
                      l10n.propertiesCount(response.totalResults),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasMorePages) ...[
                      const SizedBox(width: 12),
                      CustomText14(
                        l10n.pageOf(currentPage, totalPages),
                        color: Colors.grey,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Vertical scrolling grid - same as compounds
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.9, // balanced card proportions
                  ),
                  itemCount: unitResults.length,
                  itemBuilder: (context, index) {
                    final result = unitResults[index];
                    final data = result.data as UnitSearchData;
                    final unit = _convertToUnit(data);
                    return AnimatedListItem(
                      index: index,
                      delay: Duration(milliseconds: 60),
                      child: WebUnitCard(unit: unit),
                    );
                  },
                ),
                // Loading indicator when loading more
                if (isLoadingMore) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(
                            l10n.loadingMoreResults,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                // Show remaining count when there are more pages
                if (hasMorePages && !isLoadingMore) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      l10n.moreResultsAvailableScrollToLoad(response.totalResults - unitResults.length),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
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
