import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/models/search_result_model.dart';
import '../../data/models/search_filter_model.dart';
import '../../data/models/filter_units_response.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository repository;

  SearchBloc({required this.repository}) : super(const SearchInitial()) {
    on<SearchQueryEvent>(_onSearchQuery);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onSearchQuery(
    SearchQueryEvent event,
    Emitter<SearchState> emit,
  ) async {
    // Allow empty query if filters are present
    if (event.query.trim().isEmpty && event.filter == null) {
      emit(const SearchEmpty());
      return;
    }

    emit(const SearchLoading());

    try {
      // If filters are present, use the dedicated filter API
      if (event.filter != null) {
        print('[SEARCH] Using filter API');
        final filterResponse = await repository.filterUnits(event.filter!);

        if (filterResponse.units.isEmpty) {
          emit(const SearchEmpty());
        } else {
          // Convert FilteredUnit to SearchResult
          final searchResults = filterResponse.units.map((unit) {
            return SearchResult(
              type: 'unit',
              id: unit.id,
              name: unit.unitName,
              data: _convertFilteredUnitToSearchData(unit),
            );
          }).toList();

          final searchResponse = SearchResponse(
            status: filterResponse.success,
            searchQuery: event.query,
            totalResults: filterResponse.totalUnits,
            results: searchResults,
          );

          print('[SEARCH] Filter API returned ${filterResponse.totalUnits} units');
          emit(SearchSuccess(response: searchResponse));
        }
      } else {
        // Normal search without filters
        final response = await repository.search(
          query: event.query,
          type: event.type,
          perPage: 100,
          filter: null,
        );

        if (response.results.isEmpty) {
          emit(const SearchEmpty());
        } else {
          emit(SearchSuccess(response: response));
        }
      }
    } catch (e) {
      print('[SEARCH] Error: ${e.toString()}');
      emit(SearchError(message: e.toString()));
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
    emit(const SearchInitial());
  }
}
