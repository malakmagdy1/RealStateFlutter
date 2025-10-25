import 'package:bloc/bloc.dart';
import 'package:real/feature/auth/data/models/register_request.dart';
import 'package:real/feature/auth/presentation/bloc/register_state.dart';

import '../../data/repositories/auth_repository.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository _authRepository;

  RegisterCubit(AuthRepository authRepository)
      : _authRepository = authRepository,
        super(RegisterInitial());

  Future<void> register(RegisterRequest request) async {
    emit(RegisterLoading());

    try {
      final response = await _authRepository.register(request);
      emit(RegisterSuccess(response));
    } catch (e) {
      emit(RegisterError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
