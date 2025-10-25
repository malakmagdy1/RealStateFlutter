import 'package:equatable/equatable.dart';

abstract class SaleEvent extends Equatable {
  SaleEvent();

  @override
  List<Object?> get props => [];
}

class FetchSalesEvent extends SaleEvent {
  final int page;
  final int limit;

  FetchSalesEvent({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}

class FetchSalesByCompanyEvent extends SaleEvent {
  final String companyId;
  final int page;
  final int limit;

  FetchSalesByCompanyEvent({
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

  FetchSalesByCompoundEvent({
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

  FetchSalesByUnitEvent({
    required this.unitId,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [unitId, page, limit];
}
