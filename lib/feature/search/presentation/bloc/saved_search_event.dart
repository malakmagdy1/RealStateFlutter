import 'package:equatable/equatable.dart';
import '../../data/models/saved_search_model.dart';

abstract class SavedSearchEvent extends Equatable {
  SavedSearchEvent();

  @override
  List<Object?> get props => [];
}

class FetchSavedSearchesEvent extends SavedSearchEvent {
  final String token;

  FetchSavedSearchesEvent({required this.token});

  @override
  List<Object?> get props => [token];
}

class FetchSavedSearchByIdEvent extends SavedSearchEvent {
  final String id;
  final String token;

  FetchSavedSearchByIdEvent({required this.id, required this.token});

  @override
  List<Object?> get props => [id, token];
}

class CreateSavedSearchEvent extends SavedSearchEvent {
  final CreateSavedSearchRequest request;
  final String token;

  CreateSavedSearchEvent({required this.request, required this.token});

  @override
  List<Object?> get props => [request, token];
}

class UpdateSavedSearchEvent extends SavedSearchEvent {
  final String id;
  final UpdateSavedSearchRequest request;
  final String token;

  UpdateSavedSearchEvent({
    required this.id,
    required this.request,
    required this.token,
  });

  @override
  List<Object?> get props => [id, request, token];
}

class DeleteSavedSearchEvent extends SavedSearchEvent {
  final String id;
  final String token;

  DeleteSavedSearchEvent({required this.id, required this.token});

  @override
  List<Object?> get props => [id, token];
}
