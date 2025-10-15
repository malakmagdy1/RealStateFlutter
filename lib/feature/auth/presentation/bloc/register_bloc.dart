import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _repository;

  RegisterBloc({required AuthRepository repository})
      : _repository = repository,
        super(const RegisterInitial()) {
    on<RegisterSubmitEvent>(_onRegisterSubmit);
  }

  Future<void> _onRegisterSubmit(
    RegisterSubmitEvent event,
    Emitter<RegisterState> emit,
  ) async {
    emit(const RegisterLoading());
    try {
      final response = await _repository.register(event.request);
      emit(RegisterSuccess(response));
    } catch (e) {
      emit(RegisterError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
