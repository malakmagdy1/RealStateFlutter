import 'package:real/feature/compound/data/models/compound_model.dart';

sealed class CompoundFavoriteEvent {}

class AddFavoriteCompound extends CompoundFavoriteEvent {
  final Compound compound;

  AddFavoriteCompound(this.compound);
}

class RemoveFavoriteCompound extends CompoundFavoriteEvent {
  final Compound compound;

  RemoveFavoriteCompound(this.compound);
}

class LoadFavoriteCompounds extends CompoundFavoriteEvent {}
