import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature/compound/presentation/widget/unit_card.dart';
import 'package:real/feature/compound/presentation/screen/unit_detail_screen.dart';
import 'package:real/feature/home/presentation/CompoundScreen.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/core/animations/animated_list_item.dart';
import 'package:real/core/animations/page_transitions.dart';
import 'package:real/feature/search/data/models/search_filter_model.dart';
import 'package:real/feature/search/data/repositories/search_repository.dart';
import 'package:real/feature/search/data/services/search_history_service.dart';
import 'package:real/feature/search/data/models/search_result_model.dart';
import 'package:real/feature/search/presentation/bloc/search_bloc.dart';
import 'package:real/feature/search/presentation/bloc/search_event.dart';
import 'package:real/feature/search/presentation/bloc/search_state.dart';
import 'package:real/feature/search/presentation/widget/search_filter_bottom_sheet.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature/company/presentation/screen/company_detail_screen.dart';
import 'package:real/core/utils/card_dimensions.dart';

class CompoundsScreen extends StatefulWidget {
  static String routeName = '/compounds';

  CompoundsScreen({Key? key}) : super(key: key);

  @override
  State<CompoundsScreen> createState() => _CompoundsScreenState();
}

class _CompoundsScreenState extends State<CompoundsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  late SearchBloc _searchBloc;
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  bool _showSearchResults = false;
  bool _showSearchHistory = false;
  Timer? _debounceTimer;
  List<String> _searchHistory = [];
  SearchFilter _currentFilter = SearchFilter.empty();

  // Track expanded state for search results
  bool _showAllCompanies = false;
  bool _showAllCompounds = false;
  bool _showAllUnits = false;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 50;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _searchBloc = SearchBloc(repository: SearchRepository());
    _loadSearchHistory();

    // Fetch first page of compounds
    context.read<CompoundBloc>().add(FetchCompoundsEvent(page: _currentPage, limit: _itemsPerPage));

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
    _scrollController.dispose();
    _searchBloc.close();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreCompounds();
    }
  }

  void _loadMoreCompounds() {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    context.read<CompoundBloc>().add(
      FetchCompoundsEvent(page: _currentPage, limit: _itemsPerPage),
    );
  }

  void _performSearch(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // If both query is empty AND no filters are active, clear search
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

    // Wait 500ms before performing search
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      print('═══════════════════════════════════════════════');
      print('[COMPOUNDS SCREEN] Performing Search:');
      print('[COMPOUNDS] Query: "${query.trim()}"');
      print('[COMPOUNDS] Current Filter isEmpty: ${_currentFilter.isEmpty}');
      print('[COMPOUNDS] Current Filter activeCount: ${_currentFilter.activeFiltersCount}');
      print('[COMPOUNDS] Filter to pass: ${_currentFilter.isEmpty ? 'NULL' : 'FILTER OBJECT'}');
      if (!_currentFilter.isEmpty) {
        print('[COMPOUNDS] Filter Details: ${_currentFilter.toString()}');
        print('[COMPOUNDS] Filter Query Params: ${_currentFilter.toQueryParameters()}');
      }
      print('═══════════════════════════════════════════════');

      _searchBloc.add(SearchQueryEvent(
        query: query.trim(),
        type: _currentFilter.isEmpty ? null : 'unit', // Filter-only searches show units only
        filter: _currentFilter.isEmpty ? null : _currentFilter,
      ));
      // Save to history after search is triggered (only if there's a query)
      if (query.trim().isNotEmpty) {
        _saveToHistory(query.trim());
      }
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
          // Re-run search with new filters (works with or without query text)
          _performSearch(_searchController.text);
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = SearchFilter.empty();
    });
    // Re-run search without filters (or clear results if no query)
    _performSearch(_searchController.text);
  }

  Future<void> _saveToHistory(String query) async {
    await _searchHistoryService.addToHistory(query);
    await _loadSearchHistory();
  }

  Future<void> _deleteFromHistory(String query) async {
    await _searchHistoryService.removeFromHistory(query);
    await _loadSearchHistory();
    // Update visibility
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
      // Reset expanded states for new search
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
    });
    _searchBloc.add(ClearSearchEvent());
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search and filter
            Container(
              padding: EdgeInsets.all(16),
              color: AppColors.white,
              child: Column(
                children: [
                  // Search bar with filter button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          key: _searchKey,
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (value) {
                              setState(() {
                                _performSearch(value);
                              });
                            },
                            decoration: InputDecoration(
                              hintText: l10n.searchFor,
                              hintStyle: TextStyle(color: AppColors.greyText),
                              prefixIcon: Icon(Icons.search, color: AppColors.greyText),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: AppColors.greyText),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Filter button with badge
                      Stack(
                        key: _filterKey,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _currentFilter.isEmpty
                                  ? Colors.grey.shade200
                                  : AppColors.mainColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.filter_list,
                                color: _currentFilter.isEmpty
                                    ? Colors.grey
                                    : AppColors.mainColor,
                              ),
                              onPressed: _openFilterBottomSheet,
                            ),
                          ),
                          if (_currentFilter.activeFiltersCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    '${_currentFilter.activeFiltersCount}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Active filters chips
                  if (_currentFilter.activeFiltersCount > 0) ...[
                    SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_currentFilter.location != null)
                            _buildFilterChip(
                              'Location: ${_currentFilter.location}',
                              () => setState(() {
                                _currentFilter = _currentFilter.copyWith(clearLocation: true);
                                if (_searchController.text.isNotEmpty) {
                                  _performSearch(_searchController.text);
                                }
                              }),
                            ),
                          if (_currentFilter.propertyType != null)
                            _buildFilterChip(
                              'Type: ${_currentFilter.propertyType}',
                              () => setState(() {
                                _currentFilter = _currentFilter.copyWith(clearPropertyType: true);
                                if (_searchController.text.isNotEmpty) {
                                  _performSearch(_searchController.text);
                                }
                              }),
                            ),
                          if (_currentFilter.minPrice != null || _currentFilter.maxPrice != null)
                            _buildFilterChip(
                              'Price: ${_currentFilter.minPrice ?? "0"} - ${_currentFilter.maxPrice ?? "∞"}',
                              () => setState(() {
                                _currentFilter = _currentFilter.copyWith(
                                  clearMinPrice: true,
                                  clearMaxPrice: true,
                                );
                                if (_searchController.text.isNotEmpty) {
                                  _performSearch(_searchController.text);
                                }
                              }),
                            ),
                          if (_currentFilter.bedrooms != null)
                            _buildFilterChip(
                              '${_currentFilter.bedrooms} ${l10n.beds}',
                              () => setState(() {
                                _currentFilter = _currentFilter.copyWith(clearBedrooms: true);
                                if (_searchController.text.isNotEmpty) {
                                  _performSearch(_searchController.text);
                                }
                              }),
                            ),
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: Icon(Icons.close, size: 14),
                            label: Text(l10n.clearFilters),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Search History Dropdown
            if (_showSearchHistory) ...[
              Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText16(
                            l10n.recentSearches,
                            bold: true,
                            color: AppColors.black,
                          ),
                          TextButton(
                            onPressed: _clearAllHistory,
                            child: CustomText16(
                              l10n.clearFilters,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _searchHistory.length,
                      itemBuilder: (context, index) {
                        final historyItem = _searchHistory[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.history,
                            size: 20,
                            color: AppColors.greyText,
                          ),
                          title: Text(
                            historyItem,
                            style: TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.greyText,
                            ),
                            onPressed: () => _deleteFromHistory(historyItem),
                          ),
                          onTap: () => _selectHistoryItem(historyItem),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Search Results
            if (_showSearchResults) ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: BlocBuilder<SearchBloc, SearchState>(
                    bloc: _searchBloc,
                    builder: (context, state) {
                      if (state is SearchLoading) {
                        return Card(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      } else if (state is SearchEmpty) {
                        return Card(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                  SizedBox(height: 8),
                                  CustomText16(
                                    l10n.noResults,
                                    color: Colors.grey[600]!,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else if (state is SearchError) {
                        return Card(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                                  SizedBox(height: 8),
                                  CustomText16(
                                    'Error: ${state.message}',
                                    color: Colors.red,
                                    align: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else if (state is SearchSuccess) {
                        return _buildSearchResults(state.response, l10n, state);
                      } else if (state is SearchLoadingMore) {
                        return _buildSearchResults(state.currentResponse, l10n, state);
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ]
            // Compounds List (shown when not searching)
            else ...[
              Expanded(
                child: BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is CompoundError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              state.message,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<CompoundBloc>().add(
                                  FetchCompoundsEvent(page: 1, limit: 50),
                                );
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is CompoundSuccess) {
                      final allCompounds = state.response.data;

                      // Update pagination state
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _isLoadingMore = false;
                            _hasMoreData = allCompounds.length >= _currentPage * _itemsPerPage;
                          });
                        }
                      });

                      if (allCompounds.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No compounds found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with count
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText20(
                                  '${l10n.availableCompounds} (${state.response.total})',
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: GridView.builder(
                              controller: _scrollController,
                              scrollDirection: Axis.vertical,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.63,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: allCompounds.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Show loading indicator at the end
                                if (index == allCompounds.length) {
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final compound = allCompounds[index];
                                return AnimatedListItem(
                                  index: index,
                                  child: CompoundsName(compound: compound),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(SearchResponse response, AppLocalizations l10n, SearchState searchState) {
    final results = response.results;
    final companies = results.where((r) => r.type == 'company').toList();
    final compounds = results.where((r) => r.type == 'compound').toList();
    final units = results.where((r) => r.type == 'unit').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with result count
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText16(
                'Found ${response.totalResults} result${response.totalResults == 1 ? '' : 's'}',
                bold: true,
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: _clearSearch,
              ),
            ],
          ),
        ),

            // Companies
            if (companies.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: Colors.white,
                child: CustomText16(
                  '${l10n.companies} (${companies.length})',
                  bold: true,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 4),
              ...(_showAllCompanies ? companies : companies.take(3))
                  .map((result) => _buildCompanyResultItem(result, l10n)),
              if (companies.length > 3)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAllCompanies = !_showAllCompanies;
                    });
                  },
                  icon: Icon(
                    _showAllCompanies ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    _showAllCompanies
                        ? l10n.showLess
                        : '+ ${companies.length - 3} more',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
            ],

            // Compounds
            if (compounds.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: Colors.white,
                child: CustomText16(
                  '${l10n.compounds} (${compounds.length})',
                  bold: true,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              ...(_showAllCompounds ? compounds : compounds.take(3))
                  .map((result) => _buildCompoundResultItem(result, l10n)),
              if (compounds.length > 3)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAllCompounds = !_showAllCompounds;
                    });
                  },
                  icon: Icon(
                    _showAllCompounds ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    _showAllCompounds
                        ? l10n.showLess
                        : '+ ${compounds.length - 3} more',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
            ],

            // Units
            if (units.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText16(
                      '${l10n.units} (${response.totalResults})',
                      bold: true,
                      color: Colors.orange,
                    ),
                    if (searchState is SearchSuccess && searchState.hasMorePages)
                      CustomText14(
                        'Page ${searchState.currentPage}/${searchState.totalPages}',
                        color: Colors.grey[600]!,
                      ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              // Display units as list items (not cards)
              ...units.map((result) => _buildUnitResultListItem(result, l10n)),
              // Load more button if there are more pages
              if (searchState is SearchSuccess && searchState.hasMorePages)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _searchBloc.add(
                          LoadMoreSearchResultsEvent(
                            query: _searchController.text,
                            filter: _currentFilter,
                            page: searchState.currentPage + 1,
                          ),
                        );
                      },
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text('Load More (${response.totalResults - units.length} remaining)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ),
              // Loading indicator when loading more
              if (searchState is SearchLoadingMore)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
    );
  }

  Widget _buildCompanyResultItem(SearchResult result, AppLocalizations l10n) {
    final data = result.data as CompanySearchData;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: data.logo != null && data.logo!.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  data.logo!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.business, size: 20),
                ),
              )
            : Icon(Icons.business, size: 20),
      ),
      title: Text(
        data.name,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        data.email,
        style: TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.chevron_right, size: 20),
      onTap: () {
        _clearSearch();
        final company = Company(
          id: data.id,
          name: data.name,
          email: data.email,
          logo: data.logo,
          numberOfCompounds: data.numberOfCompounds,
          numberOfAvailableUnits: data.numberOfAvailableUnits,
          createdAt: '', sales: [], compounds: [],
        );
        Navigator.pushNamed(
          context,
          CompanyDetailScreen.routeName,
          arguments: company,
        );
      },
    );
  }

  Widget _buildCompoundResultItem(SearchResult result, AppLocalizations l10n) {
    final data = result.data as CompoundSearchData;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: data.images.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  data.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.apartment, size: 20),
                ),
              )
            : Icon(Icons.apartment, size: 20),
      ),
      title: Text(
        data.name,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        data.location,
        style: TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.chevron_right, size: 20),
      onTap: () {
        _clearSearch();
        final compound = Compound(
          id: data.id,
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
          updatedAt: '',
          companyName: data.company.name,
          companyLogo: data.company.logo,
          soldUnits: '0',
          availableUnits: data.unitsCount, sales: [],
        );
        context.pushSlideFade(
          CompoundScreen(compound: compound),
        );
      },
    );
  }

  Widget _buildUnitResultItem(SearchResult result, AppLocalizations l10n) {
    final data = result.data as UnitSearchData;

    // Don't display sold units
    if (data.status.toLowerCase() == 'sold') {
      return SizedBox.shrink();
    }

    // Use unit images, fallback to compound images if unit images are empty
    final images = data.images.isNotEmpty ? data.images : data.compound.images;

    // Use the proper price: discounted price if available, otherwise normal price, otherwise fall back
    final unitPrice = data.discountedPrice?.isNotEmpty == true
        ? data.discountedPrice!
        : (data.normalPrice?.isNotEmpty == true
            ? data.normalPrice!
            : (data.totalPrice.isNotEmpty ? data.totalPrice : (data.price ?? '0')));

    // Create Unit object from search data
    final unit = Unit(
      id: data.id,
      compoundId: data.compound.id,
      unitType: data.unitType,
      area: data.area ?? '0',
      price: unitPrice,
      bedrooms: data.numberOfBeds ?? '0',
      bathrooms: data.numberOfBaths ?? '0',
      floor: data.floor ?? '0',
      status: data.status,
      unitNumber: data.unitName?.isNotEmpty == true
          ? data.unitName!
          : (data.name.isNotEmpty ? data.name : data.code),
      deliveryDate: null,
      view: null,
      finishing: null,
      createdAt: '',
      updatedAt: '',
      images: images,
      usageType: data.usageType,
      companyName: data.compound.company.name,
      companyLogo: data.compound.company.logo,
      compoundName: data.compound.name,
      companyId: data.compound.company.id,
    );

    // Use the full UnitCard widget for consistent UI
    return UnitCard(unit: unit);
  }

  Widget _buildUnitResultListItem(SearchResult result, AppLocalizations l10n) {
    final data = result.data as UnitSearchData;

    // Don't display sold units
    if (data.status.toLowerCase() == 'sold') {
      return SizedBox.shrink();
    }

    // Use unit images, fallback to compound images if unit images are empty
    final images = data.images.isNotEmpty ? data.images : data.compound.images;

    // Use the proper price: discounted price if available, otherwise normal price, otherwise fall back
    final unitPrice = data.discountedPrice?.isNotEmpty == true
        ? data.discountedPrice!
        : (data.normalPrice?.isNotEmpty == true
            ? data.normalPrice!
            : (data.totalPrice.isNotEmpty ? data.totalPrice : (data.price ?? '0')));

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.orange.shade100,
        backgroundImage: images.isNotEmpty
            ? NetworkImage(images.first)
            : null,
        child: images.isEmpty
            ? Icon(Icons.home, size: 24, color: Colors.orange)
            : null,
      ),
      title: Text(
        data.unitName?.isNotEmpty == true
            ? data.unitName!
            : (data.name.isNotEmpty ? data.name : data.code),
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            data.compound.name,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Row(
            children: [
              if (data.numberOfBeds != null && data.numberOfBeds != '0') ...[
                Icon(Icons.bed, size: 14, color: Colors.grey[600]),
                SizedBox(width: 2),
                Text(
                  '${data.numberOfBeds}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                SizedBox(width: 8),
              ],
              if (data.numberOfBaths != null && data.numberOfBaths != '0') ...[
                Icon(Icons.bathtub, size: 14, color: Colors.grey[600]),
                SizedBox(width: 2),
                Text(
                  '${data.numberOfBaths}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                SizedBox(width: 8),
              ],
              if (data.area != null && data.area != '0') ...[
                Icon(Icons.square_foot, size: 14, color: Colors.grey[600]),
                SizedBox(width: 2),
                Text(
                  '${data.area}m²',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${unitPrice} EGP',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.mainColor,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: data.status.toLowerCase() == 'available'
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              data.status,
              style: TextStyle(
                fontSize: 10,
                color: data.status.toLowerCase() == 'available'
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        // Create full Unit object for detail screen
        final unit = Unit(
          id: data.id,
          compoundId: data.compound.id,
          unitType: data.unitType,
          area: data.area ?? '0',
          price: unitPrice,
          bedrooms: data.numberOfBeds ?? '0',
          bathrooms: data.numberOfBaths ?? '0',
          floor: data.floor ?? '0',
          status: data.status,
          unitNumber: data.unitName?.isNotEmpty == true
              ? data.unitName!
              : (data.name.isNotEmpty ? data.name : data.code),
          deliveryDate: null,
          view: null,
          finishing: null,
          createdAt: '',
          updatedAt: '',
          images: images,
          usageType: data.usageType,
          companyName: data.compound.company.name,
          companyLogo: data.compound.company.logo,
          compoundName: data.compound.name,
          companyId: data.compound.company.id,
          code: data.code,
          builtUpArea: data.area ?? '0',
          landArea: '0',
          gardenArea: '0',
          roofArea: '0',
          available: data.status.toLowerCase() != 'sold',
          isSold: data.status.toLowerCase() == 'sold',
          notes: null,
          noteId: null,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnitDetailScreen(unit: unit),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        onDeleted: onRemove,
        deleteIcon: Icon(Icons.close, size: 16),
        backgroundColor: AppColors.mainColor.withOpacity(0.1),
        labelStyle: TextStyle(
          color: AppColors.mainColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
