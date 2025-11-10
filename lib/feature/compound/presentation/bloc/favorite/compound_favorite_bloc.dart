import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/compound/data/web_services/favorites_web_services.dart';
import 'package:real/core/utils/constant.dart';
import 'compound_favorite_event.dart';
import 'compound_favorite_state.dart';

class CompoundFavoriteBloc extends Bloc<CompoundFavoriteEvent, CompoundFavoriteState> {
  final List<Compound> _favorites = [];
  final FavoritesWebServices _favoritesApi = FavoritesWebServices();
  static String _baseFavoritesKey = 'favorite_compounds';

  // Get user-specific key based on token
  String get _favoritesKey {
    if (token != null && token!.isNotEmpty) {
      // Use first 20 chars of token as identifier to keep key reasonable length
      final tokenHash = token!.length > 20 ? token!.substring(0, 20) : token!;
      return '${_baseFavoritesKey}_$tokenHash';
    }
    return _baseFavoritesKey; // Fallback for no token
  }

  CompoundFavoriteBloc() : super(CompoundFavoriteInitial()) {
    on<LoadFavoriteCompounds>(_onLoadFavorites);
    on<AddFavoriteCompound>(_onAddFavorite);
    on<RemoveFavoriteCompound>(_onRemoveFavorite);

    // Load favorites when bloc is created
    add(LoadFavoriteCompounds());
  }

  Future<void> _onLoadFavorites(
    LoadFavoriteCompounds event,
    Emitter<CompoundFavoriteState> emit,
  ) async {
    try {
      // Load from cache FIRST for instant UI (non-blocking)
      print('[CompoundFavoriteBloc] Loading favorites from cache...');
      final favoritesJson = await CasheNetwork.getCasheDataAsync(key: _favoritesKey);

      if (favoritesJson.isNotEmpty) {
        print('[CompoundFavoriteBloc] Found cached data');
        final List<dynamic> decoded = json.decode(favoritesJson);
        _favorites.clear();
        _favorites.addAll(decoded.map((json) => Compound.fromJson(json)).toList());
        print('[CompoundFavoriteBloc] Loaded ${_favorites.length} favorites from cache');

        // Emit state immediately with cached data
        emit(CompoundFavoriteUpdated(List.from(_favorites)));
      } else {
        print('[CompoundFavoriteBloc] No cached favorites found');
        emit(CompoundFavoriteUpdated([]));
      }

      // Then load from API in the background (non-blocking)
      print('[CompoundFavoriteBloc] Syncing favorites from API in background...');
      _syncFromAPI(emit);
    } catch (e) {
      print('[CompoundFavoriteBloc] Error loading favorites: $e');
      emit(CompoundFavoriteError('Failed to load favorites: $e'));
    }
  }

  // Sync from API in the background without blocking the UI
  Future<void> _syncFromAPI(Emitter<CompoundFavoriteState> emit) async {
    try {
      // Only sync if user is authenticated
      if (token == null || token!.isEmpty) {
        print('[CompoundFavoriteBloc] No token - skipping API sync, using cache only');
        return;
      }

      final response = await _favoritesApi.getFavorites();
      print('[CompoundFavoriteBloc] API sync response received');
      print('[CompoundFavoriteBloc] Full API response: $response');
      print('[CompoundFavoriteBloc] Response keys: ${response.keys.toList()}');

      List<Compound> apiCompounds = [];

      // Handle different response structures
      if (response['success'] == true || response['status'] == true) {
        List<dynamic>? favoritesData;

        // Try different response structures
        if (response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          favoritesData = data['favorites'] as List<dynamic>?;
        } else if (response['favorites'] != null) {
          favoritesData = response['favorites'] as List<dynamic>?;
        }

        if (favoritesData != null) {
          print('[CompoundFavoriteBloc] Total favorites from API: ${favoritesData.length}');

          // Extract compounds from the favorites response
          for (var fav in favoritesData) {
            if (fav is Map<String, dynamic>) {
              // Check if this is a compound favorite (compound_id is not null)
              if (fav['compound_id'] != null && fav['compound'] != null) {
                print('[CompoundFavoriteBloc] Found compound favorite: ${fav['compound_id']}');
                // Structure: {id, user_id, compound_id, notes, compound: {...}}
                final compoundData = Map<String, dynamic>.from(fav['compound'] as Map<String, dynamic>);
                // Add favorite-specific fields
                compoundData['favorite_id'] = fav['id'];
                compoundData['notes'] = fav['notes'];
                compoundData['note_id'] = fav['note_id']; // Add note_id from favorites
                apiCompounds.add(Compound.fromJson(compoundData));
              } else if (fav['unit_id'] != null) {
                print('[CompoundFavoriteBloc] Skipping unit favorite: ${fav['unit_id']}');
              }
            }
          }
        }

        print('[CompoundFavoriteBloc] Parsed ${apiCompounds.length} favorites from API');

        // Only update if API returned data OR if cache was empty
        // This prevents wiping local favorites if API returns empty
        if (apiCompounds.isNotEmpty || _favorites.isEmpty) {
          _favorites.clear();
          _favorites.addAll(apiCompounds);

          print('[CompoundFavoriteBloc] Synced ${_favorites.length} favorites from API');

          // Cache the favorites locally for offline access
          await _saveFavorites();

          // Emit updated state with new data from API
          emit(CompoundFavoriteUpdated(List.from(_favorites)));
        } else {
          print('[CompoundFavoriteBloc] API returned 0 items but cache has ${_favorites.length} - keeping cache');
        }
      } else {
        print('[CompoundFavoriteBloc] API returned no data or error - keeping cached data');
      }
    } catch (apiError) {
      print('[CompoundFavoriteBloc] API sync error: $apiError - using cached data');
    }
  }

