import 'package:equatable/equatable.dart';

import '../../data/models/saved_search_model.dart';

abstract class SavedSearchState extends Equatable {
  const SavedSearchState();

  @override
  List<Object?> get props => [];
}

class SavedSearchInitial extends SavedSearchState {
  const SavedSearchInitial();
}

class SavedSearchLoading extends SavedSearchState {
  const SavedSearchLoading();
}

class SavedSearchesLoaded extends SavedSearchState {
  final List<SavedSearch> savedSearches;

  const SavedSearchesLoaded({required this.savedSearches});

  @override
  List<Object?> get props => [savedSearches];
}

class SavedSearchLoaded extends SavedSearchState {
  final SavedSearch savedSearch;

  const SavedSearchLoaded({required this.savedSearch});

  @override
  List<Object?> get props => [savedSearch];
}

class SavedSearchCreated extends SavedSearchState {
  final SavedSearch savedSearch;
  final String message;

  const SavedSearchCreated({
    required this.savedSearch,
    this.message = 'Search saved successfully',
  });

  @override
  List<Object?> get props => [savedSearch, message];
}

class SavedSearchUpdated extends SavedSearchState {
  final SavedSearch savedSearch;
  final String message;

  const SavedSearchUpdated({
    required this.savedSearch,
    this.message = 'Search updated successfully',
  });

  @override
  List<Object?> get props => [savedSearch, message];
}

class SavedSearchDeleted extends SavedSearchState {
  final String message;

  const SavedSearchDeleted({this.message = 'Search deleted successfully'});

  @override
  List<Object?> get props => [message];
}

class SavedSearchError extends SavedSearchState {
  final String message;

  const SavedSearchError({required this.message});

  @override
  List<Object?> get props => [message];
}
