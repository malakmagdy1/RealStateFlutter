import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/company/data/repositories/company_repository.dart';
import 'package:real/feature/company/presentation/bloc/company_event.dart';
import 'package:real/feature/company/presentation/bloc/company_state.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  final CompanyRepository _repository;

  CompanyBloc({required CompanyRepository repository})
      : _repository = repository,
        super(CompanyInitial()) {
    on<FetchCompaniesEvent>(_onFetchCompanies);
    on<LoadMoreCompaniesEvent>(_onLoadMoreCompanies);
  }

  Future<void> _onFetchCompanies(
    FetchCompaniesEvent event,
    Emitter<CompanyState> emit,
  ) async {
    emit(CompanyLoading());
    try {
      // API returns all companies at once - no pagination needed
      final response = await _repository.getCompanies();
      print('[COMPANY BLOC] Received ${response.companies.length} companies from repository');
      emit(CompanySuccess(
        response,
        allCompanies: response.companies,
        currentPage: 1,
        hasMore: false, // API returns all data at once
      ));
    } catch (e) {
      print('[COMPANY BLOC] Error: $e');
      emit(CompanyError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadMoreCompanies(
    LoadMoreCompaniesEvent event,
    Emitter<CompanyState> emit,
  ) async {
    // API returns all data at once, no more to load
  }
}
