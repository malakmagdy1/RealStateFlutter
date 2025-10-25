import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/compound/data/repositories/compound_repository.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';

class CompoundBloc extends Bloc<CompoundEvent, CompoundState> {
  final CompoundRepository _repository;

  CompoundBloc({required CompoundRepository repository})
      : _repository = repository,
        super(CompoundInitial()) {
    on<FetchCompoundsEvent>(_onFetchCompounds);
    on<FetchCompoundsByCompanyEvent>(_onFetchCompoundsByCompany);
    on<FetchCompoundDetailEvent>(_onFetchCompoundDetail);
  }

  Future<void> _onFetchCompounds(
    FetchCompoundsEvent event,
    Emitter<CompoundState> emit,
  ) async {
    emit(CompoundLoading());
    try {
      final response = await _repository.getCompounds(
        page: event.page,
        limit: event.limit,
      );
      emit(CompoundSuccess(response));
    } catch (e) {
      emit(CompoundError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchCompoundsByCompany(
    FetchCompoundsByCompanyEvent event,
    Emitter<CompoundState> emit,
  ) async {
    emit(CompoundLoading());
    try {
      final response = await _repository.getCompoundsByCompany(
        companyId: event.companyId,
        page: event.page,
        limit: event.limit,
      );
      emit(CompoundSuccess(response));
    } catch (e) {
      emit(CompoundError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchCompoundDetail(
    FetchCompoundDetailEvent event,
    Emitter<CompoundState> emit,
  ) async {
    emit(CompoundDetailLoading());
    try {
      final compoundData = await _repository.getCompoundById(event.compoundId);
      emit(CompoundDetailSuccess(compoundData));
    } catch (e) {
      emit(CompoundDetailError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
