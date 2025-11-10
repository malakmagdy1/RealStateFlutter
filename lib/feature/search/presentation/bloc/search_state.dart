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
  final bool hasMorePages;
  final int currentPage;
  final int totalPages;

  SearchSuccess({
    required this.response,
    this.hasMorePages = false,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  @override
  List<Object?> get props => [response, hasMorePages, currentPage, totalPages];
}

class SearchLoadingMore extends SearchState {
  final SearchResponse currentResponse;

  SearchLoadingMore({required this.currentResponse});

  @override
  List<Object?> get props => [currentResponse];
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
