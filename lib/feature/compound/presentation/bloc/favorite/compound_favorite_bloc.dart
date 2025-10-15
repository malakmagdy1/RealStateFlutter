import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'compound_favorite_event.dart';
import 'compound_favorite_state.dart';

class CompoundFavoriteBloc extends Bloc<CompoundFavoriteEvent, CompoundFavoriteState> {
  final List<Compound> _favorites = [];
  static const String _favoritesKey = 'favorite_compounds';

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
      final favoritesJson = await CasheNetwork.getCasheData(key: _favoritesKey);
      if (favoritesJson != null && favoritesJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        _favorites.clear();
        _favorites.addAll(decoded.map((json) => Compound.fromJson(json)).toList());
      }
      emit(CompoundFavoriteUpdated(List.from(_favorites)));
    } catch (e) {
      emit(CompoundFavoriteError('Failed to load favorites: $e'));
    }
  }

  Future<void> _onAddFavorite(
    AddFavoriteCompound event,
    Emitter<CompoundFavoriteState> emit,
  ) async {
    try {
      // Check if already exists
      if (!_favorites.any((c) => c.id == event.compound.id)) {
        _favorites.add(event.compound);
        await _saveFavorites();
        emit(CompoundFavoriteUpdated(List.from(_favorites)));
      }
    } catch (e) {
      emit(CompoundFavoriteError('Failed to add favorite: $e'));
    }
  }

  Future<void> _onRemoveFavorite(
    RemoveFavoriteCompound event,
    Emitter<CompoundFavoriteState> emit,
  ) async {
    try {
      _favorites.removeWhere((c) => c.id == event.compound.id);
      await _saveFavorites();
      emit(CompoundFavoriteUpdated(List.from(_favorites)));
    } catch (e) {
      emit(CompoundFavoriteError('Failed to remove favorite: $e'));
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final favoritesJson = json.encode(
        _favorites.map((c) => c.toJson()).toList(),
      );
      await CasheNetwork.insertToCashe(key: _favoritesKey, value: favoritesJson);
    } catch (e){
      print('Error saving favorites: $e');
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
