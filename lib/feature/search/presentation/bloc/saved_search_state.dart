import 'package:equatable/equatable.dart';

import '../../data/models/saved_search_model.dart';

abstract class SavedSearchState extends Equatable {
  SavedSearchState();

  @override
  List<Object?> get props => [];
}

class SavedSearchInitial extends SavedSearchState {
  SavedSearchInitial();
}

class SavedSearchLoading extends SavedSearchState {
  SavedSearchLoading();
}

class SavedSearchesLoaded extends SavedSearchState {
  final List<SavedSearch> savedSearches;

  SavedSearchesLoaded({required this.savedSearches});

  @override
  List<Object?> get props => [savedSearches];
}

class SavedSearchLoaded extends SavedSearchState {
  final SavedSearch savedSearch;

  SavedSearchLoaded({required this.savedSearch});

  @override
  List<Object?> get props => [savedSearch];
}

class SavedSearchCreated extends SavedSearchState {
  final SavedSearch savedSearch;
  final String message;

  SavedSearchCreated({
    required this.savedSearch,
    this.message = 'Search saved successfully',
  });

  @override
  List<Object?> get props => [savedSearch, message];
}

class SavedSearchUpdated extends SavedSearchState {
  final SavedSearch savedSearch;
  final String message;

  SavedSearchUpdated({
    required this.savedSearch,
    this.message = 'Search updated successfully',
  });

  @override
  List<Object?> get props => [savedSearch, message];
}

class SavedSearchDeleted extends SavedSearchState {
  final String message;

  SavedSearchDeleted({this.message = 'Search deleted successfully'});

  @override
  List<Object?> get props => [message];
}

class SavedSearchError extends SavedSearchState {
  final String message;

  SavedSearchError({required this.message});

  @override
  List<Object?> get props => [message];
}
