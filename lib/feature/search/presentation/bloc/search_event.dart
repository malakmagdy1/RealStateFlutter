import 'package:equatable/equatable.dart';
import '../../data/models/search_filter_model.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryEvent extends SearchEvent {
  final String query;
  final String? type; // company, compound, unit, or null for all
  final int perPage;
  final SearchFilter? filter;

  const SearchQueryEvent({
    required this.query,
    this.type,
    this.perPage = 20,
    this.filter,
  });

  @override
  List<Object?> get props => [query, type, perPage, filter];
}

class ClearSearchEvent extends SearchEvent {
  const ClearSearchEvent();
}
