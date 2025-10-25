import 'package:equatable/equatable.dart';

import '../../../data/models/unit_model.dart';

abstract class UnitState extends Equatable {
  UnitState();

  @override
  List<Object?> get props => [];
}

class UnitInitial extends UnitState {
  UnitInitial();
}

class UnitLoading extends UnitState {
  UnitLoading();
}

class UnitSuccess extends UnitState {
  final UnitResponse response;

  UnitSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class UnitError extends UnitState {
  final String message;

  UnitError(this.message);

  @override
  List<Object?> get props => [message];
}
