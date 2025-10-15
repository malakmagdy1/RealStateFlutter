import 'package:equatable/equatable.dart';
import '../../data/models/search_result_model.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchSuccess extends SearchState {
  final SearchResponse response;

  const SearchSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

class SearchError extends SearchState {
  final String message;

  const SearchError({required this.message});

  @override
  List<Object?> get props => [message];
}

class SearchEmpty extends SearchState {
  const SearchEmpty();
}
