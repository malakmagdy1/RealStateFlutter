import 'package:flutter_bloc/flutter_bloc.dart';
import 'saved_search_event.dart';
import 'saved_search_state.dart';
import '../../data/repositories/saved_search_repository.dart';

class SavedSearchBloc extends Bloc<SavedSearchEvent, SavedSearchState> {
  final SavedSearchRepository _repository;

  SavedSearchBloc({required SavedSearchRepository repository})
      : _repository = repository,
        super(const SavedSearchInitial()) {
    on<FetchSavedSearchesEvent>(_onFetchSavedSearches);
    on<FetchSavedSearchByIdEvent>(_onFetchSavedSearchById);
    on<CreateSavedSearchEvent>(_onCreateSavedSearch);
    on<UpdateSavedSearchEvent>(_onUpdateSavedSearch);
    on<DeleteSavedSearchEvent>(_onDeleteSavedSearch);
  }

  Future<void> _onFetchSavedSearches(
    FetchSavedSearchesEvent event,
    Emitter<SavedSearchState> emit,
  ) async {
    emit(const SavedSearchLoading());
    try {
      final response = await _repository.getAllSavedSearches(token: event.token);

      if (response.success && response.savedSearches != null) {
        emit(SavedSearchesLoaded(savedSearches: response.savedSearches!));
      } else {
        emit(SavedSearchError(message: response.message ?? 'Failed to load saved searches'));
      }
    } catch (e) {
      emit(SavedSearchError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchSavedSearchById(
    FetchSavedSearchByIdEvent event,
    Emitter<SavedSearchState> emit,
  ) async {
    emit(const SavedSearchLoading());
    try {
      final response = await _repository.getSavedSearchById(
        id: event.id,
        token: event.token,
      );

      if (response.success && response.savedSearch != null) {
        emit(SavedSearchLoaded(savedSearch: response.savedSearch!));
      } else {
        emit(SavedSearchError(message: response.message ?? 'Failed to load saved search'));
      }
    } catch (e) {
      emit(SavedSearchError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateSavedSearch(
    CreateSavedSearchEvent event,
    Emitter<SavedSearchState> emit,
  ) async {
    emit(const SavedSearchLoading());
    try {
      final response = await _repository.createSavedSearch(
        request: event.request,
        token: event.token,
      );

      if (response.success && response.savedSearch != null) {
        emit(SavedSearchCreated(
          savedSearch: response.savedSearch!,
          message: response.message ?? 'Search saved successfully',
        ));
        // Reload all saved searches after creating
        add(FetchSavedSearchesEvent(token: event.token));
      } else {
        emit(SavedSearchError(message: response.message ?? 'Failed to create saved search'));
      }
    } catch (e) {
      emit(SavedSearchError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateSavedSearch(
    UpdateSavedSearchEvent event,
    Emitter<SavedSearchState> emit,
  ) async {
    emit(const SavedSearchLoading());
    try {
      final response = await _repository.updateSavedSearch(
        id: event.id,
        request: event.request,
        token: event.token,
      );

      if (response.success && response.savedSearch != null) {
        emit(SavedSearchUpdated(
          savedSearch: response.savedSearch!,
          message: response.message ?? 'Search updated successfully',
        ));
        // Reload all saved searches after updating
        add(FetchSavedSearchesEvent(token: event.token));
      } else {
        emit(SavedSearchError(message: response.message ?? 'Failed to update saved search'));
      }
    } catch (e) {
      emit(SavedSearchError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteSavedSearch(
    DeleteSavedSearchEvent event,
    Emitter<SavedSearchState> emit,
  ) async {
    emit(const SavedSearchLoading());
    try {
      final response = await _repository.deleteSavedSearch(
        id: event.id,
        token: event.token,
      );

      if (response.success) {
        emit(SavedSearchDeleted(
          message: response.message ?? 'Search deleted successfully',
        ));
        // Reload all saved searches after deleting
        add(FetchSavedSearchesEvent(token: event.token));
      } else {
        emit(SavedSearchError(message: response.message ?? 'Failed to delete saved search'));
      }
    } catch (e) {
      emit(SavedSearchError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
