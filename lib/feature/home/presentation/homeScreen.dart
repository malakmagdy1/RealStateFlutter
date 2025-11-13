import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/feature/home/presentation/widget/sale_slider.dart';
import 'package:real/feature/home/presentation/widget/company_name_scrol.dart';
import 'package:real/feature/home/presentation/widget/compunds_name.dart';
import 'package:real/feature/company/presentation/bloc/company_bloc.dart';
import 'package:real/feature/company/presentation/bloc/company_event.dart';
import 'package:real/feature/company/presentation/bloc/company_state.dart';
import 'package:real/feature/company/presentation/screen/company_detail_screen.dart';
import 'package:real/feature/company/presentation/screen/companies_screen.dart';
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
import 'package:real/feature/compound/presentation/widget/unit_card.dart';
import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/home/presentation/CompoundScreen.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:real/core/animations/animated_list_item.dart';
import 'package:real/core/animations/page_transitions.dart';
// AI chat imports
import 'package:real/feature/ai_chat/presentation/screen/ai_chat_screen.dart';
import 'package:real/feature/ai_chat/presentation/bloc/chat_bloc.dart';

import '../../compound/presentation/bloc/favorite/compound_favorite_bloc.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = '/home';

  HomeScreen({super.key});

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
  int _recommendedDisplayCount = 10;
  int _availableDisplayCount = 10;
  final ScrollController _recommendedScrollController = ScrollController();
  final ScrollController _availableScrollController = ScrollController();
  bool _isLoadingMoreRecommended = false;
  bool _isLoadingMoreAvailable = false;
  List<String> _searchHistory = [];
  SearchFilter _currentFilter = SearchFilter.empty();

  // All search results shown by default (no "show more" buttons)

  // New Arrivals & Recently Updated & Recommended (24h) & Recently Updated (24h)
  List<Unit> _newArrivals = [];
  List<Unit> _recentlyUpdated = [];
  List<Unit> _recommendedUnits = [];
  List<Unit> _updated24Hours = [];
  bool _isLoadingNewArrivals = false;
  bool _isLoadingRecentlyUpdated = false;
  bool _isLoadingRecommendedUnits = false;
  bool _isLoadingUpdated24Hours = false;
  final CompoundWebServices _webServices = CompoundWebServices();

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
    context.read<CompanyBloc>().add(FetchCompaniesEvent());
    context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: 50));

    // Fetch new arrivals and updated 24h
    _fetchNewArrivals();
    _fetchUpdated24Hours();

    // Add scroll listeners for pagination
    _recommendedScrollController.addListener(_onRecommendedScroll);
    _availableScrollController.addListener(_onAvailableScroll);
  }

  void _onRecommendedScroll() {
    if (_isLoadingMoreRecommended) return;

    final maxScroll = _recommendedScrollController.position.maxScrollExtent;
    final currentScroll = _recommendedScrollController.position.pixels;

    // Load more when 80% scrolled
    if (currentScroll >= maxScroll * 0.8) {
      setState(() {
        _isLoadingMoreRecommended = true;
        _recommendedDisplayCount += 10;
      });

      // Small delay to show loading indicator
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isLoadingMoreRecommended = false;
          });
        }
      });
    }
  }

  void _onAvailableScroll() {
    if (_isLoadingMoreAvailable) return;

    final maxScroll = _availableScrollController.position.maxScrollExtent;
    final currentScroll = _availableScrollController.position.pixels;

    // Load more when 80% scrolled
    if (currentScroll >= maxScroll * 0.8) {
      setState(() {
        _isLoadingMoreAvailable = true;
        _availableDisplayCount += 10;
      });

      // Small delay to show loading indicator
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isLoadingMoreAvailable = false;
          });
        }
      });
    }
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
    _recommendedScrollController.dispose();
    _availableScrollController.dispose();
    super.dispose();
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
    });

    // Wait 500ms before performing search
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _searchBloc.add(SearchQueryEvent(
        query: query.trim(),
        type: 'unit', // Always search for units
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
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    if (state is UserSuccess) {
                      return ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          "${l10n.welcome} ${state.user.name.split(' ').first}",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),

                      );
                    }
                    return ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        l10n.welcome,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),

                // Active filters chips
                if (_currentFilter.activeFiltersCount > 0) ...[
                  SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        if (_currentFilter.location != null)
                          _buildFilterChip(
                            'Location: ${_currentFilter.location}',
                            () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(clearLocation: true);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.propertyType != null)
                          _buildFilterChip(
                            'Type: ${_currentFilter.propertyType}',
                            () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(clearPropertyType: true);
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.minPrice != null || _currentFilter.maxPrice != null)
                          _buildFilterChip(
                            'Price: ${_currentFilter.minPrice ?? "0"} - ${_currentFilter.maxPrice ?? "∞"}',
                            () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(
                                  clearMinPrice: true,
                                  clearMaxPrice: true,
                                );
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        if (_currentFilter.bedrooms != null)
                          _buildFilterChip(
                            '${_currentFilter.bedrooms} ${l10n.beds}',
                            () {
                              setState(() {
                                _currentFilter = _currentFilter.copyWith(clearBedrooms: true);
                              });
                              _performSearch(_searchController.text);
                            },
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

                // Search History Dropdown
                if (_showSearchHistory) ...[
                  SizedBox(height: 8),
                  Card(
                    elevation: 4,
                    child: Column(
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
                  SizedBox(height: 16),
                  BlocBuilder<SearchBloc, SearchState>(
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
                        return _buildSearchResults(state.response, l10n);
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],

                SizedBox(height: 24),

                // 🏢 Companies section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText20(l10n.companiesName),
                    TextButton(
                      onPressed: () {
                        context.pushSlideFade(CompaniesScreen());
                      },
                      child: Row(
                        children: [
                          CustomText14('View All', color: AppColors.mainColor),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.mainColor),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                BlocBuilder<CompanyBloc, CompanyState>(
                  builder: (context, state) {
                    if (state is CompanyLoading) {
                      return SizedBox(
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
                            child: CustomText16(l10n.noCompanies, color: AppColors.grey),
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
                                context.pushSlideFade(
                                  CompanyDetailScreen(company: company),
                                ).then((_) {
                                  context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: 50));
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
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<CompanyBloc>().add(
                                        FetchCompaniesEvent(),
                                      );
                                },
                                child: CustomText16(l10n.retry, color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SizedBox(height: 100);
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
                          child: Center(
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
                                SizedBox(height: 8),
                                Text(
                                  l10n.saleDataUnavailable,
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
                              Icon(Icons.local_offer, size: 40, color: AppColors.greyText),
                              SizedBox(height: 8),
                              Text(
                                l10n.noActiveSales,
                                style: TextStyle(color: AppColors.greyText),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),

                // 🆕 New Arrivals Section
                _buildNewArrivalsSection(l10n),
                SizedBox(height: 24),

                // 🔄 Updated Units (24h)
                _buildUpdated24HoursSection(l10n),
                SizedBox(height: 24),

                // Recommended Compounds Section
                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundLoading) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText20(l10n.recommendedCompounds),
                          SizedBox(height: 12),
                          SizedBox(
                            height: 280,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ],
                      );
                    } else if (state is CompoundSuccess) {
                      if (state.response.data.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText20(l10n.recommendedCompounds),
                            SizedBox(height: 12),
                            SizedBox(
                              height: 280,
                              child: Center(
                                child: CustomText16(l10n.noCompoundsAvailable, color: AppColors.grey),
                              ),
                            ),
                          ],
                        );
                      }

                      // Show compounds with images as recommended, or all if none have images
                      final compoundsWithImages = state.response.data
                          .where((compound) => compound.images.isNotEmpty)
                          .toList();

                      final recommendedCompounds = compoundsWithImages.isNotEmpty
                          ? compoundsWithImages
                          : state.response.data;

                      // Use pagination - show up to _recommendedDisplayCount items
                      final displayCount = recommendedCompounds.length > _recommendedDisplayCount
                          ? _recommendedDisplayCount
                          : recommendedCompounds.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          CustomText20(l10n.recommendedCompounds),
                          SizedBox(height: 12),
                          // Horizontal scroll view with pagination
                          SizedBox(
                            height: 280,
                            child: ListView.builder(
                              controller: _recommendedScrollController,
                              scrollDirection: Axis.horizontal,
                              physics: BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              itemCount: displayCount + (_isLoadingMoreRecommended && displayCount < recommendedCompounds.length ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Show loading indicator at end
                                if (index == displayCount) {
                                  return Container(
                                    width: 60,
                                    margin: EdgeInsets.only(right: 12),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.mainColor,
                                      ),
                                    ),
                                  );
                                }

                                final compound = recommendedCompounds[index];
                                return Container(
                                  width: 200,
                                  margin: EdgeInsets.only(
                                    right: index < displayCount - 1 ? 12 : 0,
                                  ),
                                  child: CompoundsName(compound: compound),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    } else if (state is CompoundError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText20(l10n.recommendedCompounds),
                          SizedBox(height: 12),
                          SizedBox(
                            height: 280,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomText16(
                                    'Error: ${state.message}',
                                    color: Colors.red,
                                    align: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<CompoundBloc>().add(
                                            FetchCompoundsEvent(),
                                          );
                                    },
                                    child: CustomText16(l10n.retry, color: AppColors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText20(l10n.recommendedCompounds),
                        SizedBox(height: 280),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      // AI Chat - Property Assistant
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Capture BLoCs from current context before navigation
          final unitFavoriteBloc = context.read<UnitFavoriteBloc>();
          final compoundFavoriteBloc = context.read<CompoundFavoriteBloc>();

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (context) => ChatBloc(),
                  ),
                  BlocProvider.value(
                    value: unitFavoriteBloc,
                  ),
                  BlocProvider.value(
                    value: compoundFavoriteBloc,
                  ),
                ],
                child: const AiChatScreen(),
              ),
            ),
          );
        },
        backgroundColor: AppColors.mainColor,
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text(
          'AI Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(SearchResponse response, AppLocalizations l10n) {
    final results = response.results;
    final companies = results.where((r) => r.type == 'company').toList();
    final compounds = results.where((r) => r.type == 'compound').toList();
    final units = results.where((r) => r.type == 'unit').toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
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
                  icon: Icon(Icons.close),
                  onPressed: _clearSearch,
                ),
              ],
            ),
            Divider(),

            // Companies
            if (companies.isNotEmpty) ...[
              SizedBox(height: 8),
              CustomText16(
                '${l10n.companies} (${companies.length})',
                bold: true,
                color: Colors.blue,
              ),
              SizedBox(height: 8),
              ...companies.map((result) => _buildCompanyResultItem(result, l10n)),
            ],

            // Compounds
            if (compounds.isNotEmpty) ...[
              SizedBox(height: 16),
              CustomText16(
                '${l10n.compounds} (${compounds.length})',
                bold: true,
                color: Colors.green,
              ),
              SizedBox(height: 8),
              ...compounds.map((result) => _buildCompoundResultItem(result, l10n)),
            ],

            // Units
            if (units.isNotEmpty) ...[
              SizedBox(height: 16),
              CustomText16(
                '${l10n.units} (${units.length})',
                bold: true,
                color: Colors.orange,
              ),
              SizedBox(height: 8),
              ...units.map((result) => _buildUnitResultItem(result, l10n)),
            ],
          ],
        ),
      ),
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

  String _formatUnitPrice(String? price, String? totalPrice, AppLocalizations l10n) {
    // Try price first, then totalPrice
    final priceStr = price ?? totalPrice;

    // If both are null or empty or "0", show Contact for Price
    if (priceStr == null || priceStr.isEmpty || priceStr == '0' || priceStr == '0.0') {
      return 'Contact for Price';
    }

    try {
      final numPrice = double.parse(priceStr);
      if (numPrice == 0) {
        return 'Contact for Price';
      }

      // Format the price
      if (numPrice >= 1000000) {
        return '${l10n.egp} ${(numPrice / 1000000).toStringAsFixed(2)}M';
      } else if (numPrice >= 1000) {
        return '${l10n.egp} ${(numPrice / 1000).toStringAsFixed(0)}K';
      }
      return '${l10n.egp} ${numPrice.toStringAsFixed(0)}';
    } catch (e) {
      return 'Contact for Price';
    }
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

  // Fetch new arrivals
  Future<void> _fetchNewArrivals() async {
    if (_isLoadingNewArrivals) return;

    setState(() {
      _isLoadingNewArrivals = true;
    });

    try {
      final response = await _webServices.getNewArrivals(limit: 10);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<Unit> units = [];

        // Check if data has nested 'data' property (pagination structure)
        if (data is Map && data['data'] != null) {
          units = (data['data'] as List)
              .map((unit) {
                final unitJson = Map<String, dynamic>.from(unit as Map<String, dynamic>);
                // Parse action as change_type if present
                if (unitJson['action'] != null) {
                  unitJson['change_type'] = unitJson['action'];
                  unitJson['is_updated'] = true;
                }
                return Unit.fromJson(unitJson);
              })
              .toList();
        } else if (data is List) {
          // Fallback: if data is directly a list
          units = data
              .map((unit) {
                final unitJson = Map<String, dynamic>.from(unit as Map<String, dynamic>);
                // Parse action as change_type if present
                if (unitJson['action'] != null) {
                  unitJson['change_type'] = unitJson['action'];
                  unitJson['is_updated'] = true;
                }
                return Unit.fromJson(unitJson);
              })
              .toList();
        }

        if (mounted) {
          setState(() {
            _newArrivals = units;
            _isLoadingNewArrivals = false;
          });
        }
      }
    } catch (e) {
      print('[HomeScreen] Error fetching new arrivals: $e');
      if (mounted) {
        setState(() {
          _isLoadingNewArrivals = false;
        });
      }
    }
  }

  // Fetch recently updated
  Future<void> _fetchRecentlyUpdated() async {
    if (_isLoadingRecentlyUpdated) return;

    setState(() {
      _isLoadingRecentlyUpdated = true;
    });

    try {
      final response = await _webServices.getRecentlyUpdated(limit: 10);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<Unit> units = [];

        // Check if data has nested 'data' property (pagination structure)
        if (data is Map && data['data'] != null) {
          units = (data['data'] as List)
              .map((unit) => Unit.fromJson(unit as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          // Fallback: if data is directly a list
          units = data
              .map((unit) => Unit.fromJson(unit as Map<String, dynamic>))
              .toList();
        }

        if (mounted) {
          setState(() {
            _recentlyUpdated = units;
            _isLoadingRecentlyUpdated = false;
          });
        }
      }
    } catch (e) {
      print('[HomeScreen] Error fetching recently updated: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecentlyUpdated = false;
        });
      }
    }
  }

  // Fetch recommended units (last 24 hours)
  Future<void> _fetchRecommendedUnits() async {
    if (_isLoadingRecommendedUnits) return;

    setState(() {
      _isLoadingRecommendedUnits = true;
    });

    try {
      final response = await _webServices.getNewUnitsLast24Hours(limit: 10);

      if (response['success'] == true && response['data'] != null) {
        final units = (response['data'] as List)
            .map((unit) => Unit.fromJson(unit as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _recommendedUnits = units;
            _isLoadingRecommendedUnits = false;
          });
        }
      }
    } catch (e) {
      print('[HomeScreen] Error fetching recommended units: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommendedUnits = false;
        });
      }
    }
  }

  // Fetch updated units (last 24 hours)
  Future<void> _fetchUpdated24Hours() async {
    if (_isLoadingUpdated24Hours) return;

    setState(() {
      _isLoadingUpdated24Hours = true;
    });

    try {
      final response = await _webServices.getUpdatedUnitsLast24Hours(limit: 10);

      if (response['success'] == true && response['data'] != null) {
        // The data is nested in activities object
        final data = response['data'];
        List<Unit> units = [];

        if (data is Map && data['activities'] != null) {
          final activities = data['activities'];
          if (activities is List) {
            units = activities
                .map((activity) {
                  // Extract unit from activity
                  if (activity['unit'] != null) {
                    final unitJson = Map<String, dynamic>.from(activity['unit'] as Map<String, dynamic>);
                    // Add action as change_type
                    if (activity['action'] != null) {
                      unitJson['change_type'] = activity['action'];
                      unitJson['is_updated'] = true;
                    }
                    // Add properties (changes and original values)
                    if (activity['properties'] != null) {
                      unitJson['change_properties'] = activity['properties'];
                    }
                    return Unit.fromJson(unitJson);
                  }
                  return null;
                })
                .whereType<Unit>() // Filter out nulls
                .toList();
          }
        }

        if (mounted) {
          setState(() {
            _updated24Hours = units;
            _isLoadingUpdated24Hours = false;
          });
        }
      }
    } catch (e) {
      print('[HomeScreen] Error fetching updated units (24h): $e');
      if (mounted) {
        setState(() {
          _isLoadingUpdated24Hours = false;
        });
      }
    }
  }

  // Build New Arrivals Section
  Widget _buildNewArrivalsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.fiber_new, color: AppColors.mainColor, size: 24),
            SizedBox(width: 8),
            CustomText20(
              'New Arrivals',
              bold: true,
              color: AppColors.black,
            ),
            Spacer(),
            if (_newArrivals.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.tealAccent],                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_newArrivals.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        _isLoadingNewArrivals
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.mainColor),
                ),
              )
            : _newArrivals.isEmpty
                ? Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: AppColors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No new arrivals yet',
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _newArrivals.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 200,
                          margin: EdgeInsets.only(
                            right: index < _newArrivals.length - 1 ? 12 : 0,
                          ),
                          child: AnimatedListItem(
                            index: index,
                            delay: Duration(milliseconds: 100),
                            child: UnitCard(unit: _newArrivals[index]),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  // Build Recently Updated Section
  Widget _buildRecentlyUpdatedSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.update, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            CustomText20(
              'Recently Updated',
              bold: true,
              color: AppColors.black,
            ),
            Spacer(),
            if (_recentlyUpdated.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_recentlyUpdated.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        _isLoadingRecentlyUpdated
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              )
            : _recentlyUpdated.isEmpty
                ? Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: AppColors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No recent updates',
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      itemCount: _recentlyUpdated.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 200,
                          margin: EdgeInsets.only(
                            right: index < _recentlyUpdated.length - 1 ? 12 : 0,
                          ),
                          child: AnimatedListItem(
                            index: index,
                            delay: Duration(milliseconds: 100),
                            child: UnitCard(unit: _recentlyUpdated[index]),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  // Build Recommended Section (24h new units)
  Widget _buildRecommendedSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.recommend, color: Colors.purple, size: 24),
            SizedBox(width: 8),
            CustomText20(
              'Recommended for You',
              bold: true,
              color: AppColors.black,
            ),
            Spacer(),
            if (_recommendedUnits.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.purpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_recommendedUnits.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        _isLoadingRecommendedUnits
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.purple),
                ),
              )
            : _recommendedUnits.isEmpty
                ? Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: AppColors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No new units in the last 24 hours',
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _recommendedUnits.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 200,
                          margin: EdgeInsets.only(
                            right: index < _recommendedUnits.length - 1 ? 12 : 0,
                          ),
                          child: AnimatedListItem(
                            index: index,
                            delay: Duration(milliseconds: 100),
                            child: UnitCard(unit: _recommendedUnits[index]),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  // Build Updated Units (24h) Section
  Widget _buildUpdated24HoursSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_toggle_off, color: Colors.teal, size: 24),
            SizedBox(width: 8),
            CustomText20(
              'Updated in Last 24 Hours',
              bold: true,
              color: AppColors.black,
            ),
            Spacer(),
            if (_updated24Hours.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.tealAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_updated24Hours.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        _isLoadingUpdated24Hours
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.teal),
                ),
              )
            : _updated24Hours.isEmpty
                ? Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: AppColors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No units updated in the last 24 hours',
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _updated24Hours.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 200,
                          margin: EdgeInsets.only(
                            right: index < _updated24Hours.length - 1 ? 12 : 0,
                          ),
                          child: AnimatedListItem(
                            index: index,
                            delay: Duration(milliseconds: 100),
                            child: UnitCard(unit: _updated24Hours[index]),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }
}
