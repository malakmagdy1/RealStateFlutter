import 'package:equatable/equatable.dart';

abstract class CompoundEvent extends Equatable {
  CompoundEvent();

  @override
  List<Object?> get props => [];
}

class FetchCompoundsEvent extends CompoundEvent {
  final int page;
  final int limit;
  final bool forceRefresh;

  FetchCompoundsEvent({this.page = 1, this.limit = 20, this.forceRefresh = false});

  @override
  List<Object?> get props => [page, limit, forceRefresh];
}

class FetchCompoundsByCompanyEvent extends CompoundEvent {
  final String companyId;
  final int page;
  final int limit;

  FetchCompoundsByCompanyEvent({
    required this.companyId,
    this.page = 1,
    this.limit = 100,
  });

  @override
  List<Object?> get props => [companyId, page, limit];
}

class FetchCompoundDetailEvent extends CompoundEvent {
  final String compoundId;

  FetchCompoundDetailEvent({required this.compoundId});

  @override
  List<Object?> get props => [compoundId];
}

class FetchWeeklyRecommendedCompoundsEvent extends CompoundEvent {
  final bool forceRefresh;

  FetchWeeklyRecommendedCompoundsEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}
