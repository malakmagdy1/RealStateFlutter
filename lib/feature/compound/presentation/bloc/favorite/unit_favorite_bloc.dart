import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';

import 'unit_favorite_event.dart';
import 'unit_favorite_state.dart';

class UnitFavoriteBloc extends Bloc<UnitFavoriteEvent, UnitFavoriteState> {
  final List<Unit> _favorites = [];
  static const String _favoritesKey = 'favorite_units';

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
      print('[UnitFavoriteBloc] Loading favorites from cache...');
      final favoritesJson = await CasheNetwork.getCasheData(key: _favoritesKey);

      if (favoritesJson != null && favoritesJson.isNotEmpty) {
        print(
          '[UnitFavoriteBloc] Found cached data: ${favoritesJson.substring(0, 100)}...',
        );
        final List<dynamic> decoded = json.decode(favoritesJson);
        _favorites.clear();
        _favorites.addAll(decoded.map((json) => Unit.fromJson(json)).toList());
        print(
          '[UnitFavoriteBloc] Loaded ${_favorites.length} favorites from cache',
        );
      } else {
        print('[UnitFavoriteBloc] No cached favorites found');
      }

      emit(UnitFavoriteUpdated(List.from(_favorites)));
    } catch (e) {
      print('[UnitFavoriteBloc] Error loading favorites: $e');
      emit(UnitFavoriteError('Failed to load favorites: $e'));
    }
  }

  Future<void> _onAddFavorite(
    AddFavoriteUnit event,
    Emitter<UnitFavoriteState> emit,
  ) async {
    try {
      print('[UnitFavoriteBloc] Adding favorite unit: ${event.unit.id}');

      // Check if already exists
      if (!_favorites.any((u) => u.id == event.unit.id)) {
        _favorites.add(event.unit);
        print(
          '[UnitFavoriteBloc] Unit added. Total favorites: ${_favorites.length}',
        );

        await _saveFavorites();
        print('[UnitFavoriteBloc] Favorites saved to cache');

        emit(UnitFavoriteUpdated(List.from(_favorites)));
        print(
          '[UnitFavoriteBloc] State emitted with ${_favorites.length} favorites',
        );
      } else {
        print('[UnitFavoriteBloc] Unit already in favorites');
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
      _favorites.removeWhere((u) => u.id == event.unit.id);
      await _saveFavorites();
      emit(UnitFavoriteUpdated(List.from(_favorites)));
    } catch (e) {
      emit(UnitFavoriteError('Failed to remove favorite: $e'));
    }
  }

  Future<void> _saveFavorites() async {
    try {
      print('[UnitFavoriteBloc] Saving ${_favorites.length} favorites...');
      final favoritesJson = json.encode(
        _favorites.map((u) => u.toJson()).toList(),
      );
      print('[UnitFavoriteBloc] JSON size: ${favoritesJson.length} characters');
      await CasheNetwork.insertToCashe(
        key: _favoritesKey,
        value: favoritesJson,
      );
      print('[UnitFavoriteBloc] Save completed successfully');
    } catch (e) {
      print('[UnitFavoriteBloc] Error saving favorites: $e');
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
