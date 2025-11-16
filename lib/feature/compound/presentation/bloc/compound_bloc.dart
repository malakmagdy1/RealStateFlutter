import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/compound/data/repositories/compound_repository.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature/compound/data/services/weekly_recommendations_service.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'dart:math';

class CompoundBloc extends Bloc<CompoundEvent, CompoundState> {
  final CompoundRepository _repository;

  CompoundBloc({required CompoundRepository repository})
      : _repository = repository,
        super(CompoundInitial()) {
    on<FetchCompoundsEvent>(_onFetchCompounds);
    on<FetchCompoundsByCompanyEvent>(_onFetchCompoundsByCompany);
    on<FetchCompoundDetailEvent>(_onFetchCompoundDetail);
    on<FetchWeeklyRecommendedCompoundsEvent>(_onFetchWeeklyRecommended);
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

  Future<void> _onFetchWeeklyRecommended(
    FetchWeeklyRecommendedCompoundsEvent event,
    Emitter<CompoundState> emit,
  ) async {
    emit(CompoundLoading());
    try {
      print('[WEEKLY RECOMMENDATIONS] Starting fetch...');

      // Check if we need to refresh (weekly check)
      final shouldRefresh = await WeeklyRecommendationsService.shouldRefreshRecommendations();

      if (!shouldRefresh && !event.forceRefresh) {
        // Use cached recommendations
        print('[WEEKLY RECOMMENDATIONS] Using cached recommendations');
        final savedIds = await WeeklyRecommendationsService.getSavedRecommendedIds();

        if (savedIds.isNotEmpty) {
          // Fetch all compounds and filter by saved IDs
          final response = await _repository.getCompounds(page: 1, limit: 100);
          final recommendedCompounds = response.data.where((compound) {
            return savedIds.contains(compound.id);
          }).toList();

          print('[WEEKLY RECOMMENDATIONS] Loaded ${recommendedCompounds.length} cached compounds');
          emit(CompoundSuccess(response.copyWith(data: recommendedCompounds)));
          return;
        }
      }

      // Need to generate new recommendations
      print('[WEEKLY RECOMMENDATIONS] Generating new recommendations');

      // Fetch a large set of compounds
      final response = await _repository.getCompounds(page: 1, limit: 100);
      final allCompounds = response.data;

      if (allCompounds.isEmpty) {
        emit(CompoundSuccess(response));
        return;
      }

      // Randomly select 10 compounds
      final random = Random();
      final List<Compound> shuffled = List<Compound>.from(allCompounds)..shuffle(random);
      final List<Compound> selectedCompounds = shuffled.take(10).toList();

      // Save the IDs for next week
      final List<String> selectedIds = selectedCompounds.map((c) => c.id.toString()).toList();
      await WeeklyRecommendationsService.saveRecommendedIds(selectedIds);
      await WeeklyRecommendationsService.saveLastUpdateTimestamp();

      print('[WEEKLY RECOMMENDATIONS] Selected ${selectedCompounds.length} new compounds');

      emit(CompoundSuccess(response.copyWith(data: selectedCompounds)));
    } catch (e) {
      print('[WEEKLY RECOMMENDATIONS] Error: $e');
      emit(CompoundError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
