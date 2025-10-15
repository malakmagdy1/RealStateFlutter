import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/widget/button/showAll.dart';
import 'package:real/feature/home/presentation/widget/Image_slide.dart';
import 'package:real/feature/home/presentation/widget/sale_slider.dart';
import 'package:real/feature/home/presentation/widget/company_name_scrol.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';
import 'package:real/feature/company/presentation/bloc/company_bloc.dart';
import 'package:real/feature/company/presentation/bloc/company_event.dart';
import 'package:real/feature/company/presentation/bloc/company_state.dart';
import 'package:real/feature/company/presentation/screen/company_detail_screen.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature/compound/presentation/bloc/compound_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import 'package:real/feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_state.dart';
import 'package:real/feature/sale/presentation/bloc/sale_bloc.dart';
import 'package:real/feature/sale/presentation/bloc/sale_state.dart';
import 'package:real/feature/search/data/repositories/search_repository.dart';
import 'package:real/feature/search/data/services/search_history_service.dart';
import 'package:real/feature/search/data/models/search_filter_model.dart';
import 'package:real/feature/search/presentation/bloc/search_bloc.dart';
import 'package:real/feature/search/presentation/bloc/search_event.dart';
import 'package:real/feature/search/presentation/bloc/search_state.dart';
import 'package:real/feature/search/data/models/search_result_model.dart';
import 'package:real/feature/search/presentation/widget/search_filter_bottom_sheet.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/presentation/screen/unit_detail_screen.dart';
import 'package:real/feature/home/presentation/CompoundScreen.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late SearchBloc _searchBloc;
  late Compound compound;
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  bool _showSearchResults = false;
  bool _showSearchHistory = false;
  Timer? _debounceTimer;
  bool _showAllAvailableCompounds = false;
  bool _showAllRecommendedCompounds = false;
  List<String> _searchHistory = [];
  SearchFilter _currentFilter = SearchFilter.empty();

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

    // Fetch companies and compounds when screen loads
    context.read<CompanyBloc>().add(const FetchCompaniesEvent());
    context.read<CompoundBloc>().add(const FetchCompoundsEvent(page: 1, limit: 50));
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
    super.dispose();
  }

  void _performSearch(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // If both query is empty AND no filters are active, clear search
    if (query.trim().isEmpty && _currentFilter.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _showSearchHistory = _searchFocusNode.hasFocus && _searchHistory.isNotEmpty;
      });
      _searchBloc.add(const ClearSearchEvent());
      return;
    }

    setState(() {
      _showSearchResults = true;
      _showSearchHistory = false;
    });

    // Wait 500ms before performing search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
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
    });
    _searchBloc.add(SearchQueryEvent(query: query));
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showSearchResults = false;
    });
    _searchBloc.add(const ClearSearchEvent());
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    if (state is UserSuccess) {
                      return CustomText20("Welcome ${state.user.name}");
                    }
                    return CustomText20("Welcome");
                  },
                ),
                const SizedBox(height: 16),

                // 🔍 Search bar with filter button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (value) {
                          setState(() {
                            _performSearch(value);
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search for companies, compounds, or units...",
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          contentPadding: const EdgeInsets.symmetric(
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
                    const SizedBox(width: 8),
                    // Filter button with badge
                    Stack(
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
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.mainColor,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  '${_currentFilter.activeFiltersCount}',
                                  style: const TextStyle(
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
                  const SizedBox(height: 12),
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
                            '${_currentFilter.bedrooms} Beds',
                            () => setState(() {
                              _currentFilter = _currentFilter.copyWith(clearBedrooms: true);
                              if (_searchController.text.isNotEmpty) {
                                _performSearch(_searchController.text);
                              }
                            }),
                          ),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.close, size: 14),
                          label: const Text('Clear All'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Search History Dropdown
                if (_showSearchHistory) ...[
                  const SizedBox(height: 8),
                  Card(
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText16(
                                'Recent Searches',
                                bold: true,
                                color: AppColors.black,
                              ),
                              TextButton(
                                onPressed: _clearAllHistory,
                                child: CustomText16(
                                  'Clear All',
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _searchHistory.length,
                          itemBuilder: (context, index) {
                            final historyItem = _searchHistory[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.history,
                                size: 20,
                                color: Colors.grey,
                              ),
                              title: Text(
                                historyItem,
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.grey,
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
                  const SizedBox(height: 16),
                  BlocBuilder<SearchBloc, SearchState>(
                    bloc: _searchBloc,
                    builder: (context, state) {
                      if (state is SearchLoading) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      } else if (state is SearchEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  CustomText16(
                                    'No results found',
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
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                                  const SizedBox(height: 8),
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
                        return _buildSearchResults(state.response);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // 🏢 Companies section
                CustomText20("Companies name"),
                const SizedBox(height: 8),

                BlocBuilder<CompanyBloc, CompanyState>(
                  builder: (context, state) {
                    if (state is CompanyLoading) {
                      return const SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (state is CompanySuccess) {
                      if (state.response.companies.isEmpty) {
                        return SizedBox(
                          height: 100,
                          child: Center(
                            child: CustomText16('No companies found', color: AppColors.grey),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.response.companies.length,
                          itemBuilder: (context, index) {
                            final company = state.response.companies[index];
                            return CompanyName(
                              company: company,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CompanyDetailScreen(company: company),
                                  ),
                                ).then((_) {
                                  context.read<CompoundBloc>().add(const FetchCompoundsEvent(page: 1, limit: 50));
                                });
                              },
                            );

                          },
                        ),
                      );
                    } else if (state is CompanyError) {
                      return SizedBox(
                        height: 100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText16(
                                'Error: ${state.message}',
                                color: Colors.red,
                                align: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<CompanyBloc>().add(
                                        const FetchCompaniesEvent(),
                                      );
                                },
                                child: CustomText16('Retry', color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 100);
                  },
                ),

                // Sales Slider
                BlocBuilder<SaleBloc, SaleState>(
                  builder: (context, state) {
                    print('[HomeScreen] SaleBloc State: ${state.runtimeType}');

                    if (state is SaleLoading) {
                      return SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    if (state is SaleError) {
                      print('[HomeScreen] SaleBloc Error: ${state.message}');
                      // Show error but don't break the UI
                      return SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'Sale data unavailable',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    if (state is SaleSuccess) {
                      print('[HomeScreen] SaleSuccess: ${state.response.sales.length} sales');

                      // Filter only currently active sales
                      final activeSales = state.response.sales
                          .where((sale) => sale.isCurrentlyActive)
                          .toList();

                      print('[HomeScreen] Active sales: ${activeSales.length}');

                      // If we have active sales, show them
                      if (activeSales.isNotEmpty) {
                        print('[HomeScreen] Showing ${activeSales.length} active sales');
                        return SaleSlider(sales: activeSales);
                      }
                    }

                    // Fallback to default asset images if no active sales
                    print('[HomeScreen] Falling back to default asset images');
                    return SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_offer, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                'No active sales at the moment',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 🏘️ Compounds section
                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    final compounds = (state is CompoundSuccess) ? state.response.data : [];
                    final hasMultipleCompounds = compounds.length > 3;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with Show All Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText20("Available Compounds"),
                            if (hasMultipleCompounds && state is CompoundSuccess)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showAllAvailableCompounds = !_showAllAvailableCompounds;
                                  });
                                },
                                icon: Icon(
                                  _showAllAvailableCompounds ? Icons.expand_less : Icons.expand_more,
                                  size: 18,
                                  color: AppColors.mainColor,
                                ),
                                label: Text(
                                  _showAllAvailableCompounds ? 'Show Less' : 'Show All',
                                  style: TextStyle(
                                    color: AppColors.mainColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),

                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundLoading) {
                      return const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (state is CompoundSuccess) {
                      if (state.response.data.isEmpty) {
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: CustomText16('No compounds found', color: AppColors.grey),
                          ),
                        );
                      }

                      final compounds = state.response.data;
                      final displayCount = _showAllAvailableCompounds
                          ? compounds.length
                          : (compounds.length > 3 ? 3 : compounds.length);

                      return SizedBox(
                        height: 440,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayCount,
                          itemBuilder: (context, index) {
                            final compound = compounds[index];
                            return SizedBox(
                              width: 320,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: CompoundsName(compound: compound),
                              ),
                            );
                          },
                        ),
                      );
                    } else if (state is CompoundError) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText16(
                                'Error: ${state.message}',
                                color: Colors.red,
                                align: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<CompoundBloc>().add(
                                        const FetchCompoundsEvent(),
                                      );
                                },
                                child: CustomText16('Retry', color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 200);
                  },
                ),

                // Recommended Compounds Section
                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundSuccess) {
                      final compoundsWithImages = state.response.data
                          .where((compound) => compound.images.isNotEmpty)
                          .toList();

                      final recommendedCompounds = compoundsWithImages.isNotEmpty
                          ? compoundsWithImages
                          : state.response.data;

                      final hasMultipleRecommended = recommendedCompounds.length > 3;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with Show All Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText20("Recommended Compounds"),
                              if (hasMultipleRecommended)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showAllRecommendedCompounds = !_showAllRecommendedCompounds;
                                    });
                                  },
                                  icon: Icon(
                                    _showAllRecommendedCompounds ? Icons.expand_less : Icons.expand_more,
                                    size: 18,
                                    color: AppColors.mainColor,
                                  ),
                                  label: Text(
                                    _showAllRecommendedCompounds ? 'Show Less' : 'Show All',
                                    style: TextStyle(
                                      color: AppColors.mainColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText20("Recommended Compounds"),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),

                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundLoading) {
                      return const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (state is CompoundSuccess) {
                      if (state.response.data.isEmpty) {
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: CustomText16('No recommended compounds found', color: AppColors.grey),
                          ),
                        );
                      }

                      // Show compounds with images as recommended, or all if none have images
                      final compoundsWithImages = state.response.data
                          .where((compound) => compound.images.isNotEmpty)
                          .toList();

                      final recommendedCompounds = compoundsWithImages.isNotEmpty
                          ? compoundsWithImages
                          : state.response.data;

                      final displayCount = _showAllRecommendedCompounds
                          ? recommendedCompounds.length
                          : (recommendedCompounds.length > 3 ? 3 : recommendedCompounds.length);

                      return SizedBox(
                        height: 440,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayCount,
                          itemBuilder: (context, index) {
                            final compound = recommendedCompounds[index];
                            return SizedBox(
                              width: 320,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: CompoundsName(compound: compound),
                              ),
                            );
                          },
                        ),
                      );
                    } else if (state is CompoundError) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText16(
                                'Error: ${state.message}',
                                color: Colors.red,
                                align: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<CompoundBloc>().add(
                                        const FetchCompoundsEvent(),
                                      );
                                },
                                child: CustomText16('Retry', color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 200);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(SearchResponse response) {
    final results = response.results;
    final companies = results.where((r) => r.type == 'company').toList();
    final compounds = results.where((r) => r.type == 'compound').toList();
    final units = results.where((r) => r.type == 'unit').toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText16(
                  'Found ${response.totalResults} result${response.totalResults == 1 ? '' : 's'}',
                  bold: true,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSearch,
                ),
              ],
            ),
            const Divider(),

            // Companies
            if (companies.isNotEmpty) ...[
              const SizedBox(height: 8),
              CustomText16(
                'Companies (${companies.length})',
                bold: true,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              ...(_showAllCompanies ? companies : companies.take(3))
                  .map((result) => _buildCompanyResultItem(result)),
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
                        ? 'Show Less'
                        : '+ ${companies.length - 3} more',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
            ],

            // Compounds
            if (compounds.isNotEmpty) ...[
              const SizedBox(height: 16),
              CustomText16(
                'Compounds (${compounds.length})',
                bold: true,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              ...(_showAllCompounds ? compounds : compounds.take(3))
                  .map((result) => _buildCompoundResultItem(result)),
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
                        ? 'Show Less'
                        : '+ ${compounds.length - 3} more',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
            ],

            // Units
            if (units.isNotEmpty) ...[
              const SizedBox(height: 16),
              CustomText16(
                'Units (${units.length})',
                bold: true,
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              ...(_showAllUnits ? units : units.take(3))
                  .map((result) => _buildUnitResultItem(result)),
              if (units.length > 3)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAllUnits = !_showAllUnits;
                    });
                  },
                  icon: Icon(
                    _showAllUnits ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    _showAllUnits
                        ? 'Show Less'
                        : '+ ${units.length - 3} more',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyResultItem(SearchResult result) {
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
                      const Icon(Icons.business, size: 20),
                ),
              )
            : const Icon(Icons.business, size: 20),
      ),
      title: Text(
        data.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        data.email,
        style: const TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        _clearSearch();
        final company = Company(
          id: data.id,
          name: data.name,
          email: data.email,
          logo: data.logo,
          numberOfCompounds: data.numberOfCompounds,
          numberOfAvailableUnits: data.numberOfAvailableUnits,
          createdAt: '',
        );
        Navigator.pushNamed(
          context,
          CompanyDetailScreen.routeName,
          arguments: company,
        );
      },
    );
  }

  Widget _buildCompoundResultItem(SearchResult result) {
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
                      const Icon(Icons.apartment, size: 20),
                ),
              )
            : const Icon(Icons.apartment, size: 20),
      ),
      title: Text(
        data.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        data.location,
        style: const TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
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
          availableUnits: data.unitsCount,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompoundScreen(compound: compound),
          ),
        );
      },
    );
  }

  Widget _buildUnitResultItem(SearchResult result) {
    final data = result.data as UnitSearchData;

    Color getStatusColor() {
      switch (data.status.toLowerCase()) {
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _clearSearch();
          final unit = Unit(
            id: data.id,
            compoundId: data.compound.id,
            unitType: data.unitType,
            area: '0',
            price: data.price ?? data.totalPrice,
            bedrooms: data.numberOfBeds ?? '0',
            bathrooms: '0',
            floor: '0', // Floor info not available in search results
            status: data.status,
            unitNumber: data.code,
            createdAt: '',
            updatedAt: '',
            images: data.images,
            usageType: data.usageType,
            companyName: data.compound.company.name,
            companyLogo: data.compound.company.logo,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UnitDetailScreen(unit: unit),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with favorite button
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: data.images.isNotEmpty
                        ? Image.network(
                            data.images.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.home, size: 30, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.home, size: 30, color: Colors.grey),
                          ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: BlocBuilder<UnitFavoriteBloc, UnitFavoriteState>(
                      builder: (context, state) {
                        final bloc = context.read<UnitFavoriteBloc>();
                        final unit = Unit(
                          id: data.id,
                          compoundId: data.compound.id,
                          unitType: data.unitType,
                          area: '0',
                          price: data.price ?? data.totalPrice,
                          bedrooms: data.numberOfBeds ?? '0',
                          bathrooms: '0',
                          floor: '0',
                          status: data.status,
                          unitNumber: data.code,
                          createdAt: '',
                          updatedAt: '',
                          images: data.images,
                          usageType: data.usageType,
                          companyName: data.compound.company.name,
                          companyLogo: data.compound.company.logo,
                        );
                        final isFavorite = bloc.isFavorite(unit);

                        return GestureDetector(
                          onTap: () => bloc.toggleFavorite(unit),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.9),
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
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unit Name & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: getStatusColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Compound name
                    Text(
                      data.compound.name,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Details Row 1
                    Row(
                      children: [
                        if (data.usageType != null) ...[
                          Icon(Icons.category, size: 14, color: AppColors.mainColor),
                          const SizedBox(width: 4),
                          Text(
                            data.usageType!,
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (data.numberOfBeds != null) ...[
                          Icon(Icons.bed, size: 14, color: AppColors.mainColor),
                          const SizedBox(width: 4),
                          Text(
                            '${data.numberOfBeds} Beds',
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Details Row 2
                    Row(
                      children: [
                        if (data.code.isNotEmpty) ...[
                          Icon(Icons.tag, size: 14, color: AppColors.mainColor),
                          const SizedBox(width: 4),
                          Text(
                            'Unit #${data.code}',
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Text(
                      'EGP ${data.price ?? data.totalPrice}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        onDeleted: onRemove,
        deleteIcon: const Icon(Icons.close, size: 16),
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
