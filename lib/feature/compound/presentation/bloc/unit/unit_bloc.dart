import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repository/unit_repository.dart';
import 'unit_event.dart';
import 'unit_state.dart';

class UnitBloc extends Bloc<UnitEvent, UnitState> {
  final UnitRepository repository;

  UnitBloc({required this.repository}) : super(const UnitInitial()) {
    on<FetchUnitsEvent>(_onFetchUnits);
  }

  Future<void> _onFetchUnits(
    FetchUnitsEvent event,
    Emitter<UnitState> emit,
  ) async {
    emit(const UnitLoading());
    try {
      final response = await repository.getUnitsByCompound(
        compoundId: event.compoundId,
        page: event.page,
        limit: event.limit,
      );
      emit(UnitSuccess(response));
    } catch (e) {
      emit(UnitError(e.toString()));
    }
  }
}
