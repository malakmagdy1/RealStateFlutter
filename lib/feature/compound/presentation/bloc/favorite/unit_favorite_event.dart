import 'package:real/feature/compound/data/models/unit_model.dart';

sealed class UnitFavoriteEvent {}

class AddFavoriteUnit extends UnitFavoriteEvent {
  final Unit unit;
  AddFavoriteUnit(this.unit);
}

class RemoveFavoriteUnit extends UnitFavoriteEvent {
  final Unit unit;
  RemoveFavoriteUnit(this.unit);
}

class LoadFavoriteUnits extends UnitFavoriteEvent {}
