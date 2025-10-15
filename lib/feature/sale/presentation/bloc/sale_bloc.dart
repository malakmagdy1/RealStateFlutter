import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/sale_repository.dart';
import 'sale_event.dart';
import 'sale_state.dart';

class SaleBloc extends Bloc<SaleEvent, SaleState> {
  final SaleRepository repository;

  SaleBloc({required this.repository}) : super(SaleInitial()) {
    on<FetchSalesEvent>(_onFetchSales);
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
}
