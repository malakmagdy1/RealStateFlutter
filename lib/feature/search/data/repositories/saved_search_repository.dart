import '../models/saved_search_model.dart';
import '../web_services/saved_search_web_services.dart';

class SavedSearchRepository {
  final SavedSearchWebServices _webServices;

  SavedSearchRepository({SavedSearchWebServices? webServices})
      : _webServices = webServices ?? SavedSearchWebServices();

  /// Get all saved searches for the current user
  Future<SavedSearchResponse> getAllSavedSearches({required String token}) async {
    try {
      final response = await _webServices.getAllSavedSearches(token: token);
      return response;
    } catch (e) {
      print('Repository Get All Saved Searches Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Get a specific saved search by ID
  Future<SavedSearchResponse> getSavedSearchById({
    required String id,
    required String token,
  }) async {
    try {
      final response = await _webServices.getSavedSearchById(id: id, token: token);
      return response;
    } catch (e) {
      print('Repository Get Saved Search By ID Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Create a new saved search
  Future<SavedSearchResponse> createSavedSearch({
    required CreateSavedSearchRequest request,
    required String token,
  }) async {
    try {
      final response = await _webServices.createSavedSearch(request: request, token: token);
      return response;
    } catch (e) {
      print('Repository Create Saved Search Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Update an existing saved search
  Future<SavedSearchResponse> updateSavedSearch({
    required String id,
    required UpdateSavedSearchRequest request,
    required String token,
  }) async {
    try {
      final response = await _webServices.updateSavedSearch(
        id: id,
        request: request,
        token: token,
      );
      return response;
    } catch (e) {
      print('Repository Update Saved Search Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Delete a saved search
  Future<SavedSearchResponse> deleteSavedSearch({
    required String id,
    required String token,
  }) async {
    try {
      final response = await _webServices.deleteSavedSearch(id: id, token: token);
      return response;
    } catch (e) {
      print('Repository Delete Saved Search Error: ${e.toString()}');
      rethrow;
    }
  }
}
