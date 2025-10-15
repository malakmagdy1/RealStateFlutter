import 'package:equatable/equatable.dart';

import '../../../data/models/unit_model.dart';

abstract class UnitState extends Equatable {
  const UnitState();

  @override
  List<Object?> get props => [];
}

class UnitInitial extends UnitState {
  const UnitInitial();
}

class UnitLoading extends UnitState {
  const UnitLoading();
}

class UnitSuccess extends UnitState {
  final UnitResponse response;

  const UnitSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class UnitError extends UnitState {
  final String message;

  const UnitError(this.message);

  @override
  List<Object?> get props => [message];
}
