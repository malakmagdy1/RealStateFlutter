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
    // Require at least a query or filter
    if (event.query.trim().isEmpty && event.filter == null) {
      emit(const SearchEmpty());
      return;
    }

    emit(const SearchLoading());

    try {
      // Use the search API (returns companies, compounds, and units)
      print('[SEARCH] Using search API with query: "${event.query}"');
      final response = await repository.search(
        query: event.query,
        type: event.type,
        perPage: 100,
        filter: event.filter,
      );

      if (response.results.isEmpty) {
        emit(const SearchEmpty());
      } else {
        print('[SEARCH] Found ${response.totalResults} results');
        emit(SearchSuccess(response: response));
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
