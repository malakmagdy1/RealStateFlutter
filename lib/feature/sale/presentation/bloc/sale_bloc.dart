import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/sale_repository.dart';
import 'sale_event.dart';
import 'sale_state.dart';

class SaleBloc extends Bloc<SaleEvent, SaleState> {
  final SaleRepository repository;

  SaleBloc({required this.repository}) : super(SaleInitial()) {
    on<FetchSalesEvent>(_onFetchSales);
    on<FetchSalesByCompanyEvent>(_onFetchSalesByCompany);
    on<FetchSalesByCompoundEvent>(_onFetchSalesByCompound);
    on<FetchSalesByUnitEvent>(_onFetchSalesByUnit);
  }

  Future<void> _onFetchSales(
    FetchSalesEvent event,
    Emitter<SaleState> emit,
  ) async {
    emit(SaleLoading());
    try {
      print('[SaleBloc] Fetching sales...');
      final response = await repository.getSales(
        page: event.page,
        limit: event.limit,
      );
      print('[SaleBloc] Success: ${response.sales.length} sales fetched');
      emit(SaleSuccess(response: response));
    } catch (e) {
      print('[SaleBloc] Error: $e');
      emit(SaleError(message: e.toString()));
    }
  }

  Future<void> _onFetchSalesByCompany(
    FetchSalesByCompanyEvent event,
    Emitter<SaleState> emit,
  ) async {
    emit(SaleLoading());
    try {
      print('[SaleBloc] Fetching sales for company ${event.companyId}...');
      final response = await repository.getSalesByCompany(
        event.companyId,
        page: event.page,
        limit: event.limit,
      );
      print('[SaleBloc] Success: ${response.sales.length} sales fetched for company');
      emit(SaleSuccess(response: response));
    } catch (e) {
      print('[SaleBloc] Error: $e');
      emit(SaleError(message: e.toString()));
    }
  }

  Future<void> _onFetchSalesByCompound(
    FetchSalesByCompoundEvent event,
    Emitter<SaleState> emit,
  ) async {
    emit(SaleLoading());
    try {
      print('[SaleBloc] Fetching sales for compound ${event.compoundId}...');
      final response = await repository.getSalesByCompound(
        event.compoundId,
        page: event.page,
        limit: event.limit,
      );
      print('[SaleBloc] Success: ${response.sales.length} sales fetched for compound');
      emit(SaleSuccess(response: response));
    } catch (e) {
      print('[SaleBloc] Error: $e');
      emit(SaleError(message: e.toString()));
    }
  }

  Future<void> _onFetchSalesByUnit(
    FetchSalesByUnitEvent event,
    Emitter<SaleState> emit,
  ) async {
    emit(SaleLoading());
    try {
      print('[SaleBloc] Fetching sales for unit ${event.unitId}...');
      final response = await repository.getSalesByUnit(
        event.unitId,
        page: event.page,
        limit: event.limit,
      );
      print('[SaleBloc] Success: ${response.sales.length} sales fetched for unit');
      emit(SaleSuccess(response: response));
    } catch (e) {
      print('[SaleBloc] Error: $e');
      emit(SaleError(message: e.toString()));
    }
  }
}
