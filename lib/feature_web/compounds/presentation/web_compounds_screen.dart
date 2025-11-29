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
import 'package:real/feature/search/data/services/company_service.dart';
import 'package:intl/intl.dart';
import 'package:real/core/widgets/custom_loading_dots.dart';
import 'package:real/feature/ai_chat/presentation/widget/floating_comparison_cart.dart';

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

  // Filter debounce timer
  Timer? _filterDebounce;

  // Filter sidebar state variables
  String? _selectedLocation;
  String? _selectedCompanyId;
  List<LocationFilterItem> _availableLocations = [];
  List<CompanyFilterItem> _availableCompanies = [];
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String? _selectedPropertyType;
  int? _selectedBedrooms;
  String? _selectedFinishing;
  DateTime? _deliveredAtFrom;
  DateTime? _deliveredAtTo;
  bool? _hasBeenDelivered;
  bool _hasClub = false;
  bool _hasRoof = false;
  bool _hasGarden = false;
  String? _selectedSortBy;

  // Payment plan filter state variables
  int? _selectedPaymentDuration;
  final TextEditingController _minMonthlyPaymentController = TextEditingController();
  final TextEditingController _maxMonthlyPaymentController = TextEditingController();
  final List<int> paymentDurationOptions = [0, 5, 7, 10]; // 0 = Cash

  final List<String> propertyTypes = ['Villa', 'Apartment', 'Studio', 'Duplex', 'Penthouse'];
  final List<int> bedroomOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  // Finishing options - must match API values exactly
  final List<String> finishingOptions = ['Finished', 'Semi-Finished', 'Core and Shell'];

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
    _loadCompanies();

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
    final locations = await locationService.getLocationsWithLocalization();
    print('[WEB COMPOUNDS] Loaded ${locations.length} locations with localization');
    setState(() {
      _availableLocations = locations;
    });
  }

  Future<void> _loadCompanies() async {
    final companyService = CompanyService();
    final companies = await companyService.getCompaniesWithLocalization();
    print('[WEB COMPOUNDS] Loaded ${companies.length} companies with localization: ${companies.take(10).map((c) => c.name).join(", ")}${companies.length > 10 ? "..." : ""}');
    setState(() {
      _availableCompanies = companies;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _filterDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minMonthlyPaymentController.dispose();
    _maxMonthlyPaymentController.dispose();
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
    // Cancel previous debounce if active
    if (_filterDebounce?.isActive ?? false) {
      _filterDebounce!.cancel();
    }

    // Debounce filter application to prevent multiple rapid calls
    _filterDebounce = Timer(const Duration(milliseconds: 400), () {
      print('🔍 APPLYING FILTERS WITH DEBOUNCE');

      // Convert millions to full price (multiply by 1,000,000)
      final minPriceInMillions = _minPriceController.text.isEmpty
          ? null
          : double.tryParse(_minPriceController.text);
      final maxPriceInMillions = _maxPriceController.text.isEmpty
          ? null
          : double.tryParse(_maxPriceController.text);

      // Monthly payment - use raw values (no multiplication)
      final minMonthlyPayment = _minMonthlyPaymentController.text.isEmpty
          ? null
          : double.tryParse(_minMonthlyPaymentController.text);
      final maxMonthlyPayment = _maxMonthlyPaymentController.text.isEmpty
          ? null
          : double.tryParse(_maxMonthlyPaymentController.text);

      setState(() {
        _currentFilter = SearchFilter(
          location: _selectedLocation,
          companyId: _selectedCompanyId,
          minPrice: minPriceInMillions != null ? minPriceInMillions * 1000000 : null,
          maxPrice: maxPriceInMillions != null ? maxPriceInMillions * 1000000 : null,
          propertyType: _selectedPropertyType,
          bedrooms: _selectedBedrooms,
          finishing: _selectedFinishing,
          deliveredAtFrom: _deliveredAtFrom != null
              ? DateFormat('yyyy-MM-dd').format(_deliveredAtFrom!)
              : null,
          deliveredAtTo: _deliveredAtTo != null
              ? DateFormat('yyyy-MM-dd').format(_deliveredAtTo!)
              : null,
          hasBeenDelivered: _hasBeenDelivered,
          hasClub: _hasClub,
          hasRoof: _hasRoof,
          hasGarden: _hasGarden,
          sortBy: _selectedSortBy,
          // Payment plan filters
          paymentPlanDuration: _selectedPaymentDuration,
          minMonthlyPayment: minMonthlyPayment,
          maxMonthlyPayment: maxMonthlyPayment,
        );
      });

      _performSearch(_searchController.text);
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedLocation = null;
      _selectedCompanyId = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedPropertyType = null;
      _selectedBedrooms = null;
      _selectedFinishing = null;
      _deliveredAtFrom = null;
      _deliveredAtTo = null;
      _hasBeenDelivered = null;
      _hasClub = false;
      _hasRoof = false;
      _hasGarden = false;
      _selectedSortBy = null;
      // Clear payment plan filters
      _selectedPaymentDuration = null;
      _minMonthlyPaymentController.clear();
      _maxMonthlyPaymentController.clear();
      _currentFilter = SearchFilter.empty();
      _showSearchResults = false;
      _showSearchHistory = false;
      // Reset pagination state
      _currentPage = 1;
      _allCompounds.clear();
      _hasMorePages = true;
    });
    // Clear search text and clear search state
    _searchController.clear();
    _searchBloc.add(ClearSearchEvent());

    // Reload compounds from first page
    context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: _pageLimit));
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

    return Stack(
      children: [
        // Main content
        Container(
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
                    Builder(
                      builder: (context) {
                        final isArabic = l10n.localeName == 'ar';
                        // Get localized location name
                        String? localizedLocation;
                        if (_currentFilter.location != null) {
                          final locItem = _availableLocations.where((l) => l.location == _currentFilter.location).firstOrNull;
                          localizedLocation = locItem?.getLocalizedName(isArabic) ?? _currentFilter.location;
                        }
                        // Get localized company name
                        String? localizedCompany;
                        if (_currentFilter.companyId != null) {
                          final compItem = _availableCompanies.where((c) => c.id == _currentFilter.companyId).firstOrNull;
                          localizedCompany = compItem?.getLocalizedName(isArabic) ?? _currentFilter.companyId;
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_currentFilter.location != null)
                              Chip(
                                label: Text('${l10n.location}: $localizedLocation', style: const TextStyle(fontSize: 12)),
                                backgroundColor: AppColors.mainColor.withOpacity(0.1),
                                labelStyle: TextStyle(color: AppColors.mainColor),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _selectedLocation = null;
                                    _currentFilter = _currentFilter.copyWith(clearLocation: true);
                                  });
                                  _performSearch(_searchController.text);
                                },
                              ),
                            if (_currentFilter.companyId != null)
                              Chip(
                                label: Text('${l10n.company}: $localizedCompany', style: const TextStyle(fontSize: 12)),
                                backgroundColor: AppColors.mainColor.withOpacity(0.1),
                                labelStyle: TextStyle(color: AppColors.mainColor),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _selectedCompanyId = null;
                                    _currentFilter = _currentFilter.copyWith(clearCompanyId: true);
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
                                _currentFilter = _currentFilter.copyWith(clearMinPrice: true);
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
                                _currentFilter = _currentFilter.copyWith(clearMaxPrice: true);
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
                                _currentFilter = _currentFilter.copyWith(clearPropertyType: true);
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
                                _currentFilter = _currentFilter.copyWith(clearBedrooms: true);
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
                                _currentFilter = _currentFilter.copyWith(clearFinishing: true);
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
                                _currentFilter = _currentFilter.copyWith(clearHasClub: true);
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
                                _currentFilter = _currentFilter.copyWith(clearHasRoof: true);
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
                                _currentFilter = _currentFilter.copyWith(clearHasGarden: true);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.deliveredAtFrom != null)
                          Chip(
                            label: Text('From: ${_currentFilter.deliveredAtFrom}', style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.mainColor),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(clearDeliveredAtFrom: true);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.deliveredAtTo != null)
                          Chip(
                            label: Text('To: ${_currentFilter.deliveredAtTo}', style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppColors.mainColor),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(clearDeliveredAtTo: true);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                            if (_currentFilter.hasBeenDelivered != null)
                              Chip(
                                label: Text(
                                  _currentFilter.hasBeenDelivered == true
                                    ? 'Delivered'
                                    : 'Not Delivered',
                                  style: const TextStyle(fontSize: 12)
                                ),
                                backgroundColor: AppColors.mainColor.withOpacity(0.1),
                                labelStyle: TextStyle(color: AppColors.mainColor),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _currentFilter = _currentFilter.copyWith(clearHasBeenDelivered: true);
                                  });
                                  _performSearch(_searchController.text);
                                },
                              ),
                          ],
                        );
                      },
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
        ),

        // Floating Comparison Cart
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FloatingComparisonCart(isWeb: true),
        ),
      ],
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

            // Company Dropdown (Searchable with Localization)
            _buildFilterCard(
              title: l10n.company,
              icon: Icons.business,
              child: Builder(
                builder: (context) {
                  final isArabic = l10n.localeName == 'ar';

                  // Get display name for selected company
                  String? selectedDisplayName;
                  if (_selectedCompanyId != null) {
                    final selectedCompany = _availableCompanies.where((c) => c.id == _selectedCompanyId).firstOrNull;
                    selectedDisplayName = selectedCompany?.getLocalizedName(isArabic);
                  }

                  return Autocomplete<CompanyFilterItem>(
                    initialValue: selectedDisplayName != null
                        ? TextEditingValue(text: selectedDisplayName)
                        : const TextEditingValue(),
                    displayStringForOption: (CompanyFilterItem option) => option.getLocalizedName(isArabic),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      // If empty, show all companies
                      if (textEditingValue.text.isEmpty) {
                        return _availableCompanies;
                      }

                      // Filter companies based on input (search in all language variants)
                      final filtered = _availableCompanies.where((CompanyFilterItem company) {
                        final query = textEditingValue.text.toLowerCase();
                        return company.name.toLowerCase().contains(query) ||
                               company.nameEn.toLowerCase().contains(query) ||
                               company.nameAr.toLowerCase().contains(query);
                      }).toList();

                      return filtered;
                    },
                    onSelected: (CompanyFilterItem selection) {
                      setState(() {
                        _selectedCompanyId = selection.id;
                      });
                      _applyFilters();
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      // Set initial value
                      if (selectedDisplayName != null && textEditingController.text.isEmpty) {
                        textEditingController.text = selectedDisplayName;
                      }

                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: isArabic ? 'ابحث واختر الشركة' : 'Type to search or select company',
                          hintStyle: TextStyle(fontSize: 13),
                          suffixIcon: _selectedCompanyId != null
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _selectedCompanyId = null;
                                    });
                                    textEditingController.clear();
                                    _applyFilters();
                                  },
                                )
                              : Icon(Icons.arrow_drop_down, size: 24),
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
                        style: TextStyle(fontSize: 13),
                        onTap: () {
                          // Clear text when tapped to show all options
                          textEditingController.clear();
                          textEditingController.selection = TextSelection.fromPosition(
                            TextPosition(offset: 0),
                          );
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      print('[AUTOCOMPLETE] Showing ${options.length} companies in dropdown');
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            constraints: BoxConstraints(maxHeight: 300),
                            width: 280,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              shrinkWrap: true,
                              itemBuilder: (BuildContext context, int index) {
                                final CompanyFilterItem option = options.elementAt(index);
                                final isSelected = _selectedCompanyId == option.id;
                                return InkWell(
                                  onTap: () {
                                    onSelected(option);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.mainColor.withOpacity(0.1) : null,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            option.getLocalizedName(isArabic),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? AppColors.mainColor : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(Icons.check, size: 16, color: AppColors.mainColor),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Location Dropdown (with Localization)
            _buildFilterCard(
              title: l10n.location,
              icon: Icons.location_on,
              child: Builder(
                builder: (context) {
                  final isArabic = l10n.localeName == 'ar';
                  return DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    icon: Icon(Icons.arrow_drop_down, size: 24),
                    isExpanded: true,
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
                      ..._availableLocations.map((loc) {
                        return DropdownMenuItem<String>(
                          value: loc.location, // Use original location value for filter
                          child: Text(loc.getLocalizedName(isArabic), style: TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
                      });
                      _applyFilters();
                    },
                    selectedItemBuilder: (BuildContext context) {
                      // Custom builder for selected item to show localized name
                      return [
                        Text(l10n.allLocations, style: TextStyle(fontSize: 13)),
                        ..._availableLocations.map((loc) {
                          return Text(loc.getLocalizedName(isArabic), style: TextStyle(fontSize: 13));
                        }).toList(),
                      ];
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Price Range Card (in Millions)
            _buildFilterCard(
              title: 'Price Range (Million EGP)',
              icon: Icons.attach_money,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Min (e.g., 3)',
                        suffixText: 'M',
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
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Max (e.g., 5)',
                        suffixText: 'M',
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

            // Delivered From Date
            _buildFilterCard(
              title: 'Delivered From',
              icon: Icons.calendar_today,
              child: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _deliveredAtFrom ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() {
                      _deliveredAtFrom = picked;
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
                          _deliveredAtFrom != null
                              ? DateFormat('yyyy-MM-dd').format(_deliveredAtFrom!)
                              : 'Select from date',
                          style: TextStyle(
                            fontSize: 13,
                            color: _deliveredAtFrom != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (_deliveredAtFrom != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _deliveredAtFrom = null;
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

            // Delivered To Date
            _buildFilterCard(
              title: 'Delivered To',
              icon: Icons.calendar_today,
              child: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _deliveredAtTo ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() {
                      _deliveredAtTo = picked;
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
                          _deliveredAtTo != null
                              ? DateFormat('yyyy-MM-dd').format(_deliveredAtTo!)
                              : 'Select to date',
                          style: TextStyle(
                            fontSize: 13,
                            color: _deliveredAtTo != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (_deliveredAtTo != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _deliveredAtTo = null;
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

            // Delivery Status
            _buildFilterCard(
              title: 'Delivery Status',
              icon: Icons.local_shipping,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool?>(
                    value: _hasBeenDelivered,
                    icon: Icon(Icons.arrow_drop_down, size: 24),
                    isExpanded: true,
                    hint: Text('All', style: TextStyle(fontSize: 13)),
                    items: [
                      DropdownMenuItem<bool?>(
                        value: null,
                        child: Text('All', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem<bool?>(
                        value: true,
                        child: Text('Only Delivered', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem<bool?>(
                        value: false,
                        child: Text('Not Delivered', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _hasBeenDelivered = value;
                      });
                      _applyFilters();
                    },
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

            // Payment Plan Duration Filter
            _buildFilterCard(
              title: l10n.paymentDuration,
              icon: Icons.calendar_month,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // All Durations option
                  ChoiceChip(
                    label: Text(l10n.allDurations, style: const TextStyle(fontSize: 11)),
                    selected: _selectedPaymentDuration == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPaymentDuration = null;
                      });
                      _applyFilters();
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: AppColors.mainColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _selectedPaymentDuration == null ? AppColors.mainColor : Colors.black,
                      fontWeight: _selectedPaymentDuration == null ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                  // Duration options
                  ...paymentDurationOptions.map((duration) {
                    final isSelected = _selectedPaymentDuration == duration;
                    final label = duration == 0 ? l10n.cashOnly : '$duration ${l10n.years}';
                    return ChoiceChip(
                      label: Text(label, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPaymentDuration = selected ? duration : null;
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
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Monthly Payment Range Filter
            _buildFilterCard(
              title: l10n.monthlyPaymentRange,
              icon: Icons.payments,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minMonthlyPaymentController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: l10n.minMonthly,
                        suffixText: 'EGP',
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
                      controller: _maxMonthlyPaymentController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: l10n.maxMonthly,
                        suffixText: 'EGP',
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
          // Update data immediately
          _allCompounds = List.from(state.response.data);
          _hasMorePages = state.response.page < state.response.totalPages;

          print('[WEB COMPOUNDS] Page ${state.response.page}/${state.response.totalPages}: Loaded ${_allCompounds.length}/${state.response.total} compounds');

          // Reset loading indicator after frame completes (so it shows during loading)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isLoadingMore = false;
              });
            }
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: CustomLoadingDots(size: 80),
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
                maxCrossAxisExtent: 300, // Unified width (increased by 40)
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85, // Unified aspect ratio (wider cards, shorter height)
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
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: CustomLoadingDots(size: 80),
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
          return Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CustomLoadingDots(size: 120),
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
                // Horizontal list layout for companies
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: companyResults.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final result = companyResults[index];
                    final data = result.data as CompanySearchData;
                    final company = _convertToCompany(data, result.id);
                    return AnimatedListItem(
                      index: index,
                      delay: Duration(milliseconds: 60),
                      child: _buildHorizontalCompanyCard(company, l10n),
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
                    maxCrossAxisExtent: 300, // Unified width (increased by 40)
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85, // Unified aspect ratio (wider cards, shorter height)
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
                    maxCrossAxisExtent: 300, // Unified width (increased by 40)
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85, // Unified aspect ratio (wider cards, shorter height)
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
      area: data.totalArea?.toString() ?? data.area ?? '0',
      price: unitPrice,
      bedrooms: data.numberOfBeds ?? '0',
      bathrooms: data.numberOfBaths ?? '0',
      floor: data.floor ?? '0',
      status: data.status,
      unitNumber: data.unitName?.isNotEmpty == true ? data.unitName! : (data.name.isNotEmpty ? data.name : data.code),
      code: data.unitCode?.isNotEmpty == true ? data.unitCode! : data.code,
      createdAt: '',
      updatedAt: '',
      images: images,
      usageType: data.usageType,
      companyName: data.compound.company.name,
      companyLogo: data.compound.company.logo,
      companyId: data.compound.company.id,
      compoundName: data.compound.name,
      compoundLocation: data.compound.location,
      deliveryDate: data.deliveryDate,
      finishing: data.finishingType,
    );
  }

  Widget _buildHorizontalCompanyCard(Company company, AppLocalizations l10n) {
    final isArabic = l10n.localeName == 'ar';
    final companyName = company.getLocalizedName(isArabic);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          print('[COMPANY CARD] Navigating to company: ${company.id} - $companyName');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WebCompanyDetailScreen(
                companyId: company.id,
                company: company,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E6E6), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Company Logo
              if (company.logo != null && company.logo!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: const Color(0xFFF8F9FA),
                    padding: const EdgeInsets.all(8),
                    child: RobustNetworkImage(
                      imageUrl: company.logo!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.contain,
                      errorBuilder: (context, url) => _buildCompanyPlaceholder(companyName),
                    ),
                  ),
                )
              else
                _buildCompanyPlaceholder(companyName),

              const SizedBox(width: 20),

              // Company Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            company.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Stats
              Row(
                children: [
                  _buildCompanyStat(
                    icon: Icons.apartment,
                    label: l10n.compounds,
                    value: company.numberOfCompounds,
                  ),
                  const SizedBox(width: 24),
                  _buildCompanyStat(
                    icon: Icons.home_work_outlined,
                    label: l10n.units,
                    value: company.numberOfAvailableUnits,
                  ),
                ],
              ),

              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppColors.mainColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyPlaceholder(String name) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.mainColor,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'C',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.mainColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.mainColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Company _convertToCompany(CompanySearchData data, String id) {
    return Company(
      id: id,
      name: data.name,
      nameEn: data.name,
      nameAr: data.name,
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
