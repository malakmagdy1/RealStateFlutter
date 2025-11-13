import 'package:flutter_bloc/flutter_bloc.dart';
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
    if (event.query.trim().isEmpty && event.filter == null) {
      emit(SearchEmpty());
      return;
    }

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
        limit: 1000, // Get all results
      );

      // Convert FilteredUnit to SearchResult
      final searchResults = filterResponse.units.map((unit) {
        return SearchResult(
          type: 'unit',
          id: unit.id,
          name: unit.unitName,
          data: _convertFilteredUnitToSearchData(unit),
        );
      }).toList();

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
        limit: 1000,
      );

      // Convert new units to SearchResult
      final newSearchResults = filterResponse.units.map((unit) {
        return SearchResult(
          type: 'unit',
          id: unit.id,
          name: unit.unitName,
          data: _convertFilteredUnitToSearchData(unit),
        );
      }).toList();

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
    );
  }


  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchInitial());
  }
}
