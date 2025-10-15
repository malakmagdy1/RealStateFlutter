import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/company/data/repositories/company_repository.dart';
import 'package:real/feature/company/presentation/bloc/company_event.dart';
import 'package:real/feature/company/presentation/bloc/company_state.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  final CompanyRepository _repository;

  CompanyBloc({required CompanyRepository repository})
      : _repository = repository,
        super(const CompanyInitial()) {
    on<FetchCompaniesEvent>(_onFetchCompanies);
  }

  Future<void> _onFetchCompanies(
    FetchCompaniesEvent event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    try {
      final response = await _repository.getCompanies();
      emit(CompanySuccess(response));
    } catch (e) {
      emit(CompanyError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
