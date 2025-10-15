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
