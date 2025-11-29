import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/company/data/models/company_model.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/models/search_result_model.dart';
import '../../data/models/search_filter_model.dart';
import '../../data/models/filter_units_response.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository repository;
  List<SearchResult> _allResults = [];

  SearchBloc({required this.repository}) : super(SearchInitial()) {
    on<SearchQueryEvent>(_onSearchQuery);
    on<LoadMoreSearchResultsEvent>(_onLoadMoreResults);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onSearchQuery(
    SearchQueryEvent event,
    Emitter<SearchState> emit,
  ) async {
    // Require at least a query or filter
    final hasQuery = event.query.trim().isNotEmpty;
    final hasFilter = event.filter != null && !event.filter!.isEmpty;

    if (!hasQuery && !hasFilter) {
      print('[SEARCH BLOC] ✗ No query or filter provided - emitting SearchEmpty');
      emit(SearchEmpty());
      return;
    }

    print('[SEARCH BLOC] ✓ Has Query: $hasQuery, Has Filter: $hasFilter');

    // Reset results for new search
    _allResults = [];
    emit(SearchLoading());

    try {
      // Always use the unified search-and-filter API
      print('[SEARCH BLOC] Using unified search-and-filter API (Page: ${event.page})');
      print('[SEARCH BLOC] Search Query: "${event.query}"');
      if (event.filter != null) {
        print('[SEARCH BLOC] Filter params: ${event.filter!.toQueryParameters()}');
      }

      // Use unified searchAndFilter API
      final filterResponse = await repository.searchAndFilter(
        query: event.query.trim().isEmpty ? null : event.query.trim(),
        filter: event.filter,
        page: event.page,
        limit: 30, // Load 30 results per page for better performance
      );

      // Convert companies, compounds, and units to SearchResult
      // Order: companies first, then compounds, then units
      final List<SearchResult> searchResults = [];

      // Add companies
      searchResults.addAll(filterResponse.companies.map((company) {
        return SearchResult(
          type: 'company',
          id: company.id,
          name: company.name,
          data: _convertCompanyToSearchData(company),
        );
      }));

      // Add compounds
      searchResults.addAll(filterResponse.compounds.map((compound) {
        return SearchResult(
          type: 'compound',
          id: compound.id,
          name: compound.project,
          data: _convertCompoundToSearchData(compound),
        );
      }));

      // Add units
      searchResults.addAll(filterResponse.units.map((unit) {
        return SearchResult(
          type: 'unit',
          id: unit.id,
          name: unit.unitName,
          data: _convertFilteredUnitToSearchData(unit),
        );
      }));

      _allResults = searchResults;

      // Create a SearchResponse with the filtered units
      final response = SearchResponse(
        status: filterResponse.success,
        searchQuery: event.query,
        totalResults: filterResponse.totalUnits,
        results: searchResults,
      );

      if (searchResults.isEmpty) {
        emit(SearchEmpty());
      } else {
        final hasMore = filterResponse.page < filterResponse.totalPages;
        print('[SEARCH BLOC] Found ${searchResults.length} units (Page ${filterResponse.page}/${filterResponse.totalPages})');
        emit(SearchSuccess(
          response: response,
          hasMorePages: hasMore,
          currentPage: filterResponse.page,
          totalPages: filterResponse.totalPages,
        ));
      }
    } catch (e) {
      print('[SEARCH BLOC] Error: ${e.toString()}');
      emit(SearchError(message: e.toString()));
    }
  }

  Future<void> _onLoadMoreResults(
    LoadMoreSearchResultsEvent event,
    Emitter<SearchState> emit,
  ) async {
    // Check if we're already in a loading state
    if (state is! SearchSuccess) return;

    final currentState = state as SearchSuccess;
    if (!currentState.hasMorePages) return;

    emit(SearchLoadingMore(currentResponse: currentState.response));

    try {
      print('[SEARCH BLOC] Loading more results (Page: ${event.page})');
      print('[SEARCH BLOC] Search Query: "${event.query}"');

      // Use unified searchAndFilter API
      final filterResponse = await repository.searchAndFilter(
        query: event.query.trim().isEmpty ? null : event.query.trim(),
        filter: event.filter,
        page: event.page,
        limit: 30, // Load 30 results per page for better performance
      );

      // Convert new companies, compounds, and units to SearchResult
      // Order: companies first, then compounds, then units
      final List<SearchResult> newSearchResults = [];

      // Add companies
      newSearchResults.addAll(filterResponse.companies.map((company) {
        return SearchResult(
          type: 'company',
          id: company.id,
          name: company.name,
          data: _convertCompanyToSearchData(company),
        );
      }));

      // Add compounds
      newSearchResults.addAll(filterResponse.compounds.map((compound) {
        return SearchResult(
          type: 'compound',
          id: compound.id,
          name: compound.project,
          data: _convertCompoundToSearchData(compound),
        );
      }));

      // Add units
      newSearchResults.addAll(filterResponse.units.map((unit) {
        return SearchResult(
          type: 'unit',
          id: unit.id,
          name: unit.unitName,
          data: _convertFilteredUnitToSearchData(unit),
        );
      }));

      // Append new results to existing
      _allResults.addAll(newSearchResults);

      // Create updated response with all results
      final updatedResponse = SearchResponse(
        status: filterResponse.success,
        searchQuery: currentState.response.searchQuery,
        totalResults: filterResponse.totalUnits,
        results: _allResults,
      );

      final hasMore = filterResponse.page < filterResponse.totalPages;
      print('[SEARCH BLOC] Loaded ${newSearchResults.length} more units. Total: ${_allResults.length} (Page ${filterResponse.page}/${filterResponse.totalPages})');

      emit(SearchSuccess(
        response: updatedResponse,
        hasMorePages: hasMore,
        currentPage: filterResponse.page,
        totalPages: filterResponse.totalPages,
      ));
    } catch (e) {
      print('[SEARCH BLOC] Error loading more: ${e.toString()}');
      // Restore previous state on error
      emit(currentState);
    }
  }

  // Convert Company to CompanySearchData
  CompanySearchData _convertCompanyToSearchData(Company company) {
    return CompanySearchData(
      id: company.id,
      name: company.name,
      email: company.email,
      logo: company.logo,
      numberOfCompounds: company.numberOfCompounds,
      numberOfAvailableUnits: company.numberOfAvailableUnits,
      compoundsCount: company.numberOfCompounds,
      createdAt: company.createdAt,
    );
  }

  // Convert Compound to CompoundSearchData
  CompoundSearchData _convertCompoundToSearchData(Compound compound) {
    return CompoundSearchData(
      id: compound.id,
      name: compound.project,
      location: compound.location,
      status: compound.status,
      completionProgress: compound.completionProgress ?? '0',
      unitsCount: compound.totalUnits,
      company: CompanyInfo(
        id: compound.companyId,
        name: compound.companyName,
        logo: compound.companyLogo,
      ),
      images: compound.images,
      createdAt: compound.createdAt,
    );
  }

  // Convert FilteredUnit from filter API to UnitSearchData for consistency
  UnitSearchData _convertFilteredUnitToSearchData(FilteredUnit unit) {
    return UnitSearchData(
      id: unit.id,
      name: unit.unitName,
      code: unit.code,
      unitType: unit.usageType,
      usageType: unit.usageType,
      price: unit.normalPrice,
      totalPrice: unit.totalPricing,
      available: unit.available,
      isSold: unit.isSold,
      status: unit.status,
      numberOfBeds: unit.numberOfBeds.toString(),
      area: unit.totalArea.toString(),
      compound: CompoundInfo(
        id: unit.compoundId,
        name: unit.compoundName,
        location: unit.compoundLocation,
        company: CompanyInfo(
          id: unit.companyId,
          name: unit.companyName,
          logo: unit.companyLogo,
        ),
      ),
      images: unit.images,
      // Pass additional fields for card display
      deliveryDate: unit.deliveredAt,
      finishingType: unit.finishingType,
      totalArea: unit.totalArea,
      unitName: unit.unitName,
      unitCode: unit.unitCode,
    );
  }


  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchInitial());
  }
}
