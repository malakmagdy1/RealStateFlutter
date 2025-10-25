import 'package:equatable/equatable.dart';
import '../../data/models/search_result_model.dart';

abstract class SearchState extends Equatable {
  SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  SearchInitial();
}

class SearchLoading extends SearchState {
  SearchLoading();
}

class SearchSuccess extends SearchState {
  final SearchResponse response;

  SearchSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

class SearchError extends SearchState {
  final String message;

  SearchError({required this.message});

  @override
  List<Object?> get props => [message];
}

class SearchEmpty extends SearchState {
  SearchEmpty();
}
