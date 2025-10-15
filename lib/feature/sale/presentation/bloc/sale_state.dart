import 'package:equatable/equatable.dart';

import '../../data/models/sale_model.dart';

abstract class SaleState extends Equatable {
  const SaleState();

  @override
  List<Object?> get props => [];
}

class SaleInitial extends SaleState {}

class SaleLoading extends SaleState {}

class SaleSuccess extends SaleState {
  final SaleResponse response;

  const SaleSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

class SaleError extends SaleState {
  final String message;

  const SaleError({required this.message});

  @override
  List<Object?> get props => [message];
}
