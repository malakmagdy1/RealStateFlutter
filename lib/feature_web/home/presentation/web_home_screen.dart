import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/feature/company/presentation/bloc/company_bloc.dart';
import 'package:real/feature/company/presentation/bloc/company_event.dart';
import 'package:real/feature/company/presentation/bloc/company_state.dart';
import '../../../core/utils/text_style.dart';
import '../../company/presentation/web_company_detail_screen.dart';
import '../../../feature/compound/presentation/bloc/compound_bloc.dart';
import '../../../feature/compound/presentation/bloc/compound_event.dart';
import '../../../feature/compound/presentation/bloc/compound_state.dart';
import '../../../feature/home/presentation/widget/company_name_scrol.dart';
import '../../../feature/home/presentation/widget/compunds_name.dart';
import '../../widgets/web_compound_card.dart';
import '../../../feature/home/presentation/widget/sale_slider.dart';
import '../../../feature/auth/presentation/bloc/user_bloc.dart';
import '../../../feature/auth/presentation/bloc/user_state.dart';
import '../../../feature/sale/presentation/bloc/sale_bloc.dart';
import '../../../feature/sale/presentation/bloc/sale_state.dart';
import '../../../feature/search/data/repositories/search_repository.dart';
import '../../../feature/search/data/services/search_history_service.dart';
import '../../../feature/search/data/models/search_filter_model.dart';
import '../../../feature/search/presentation/bloc/search_bloc.dart';
import '../../../feature/search/presentation/bloc/search_event.dart';
import '../../../feature/search/presentation/bloc/search_state.dart';
import '../../../feature/search/data/models/search_result_model.dart';
import '../../../feature/search/presentation/widget/search_filter_bottom_sheet.dart';
import '../../../feature/compound/data/models/compound_model.dart';
import '../../../feature/compound/data/models/unit_model.dart';
import '../../../feature/compound/presentation/screen/unit_detail_screen.dart';
import '../../../feature/home/presentation/CompoundScreen.dart';
import '../../../feature/company/data/models/company_model.dart';
import '../../../feature/compound/presentation/bloc/favorite/unit_favorite_bloc.dart';
import '../../../feature/compound/presentation/bloc/favorite/unit_favorite_state.dart';
import '../../../l10n/app_localizations.dart';
import 'package:real/core/widget/robust_network_image.dart';

class WebHomeScreen extends StatefulWidget {
  static String routeName = '/web-home';

