import 'package:equatable/equatable.dart';

abstract class CompoundEvent extends Equatable {
  const CompoundEvent();

  @override
  List<Object?> get props => [];
}

class FetchCompoundsEvent extends CompoundEvent {
  final int page;
  final int limit;

  const FetchCompoundsEvent({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}

class FetchCompoundsByCompanyEvent extends CompoundEvent {
  final String companyId;
  final int page;
  final int limit;

  const FetchCompoundsByCompanyEvent({
    required this.companyId,
    this.page = 1,
    this.limit = 100,
  });

  @override
  List<Object?> get props => [companyId, page, limit];
}
