import 'package:equatable/equatable.dart';
import 'package:real/feature/compound/data/models/compound_response.dart';

abstract class CompoundState extends Equatable {
  const CompoundState();

  @override
  List<Object?> get props => [];
}

class CompoundInitial extends CompoundState {
  const CompoundInitial();
}

class CompoundLoading extends CompoundState {
  const CompoundLoading();
}

class CompoundSuccess extends CompoundState {
  final CompoundResponse response;

  const CompoundSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class CompoundError extends CompoundState {
  final String message;

  const CompoundError(this.message);

  @override
  List<Object?> get props => [message];
}