  Future<void> _onAddFavorite(
    AddFavoriteCompound event,
    Emitter<CompoundFavoriteState> emit,
  ) async {
    try {
      print('[CompoundFavoriteBloc] Adding favorite compound: ${event.compound.id}');

      // Check if already exists
      if (_favorites.any((c) => c.id == event.compound.id)) {
        print('[CompoundFavoriteBloc] ⚠️ Compound already in favorites');
        return;
      }

      // Add to API
      try {
        final compoundId = int.parse(event.compound.id!);
        print('[CompoundFavoriteBloc] 📡 Calling API with compound_id: $compoundId');
        final response = await _favoritesApi.addCompoundToFavorites(compoundId);
        print('[CompoundFavoriteBloc] 📥 API add response: $response');

        if (response['success'] == true) {
          // Add to local list
          _favorites.add(event.compound);
          print('[CompoundFavoriteBloc] ✅ Compound added to API and local. Total favorites: ${_favorites.length}');

          // Save to cache
          await _saveFavorites();

          emit(CompoundFavoriteUpdated(List.from(_favorites)));
          print('[CompoundFavoriteBloc] State emitted with ${_favorites.length} favorites');
        } else {
          throw Exception(response['message'] ?? 'Failed to add favorite');
        }
      } catch (apiError) {
        print('[CompoundFavoriteBloc] API error: $apiError');
        // If API fails, still add locally
        _favorites.add(event.compound);
        await _saveFavorites();
        emit(CompoundFavoriteUpdated(List.from(_favorites)));
        throw apiError;
      }
    } catch (e) {
      print('[CompoundFavoriteBloc] Error adding favorite: $e');
      emit(CompoundFavoriteError('Failed to add favorite: $e'));
    }
  }

  Future<void> _onRemoveFavorite(
    RemoveFavoriteCompound event,
    Emitter<CompoundFavoriteState> emit,
  ) async {
    try {
      print('[CompoundFavoriteBloc] Removing favorite compound: ${event.compound.id}');

      // Remove from API
      try {
        final compoundId = int.parse(event.compound.id!);
        final response = await _favoritesApi.removeCompoundFromFavorites(compoundId);
        print('[CompoundFavoriteBloc] API remove response: $response');

        if (response['success'] == true) {
          // Remove from local list
          _favorites.removeWhere((c) => c.id == event.compound.id);
          print('[CompoundFavoriteBloc] ✅ Compound removed from API and local. Total favorites: ${_favorites.length}');

          // Save to cache
          await _saveFavorites();

          emit(CompoundFavoriteUpdated(List.from(_favorites)));
        } else {
          throw Exception(response['message'] ?? 'Failed to remove favorite');
        }
      } catch (apiError) {
        print('[CompoundFavoriteBloc] API error: $apiError');
        // If API fails, still remove locally
        _favorites.removeWhere((c) => c.id == event.compound.id);
        await _saveFavorites();
        emit(CompoundFavoriteUpdated(List.from(_favorites)));
        throw apiError;
      }
    } catch (e) {
      print('[CompoundFavoriteBloc] Error removing favorite: $e');
      emit(CompoundFavoriteError('Failed to remove favorite: $e'));
    }
  }

  Future<void> _saveFavorites() async {
    try {
      print('[CompoundFavoriteBloc] Saving ${_favorites.length} favorites...');
      final favoritesJson = json.encode(
        _favorites.map((c) => c.toJson()).toList(),
      );
      print('[CompoundFavoriteBloc] JSON size: ${favoritesJson.length} characters');
      await CasheNetwork.insertToCashe(key: _favoritesKey, value: favoritesJson);
      print('[CompoundFavoriteBloc] Save completed successfully');
    } catch (e){
      print('[CompoundFavoriteBloc] Error saving favorites: $e');
    }
  }

  // Helper methods to check favorite status and toggle
  bool isFavorite(Compound compound) {
    return _favorites.any((c) => c.id == compound.id);
  }

  void toggleFavorite(Compound compound) {
    if (isFavorite(compound)) {
      add(RemoveFavoriteCompound(compound));
    } else {
      add(AddFavoriteCompound(compound));
    }
  }

  List<Compound> get favorites => List.from(_favorites);
}
