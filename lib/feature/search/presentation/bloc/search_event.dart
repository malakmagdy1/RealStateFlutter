import 'package:equatable/equatable.dart';
import '../../data/models/search_filter_model.dart';

abstract class SearchEvent extends Equatable {
  SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryEvent extends SearchEvent {
  final String query;
  final String? type; // company, compound, unit, or null for all
  final int perPage;
  final SearchFilter? filter;
  final int page;

  SearchQueryEvent({
    required this.query,
    this.type,
    this.perPage = 20,
    this.filter,
    this.page = 1,
  });

  @override
  List<Object?> get props => [query, type, perPage, filter, page];
}

class LoadMoreSearchResultsEvent extends SearchEvent {
  final String query;
  final String? type;
  final SearchFilter? filter;
  final int page;

  LoadMoreSearchResultsEvent({
    required this.query,
    this.type,
    this.filter,
    required this.page,
  });

  @override
  List<Object?> get props => [query, type, filter, page];
}

class ClearSearchEvent extends SearchEvent {
  ClearSearchEvent();
}
