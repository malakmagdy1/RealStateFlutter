import 'package:equatable/equatable.dart';
import 'package:real/feature/compound/data/models/compound_response.dart';

abstract class CompoundState extends Equatable {
  CompoundState();

  @override
  List<Object?> get props => [];
}

class CompoundInitial extends CompoundState {
  CompoundInitial();
}

class CompoundLoading extends CompoundState {
  CompoundLoading();
}

class CompoundSuccess extends CompoundState {
  final CompoundResponse response;

  CompoundSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class CompoundError extends CompoundState {
  final String message;

  CompoundError(this.message);

  @override
  List<Object?> get props => [message];
}

class CompoundDetailLoading extends CompoundState {
  CompoundDetailLoading();
}

class CompoundDetailSuccess extends CompoundState {
  final Map<String, dynamic> compoundData;

  CompoundDetailSuccess(this.compoundData);

  @override
  List<Object?> get props => [compoundData];
}

class CompoundDetailError extends CompoundState {
  final String message;

  CompoundDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
