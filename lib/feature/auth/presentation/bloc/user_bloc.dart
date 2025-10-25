import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AuthRepository _repository;

  UserBloc({required AuthRepository repository})
      : _repository = repository,
        super(UserInitial()) {
    on<FetchUserEvent>(_onFetchUser);
    on<RefreshUserEvent>(_onRefreshUser);
  }

  Future<void> _onFetchUser(
    FetchUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final user = await _repository.getUserByToken();
      emit(UserSuccess(user));
    } catch (e) {
      emit(UserError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshUser(
    RefreshUserEvent event,
    Emitter<UserState> emit,
  ) async {
    // Don't show loading state for refresh
    try {
      final user = await _repository.getUserByToken();
      emit(UserSuccess(user));
    } catch (e) {
      emit(UserError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
