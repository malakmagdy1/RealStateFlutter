import 'package:equatable/equatable.dart';
import '../../data/models/saved_search_model.dart';

abstract class SavedSearchEvent extends Equatable {
  const SavedSearchEvent();

  @override
  List<Object?> get props => [];
}

class FetchSavedSearchesEvent extends SavedSearchEvent {
  final String token;

  const FetchSavedSearchesEvent({required this.token});

  @override
  List<Object?> get props => [token];
}

class FetchSavedSearchByIdEvent extends SavedSearchEvent {
  final String id;
  final String token;

  const FetchSavedSearchByIdEvent({required this.id, required this.token});

  @override
  List<Object?> get props => [id, token];
}

class CreateSavedSearchEvent extends SavedSearchEvent {
  final CreateSavedSearchRequest request;
  final String token;

  const CreateSavedSearchEvent({required this.request, required this.token});

  @override
  List<Object?> get props => [request, token];
}

class UpdateSavedSearchEvent extends SavedSearchEvent {
  final String id;
  final UpdateSavedSearchRequest request;
  final String token;

  const UpdateSavedSearchEvent({
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

  const DeleteSavedSearchEvent({required this.id, required this.token});

  @override
  List<Object?> get props => [id, token];
}
