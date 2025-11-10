import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/data/web_services/favorites_web_services.dart';
import 'package:real/core/utils/constant.dart';

import 'unit_favorite_event.dart';
import 'unit_favorite_state.dart';

class UnitFavoriteBloc extends Bloc<UnitFavoriteEvent, UnitFavoriteState> {
  final List<Unit> _favorites = [];
  final FavoritesWebServices _favoritesApi = FavoritesWebServices();
  static String _baseFavoritesKey = 'favorite_units';

  // Get user-specific key based on token
  String get _favoritesKey {
    if (token != null && token!.isNotEmpty) {
      // Use first 20 chars of token as identifier to keep key reasonable length
      final tokenHash = token!.length > 20 ? token!.substring(0, 20) : token!;
      return '${_baseFavoritesKey}_$tokenHash';
    }
    return _baseFavoritesKey; // Fallback for no token
  }

  UnitFavoriteBloc() : super(UnitFavoriteInitial()) {
    on<LoadFavoriteUnits>(_onLoadFavorites);
    on<AddFavoriteUnit>(_onAddFavorite);
    on<RemoveFavoriteUnit>(_onRemoveFavorite);

    // Load favorites when bloc is created
    add(LoadFavoriteUnits());
  }

  Future<void> _onLoadFavorites(
    LoadFavoriteUnits event,
    Emitter<UnitFavoriteState> emit,
  ) async {
    try {
      // Load from cache FIRST for instant UI (non-blocking)
      print('[UnitFavoriteBloc] Loading favorites from cache...');
      final favoritesJson = await CasheNetwork.getCasheDataAsync(key: _favoritesKey);

      if (favoritesJson.isNotEmpty) {
        print('[UnitFavoriteBloc] Found cached data');
        final List<dynamic> decoded = json.decode(favoritesJson);
        _favorites.clear();
        _favorites.addAll(decoded.map((json) => Unit.fromJson(json)).toList());
        print('[UnitFavoriteBloc] Loaded ${_favorites.length} favorites from cache');

        // Emit state immediately with cached data
        emit(UnitFavoriteUpdated(List.from(_favorites)));
      } else {
        print('[UnitFavoriteBloc] No cached favorites found');
        emit(UnitFavoriteUpdated([]));
      }

      // Then load from API in the background (non-blocking)
      print('[UnitFavoriteBloc] Syncing favorites from API in background...');
      // Note: We don't await this to keep UI responsive with cached data
      _syncFromAPIInBackground();
    } catch (e) {
      print('[UnitFavoriteBloc] Error loading favorites: $e');
      emit(UnitFavoriteError('Failed to load favorites: $e'));
    }
  }

  // Sync from API in the background without emitting
  // Instead, dispatch a new event to update state
  Future<void> _syncFromAPIInBackground() async {
    try {
      // Only sync if user is authenticated
      if (token == null || token!.isEmpty) {
        print('[UnitFavoriteBloc] No token - skipping API sync, using cache only');
        return;
      }

      final response = await _favoritesApi.getFavorites();
      print('[UnitFavoriteBloc] API sync response received');
      print('[UnitFavoriteBloc] Full API response: $response');
      print('[UnitFavoriteBloc] Response keys: ${response.keys.toList()}');

      List<Unit> apiUnits = [];

      // Handle different response structures
      if (response['success'] == true || response['status'] == true) {
        List<dynamic>? favoritesData;

        // Try different response structures
        if (response['data'] != null) {
          // Structure: {"success": true, "data": {"favorites": [...]}}
          final data = response['data'] as Map<String, dynamic>;
          favoritesData = data['favorites'] as List<dynamic>?;
          print('[UnitFavoriteBloc] Found favorites in response[data][favorites]');
        } else if (response['favorites'] != null) {
          // Structure: {"success": true, "favorites": [...]}
          favoritesData = response['favorites'] as List<dynamic>?;
          print('[UnitFavoriteBloc] Found favorites in response[favorites]');
        }

        if (favoritesData != null) {
          print('[UnitFavoriteBloc] Total favorites from API: ${favoritesData.length}');

          // Extract units from the favorites response
          for (var fav in favoritesData) {
            if (fav is Map<String, dynamic>) {
              // Check if this is a unit favorite (unit_id is not null)
              if (fav['unit_id'] != null && fav['unit'] != null) {
                print('[UnitFavoriteBloc] Found unit favorite: ${fav['unit_id']}');
                // Structure: {id, user_id, unit_id, notes, unit: {...}}
                final unitData = Map<String, dynamic>.from(fav['unit'] as Map<String, dynamic>);
                // Add favorite-specific fields
                unitData['favorite_id'] = fav['id'];
                unitData['notes'] = fav['notes'];
                unitData['note_id'] = fav['note_id']; // Add note_id from favorites
                apiUnits.add(Unit.fromJson(unitData));
              } else if (fav['compound_id'] != null) {
                print('[UnitFavoriteBloc] Skipping compound favorite: ${fav['compound_id']}');
              }
            }
          }
        }

        print('[UnitFavoriteBloc] Parsed ${apiUnits.length} favorites from API');

        // Only update if API returned data OR if cache was empty
        // This prevents wiping local favorites if API returns empty
        if (apiUnits.isNotEmpty || _favorites.isEmpty) {
          _favorites.clear();
          _favorites.addAll(apiUnits);

          print('[UnitFavoriteBloc] Synced ${_favorites.length} favorites from API');

          // Cache the favorites locally for offline access
          await _saveFavoritesToCache();

          // Dispatch new event to update state (safe way to emit after async operation)
          add(LoadFavoriteUnits());
        } else {
          print('[UnitFavoriteBloc] API returned 0 items but cache has ${_favorites.length} - keeping cache');
        }
      } else {
        print('[UnitFavoriteBloc] API returned no data or error - keeping cached data');
      }
    } catch (apiError) {
      print('[UnitFavoriteBloc] API sync error: $apiError - using cached data');
    }
  }

