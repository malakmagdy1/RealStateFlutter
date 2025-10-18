import 'package:equatable/equatable.dart';

abstract class SaleEvent extends Equatable {
  const SaleEvent();

  @override
  List<Object?> get props => [];
}

class FetchSalesEvent extends SaleEvent {
  final int page;
  final int limit;

  const FetchSalesEvent({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}

class FetchSalesByCompanyEvent extends SaleEvent {
  final String companyId;
  final int page;
  final int limit;

  const FetchSalesByCompanyEvent({
    required this.companyId,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [companyId, page, limit];
}

class FetchSalesByCompoundEvent extends SaleEvent {
  final String compoundId;
  final int page;
  final int limit;

  const FetchSalesByCompoundEvent({
    required this.compoundId,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [compoundId, page, limit];
}

class FetchSalesByUnitEvent extends SaleEvent {
  final String unitId;
  final int page;
  final int limit;

  const FetchSalesByUnitEvent({
    required this.unitId,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [unitId, page, limit];
}
