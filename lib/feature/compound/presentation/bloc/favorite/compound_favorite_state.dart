import 'package:real/feature/compound/data/models/compound_model.dart';

abstract class CompoundFavoriteState {}

class CompoundFavoriteInitial extends CompoundFavoriteState {}

class CompoundFavoriteUpdated extends CompoundFavoriteState {
  final List<Compound> favorites;
  CompoundFavoriteUpdated(this.favorites);
}

class CompoundFavoriteError extends CompoundFavoriteState {
  final String message;
  CompoundFavoriteError(this.message);
}