  Future<void> _onAddFavorite(
    AddFavoriteUnit event,
    Emitter<UnitFavoriteState> emit,
  ) async {
    try {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('🔵 [UnitFavoriteBloc] ADD FAVORITE REQUEST');
      print('═══════════════════════════════════════════════════════');
      print('Unit ID: ${event.unit.id}');
      print('Unit Type: ${event.unit.unitType}');
      print('Unit Number: ${event.unit.unitNumber ?? "N/A"}');
      print('Token available: ${token != null && token!.isNotEmpty}');
      if (token != null && token!.isNotEmpty) {
        print('Token: ${token!.substring(0, 20)}...');
      }
      print('═══════════════════════════════════════════════════════');

      // Check if already exists
      if (_favorites.any((u) => u.id == event.unit.id)) {
        print('[UnitFavoriteBloc] ⚠️ Unit already in favorites');
        return;
      }

      // Add to API
      try {
        final unitId = int.parse(event.unit.id!);
        print('[UnitFavoriteBloc] 📡 Calling API with unit_id: $unitId');
        final response = await _favoritesApi.addToFavorites(unitId);
        print('[UnitFavoriteBloc] 📥 API add response: $response');

        if (response['success'] == true) {
          // Add to local list
          _favorites.add(event.unit);
          print('[UnitFavoriteBloc] ✅ Unit added to API and local. Total favorites: ${_favorites.length}');

          // Save to cache
          await _saveFavoritesToCache();

          emit(UnitFavoriteUpdated(List.from(_favorites)));
          print('[UnitFavoriteBloc] State emitted with ${_favorites.length} favorites');
        } else {
          throw Exception(response['message'] ?? 'Failed to add favorite');
        }
      } catch (apiError) {
        print('[UnitFavoriteBloc] API error: $apiError');
        // If API fails, still add locally
        _favorites.add(event.unit);
        await _saveFavoritesToCache();
        emit(UnitFavoriteUpdated(List.from(_favorites)));
        throw apiError;
      }
    } catch (e) {
      print('[UnitFavoriteBloc] Error adding favorite: $e');
      emit(UnitFavoriteError('Failed to add favorite: $e'));
    }
  }

  Future<void> _onRemoveFavorite(
    RemoveFavoriteUnit event,
    Emitter<UnitFavoriteState> emit,
  ) async {
    try {
      print('[UnitFavoriteBloc] Removing favorite unit: ${event.unit.id}');

      // Remove from API
      try {
        final unitId = int.parse(event.unit.id!);
        final response = await _favoritesApi.removeFromFavorites(unitId);
        print('[UnitFavoriteBloc] API remove response: $response');

        if (response['success'] == true) {
          // Remove from local list
          _favorites.removeWhere((u) => u.id == event.unit.id);
          print('[UnitFavoriteBloc] ✅ Unit removed from API and local. Total favorites: ${_favorites.length}');

          // Save to cache
          await _saveFavoritesToCache();

          emit(UnitFavoriteUpdated(List.from(_favorites)));
        } else {
          throw Exception(response['message'] ?? 'Failed to remove favorite');
        }
      } catch (apiError) {
        print('[UnitFavoriteBloc] API error: $apiError');
        // If API fails, still remove locally
        _favorites.removeWhere((u) => u.id == event.unit.id);
        await _saveFavoritesToCache();
        emit(UnitFavoriteUpdated(List.from(_favorites)));
        throw apiError;
      }
    } catch (e) {
      print('[UnitFavoriteBloc] Error removing favorite: $e');
      emit(UnitFavoriteError('Failed to remove favorite: $e'));
    }
  }

  Future<void> _saveFavoritesToCache() async {
    try {
      print('[UnitFavoriteBloc] Saving ${_favorites.length} favorites to cache...');
      final favoritesJson = json.encode(
        _favorites.map((u) => u.toJson()).toList(),
      );
      print('[UnitFavoriteBloc] JSON size: ${favoritesJson.length} characters');
      await CasheNetwork.insertToCashe(
        key: _favoritesKey,
        value: favoritesJson,
      );
      print('[UnitFavoriteBloc] Cache save completed successfully');
    } catch (e) {
      print('[UnitFavoriteBloc] Error saving favorites to cache: $e');
    }
  }

  // Helper methods to check favorite status and toggle
  bool isFavorite(Unit unit) {
    return _favorites.any((u) => u.id == unit.id);
  }

  void toggleFavorite(Unit unit) {
    print('[UnitFavoriteBloc] toggleFavorite called for unit: ${unit.id}');
    if (isFavorite(unit)) {
      print('[UnitFavoriteBloc] Unit is favorited - removing');
      add(RemoveFavoriteUnit(unit));
    } else {
      print('[UnitFavoriteBloc] Unit is not favorited - adding');
      add(AddFavoriteUnit(unit));
    }
  }

  List<Unit> get favorites => List.from(_favorites);
}
