import 'package:equatable/equatable.dart';

abstract class UnitEvent extends Equatable {
  const UnitEvent();

  @override
  List<Object?> get props => [];
}

class FetchUnitsEvent extends UnitEvent {
  final String compoundId;
  final int page;
  final int limit;

  const FetchUnitsEvent({
    required this.compoundId,
    this.page = 1,
    this.limit = 100,
  });

  @override
  List<Object?> get props => [compoundId, page, limit];
}
