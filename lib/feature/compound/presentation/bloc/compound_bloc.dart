import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/compound/data/repositories/compound_repository.dart';
import 'package:real/feature/compound/presentation/bloc/compound_event.dart';
import 'package:real/feature/compound/presentation/bloc/compound_state.dart';
import 'package:real/feature/compound/data/services/ai_weekly_recommendations_service.dart';

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
    // Only show loading on first page
    final currentState = state;
    if (event.page == 1) {
      emit(CompoundLoading());
    }

    try {
      // Use getCompoundsWithDetails to get full data for cards
      final response = await _repository.getCompoundsWithDetails(
        page: event.page,
        limit: event.limit,
        forceRefresh: event.forceRefresh,
      );

      // If loading more pages (page > 1), accumulate compounds
      if (event.page > 1 && currentState is CompoundSuccess) {
        final existingCompounds = currentState.response.data;
        final newCompounds = response.data;
        final allCompounds = [...existingCompounds, ...newCompounds];

        // Create updated response with accumulated data and current page
        final updatedResponse = response.copyWith(
          data: allCompounds,
          page: event.page,
        );
        emit(CompoundSuccess(updatedResponse));
      } else {
        emit(CompoundSuccess(response));
      }
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
      // Use getCompoundsByCompanyWithDetails to get full data for cards
      final response = await _repository.getCompoundsByCompanyWithDetails(
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
      // Check if we need to refresh (weekly check)
      final shouldRefresh = await AIWeeklyRecommendationsService.shouldRefreshRecommendations();

      if (!shouldRefresh && !event.forceRefresh) {
        // Use cached recommendations
        final savedIds = await AIWeeklyRecommendationsService.getSavedRecommendedIds();

        if (savedIds.isNotEmpty) {
          // Fetch all compounds WITH DETAILS and filter by saved IDs
          final response = await _repository.getCompoundsWithDetails(page: 1, limit: 100);
          final recommendedCompounds = response.data.where((compound) {
            return savedIds.contains(compound.id.toString());
          }).toList();

          emit(CompoundSuccess(response.copyWith(data: recommendedCompounds)));
          return;
        }
      }

      // Need to generate new AI-powered recommendations
      // Fetch a large set of compounds WITH DETAILS for AI to analyze
      final response = await _repository.getCompoundsWithDetails(page: 1, limit: 100);
      final allCompounds = response.data;

      if (allCompounds.isEmpty) {
        emit(CompoundSuccess(response));
        return;
      }

      // Use AI to select the best 10 compounds
      final selectedIds = await AIWeeklyRecommendationsService.generateAIRecommendations(allCompounds);

      // Filter compounds by AI-selected IDs
      final selectedCompounds = allCompounds.where((compound) {
        return selectedIds.contains(compound.id.toString());
      }).toList();

      // Save the IDs for next week
      await AIWeeklyRecommendationsService.saveRecommendedIds(selectedIds);
      await AIWeeklyRecommendationsService.saveLastUpdateTimestamp();

      emit(CompoundSuccess(response.copyWith(data: selectedCompounds)));
    } catch (e) {
      emit(CompoundError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
