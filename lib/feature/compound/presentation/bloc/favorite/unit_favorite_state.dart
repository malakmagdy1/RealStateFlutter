import 'package:real/feature/compound/data/models/unit_model.dart';

abstract class UnitFavoriteState {}

class UnitFavoriteInitial extends UnitFavoriteState {}

class UnitFavoriteUpdated extends UnitFavoriteState {
  final List<Unit> favorites;

  UnitFavoriteUpdated(this.favorites);
}

class UnitFavoriteError extends UnitFavoriteState {
  final String message;

  UnitFavoriteError(this.message);
}