  const WebHomeScreen({Key? key}) : super(key: key);

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late SearchBloc _searchBloc;
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
    context.read<CompanyBloc>().add(FetchCompaniesEvent());
    context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: 100));
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

    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _searchBloc.add(SearchQueryEvent(
        query: query.trim(),
        type: _currentFilter.isEmpty ? null : 'unit',
        filter: _currentFilter.isEmpty ? null : _currentFilter,
      ));
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
          _performSearch(_searchController.text);
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = SearchFilter.empty();
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
    });
    _searchBloc.add(ClearSearchEvent());
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    if (state is UserSuccess) {
                      return CustomText20("${l10n.welcome} ${state.user.name}");
                    }
                    return CustomText20(l10n.welcome);
                  },
                ),
                SizedBox(height: 24),

                // Companies section
                CustomText20(l10n.companiesName),
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WebCompanyDetailScreen(company: company),
                                  ),
                                ).then((_) {
                                  context.read<CompoundBloc>().add(FetchCompoundsEvent(page: 1, limit: 100));
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
                      final activeSales = state.response.sales
                          .where((sale) => sale.isCurrentlyActive)
                          .toList();

                      if (activeSales.isNotEmpty) {
                        return SaleSlider(sales: activeSales);
                      }
                    }

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

                // Available Compounds section
                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    final compounds = (state is CompoundSuccess) ? state.response.data : [];
                    final hasMultipleCompounds = compounds.length > 6;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText20(l10n.availableCompounds),
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
                                  _showAllAvailableCompounds ? l10n.showLess : l10n.showAll,
                                  style: TextStyle(
                                    color: AppColors.mainColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                      ],
                    );
                  },
                ),

                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundLoading) {
                      return SizedBox(
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
                            child: CustomText16(l10n.noCompounds, color: AppColors.grey),
                          ),
                        );
                      }

                      final compounds = [...state.response.data];
                      final displayCount = _showAllAvailableCompounds
                          ? compounds.length
                          : (compounds.length > 6 ? 6 : compounds.length);

                      // Horizontal scroll view
                      return SizedBox(
                        height: 320,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayCount,
                          itemBuilder: (context, index) {
                            final compound = compounds[index];
                            return Container(
                              width: 280,
                              margin: EdgeInsets.only(right: 16),
                              child: WebCompoundCard(compound: compound),
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
                      );
                    }
                    return SizedBox(height: 200);
                  },
                ),

                SizedBox(height: 24),

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

                      final hasMultipleRecommended = recommendedCompounds.length > 6;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText20(l10n.recommendedCompounds),
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
                                    _showAllRecommendedCompounds ? l10n.showLess : l10n.showAll,
                                    style: TextStyle(
                                      color: AppColors.mainColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText20(l10n.recommendedCompounds),
                        SizedBox(height: 8),
                      ],
                    );
                  },
                ),

                BlocBuilder<CompoundBloc, CompoundState>(
                  builder: (context, state) {
                    if (state is CompoundLoading) {
                      return SizedBox(
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
                            child: CustomText16(l10n.noCompoundsAvailable, color: AppColors.grey),
                          ),
                        );
                      }

                      final compoundsWithImages = state.response.data
                          .where((compound) => compound.images.isNotEmpty)
                          .toList();

                      final recommendedCompounds = compoundsWithImages.isNotEmpty
                          ? compoundsWithImages
                          : state.response.data;

                      final displayCount = _showAllRecommendedCompounds
                          ? recommendedCompounds.length
                          : (recommendedCompounds.length > 9 ? 9 : recommendedCompounds.length);

                      // Horizontal scroll view
                      return SizedBox(
                        height: 320,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayCount,
                          itemBuilder: (context, index) {
                            final compound = recommendedCompounds[index];
                            return Container(
                              width: 280,
                              margin: EdgeInsets.only(right: 16),
                              child: WebCompoundCard(compound: compound),
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
                      );
                    }
                    return SizedBox(height: 200);
                  },
                ),
              ],
            ),
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
              SizedBox(height: 16),
              CustomText16(
                '${l10n.compounds} (${compounds.length})',
                bold: true,
                color: Colors.green,
              ),
              SizedBox(height: 8),
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
              SizedBox(height: 16),
              CustomText16(
                '${l10n.units} (${units.length})',
                bold: true,
                color: Colors.orange,
              ),
              SizedBox(height: 8),
              ...(_showAllUnits ? units : units.take(3))
                  .map((result) => _buildUnitResultItem(result, l10n)),
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
                        ? l10n.showLess
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

  Widget _buildCompanyResultItem(SearchResult result, AppLocalizations l10n) {
    final data = result.data as CompanySearchData;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: data.logo != null && data.logo!.isNotEmpty
            ? ClipOval(
          child: RobustNetworkImage(
            imageUrl: data.logo!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, url) =>
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebCompanyDetailScreen(company: company),
          ),
        );
      },
    );
  }

  Widget _buildCompoundResultItem(SearchResult result, AppLocalizations l10n) {
    final data = result.data as CompoundSearchData;
    return InkWell(
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompoundScreen(compound: compound),
          ),
        );
      },
      child: Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.green.shade100,
              child: data.images.isNotEmpty
                  ? ClipOval(
                      child: RobustNetworkImage(
                        imageUrl: data.images.first,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (context, url) =>
                            Icon(Icons.apartment, size: 14),
                      ),
                    )
                  : Icon(Icons.apartment, size: 14),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data.location,
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitResultItem(SearchResult result, AppLocalizations l10n) {
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
      margin: EdgeInsets.only(bottom: 12),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UnitDetailScreen(unit: unit),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with favorite button
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: data.images.isNotEmpty
                        ? RobustNetworkImage(
                      imageUrl: data.images.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.home, size: 30, color: AppColors.greyText),
                      ),
                    )
                        : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.home, size: 30, color: AppColors.greyText),
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
                            padding: EdgeInsets.all(4),
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
              SizedBox(width: 12),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: getStatusColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data.status.toUpperCase(),
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
                    // Compound name
                    Text(
                      data.compound.name,
                      style: TextStyle(fontSize: 12, color: AppColors.greyText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    // Details Row 1
                    Row(
                      children: [
                        if (data.usageType != null) ...[
                          Icon(Icons.category, size: 14, color: AppColors.mainColor),
                          SizedBox(width: 4),
                          Text(
                            data.usageType!,
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                          SizedBox(width: 12),
                        ],
                        if (data.numberOfBeds != null) ...[
                          Icon(Icons.bed, size: 14, color: AppColors.mainColor),
                          SizedBox(width: 4),
                          Text(
                            '${data.numberOfBeds} ${l10n.beds}',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 6),
                    // Details Row 2
                    Row(
                      children: [
                        if (data.code.isNotEmpty) ...[
                          Icon(Icons.tag, size: 14, color: AppColors.mainColor),
                          SizedBox(width: 4),
                          Text(
                            'Unit #${data.code}',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 8),
                    // Price
                    Text(
                      '${l10n.egp} ${data.price ?? data.totalPrice}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: AppColors.greyText),
            ],
          ),
        ),
      ),
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
