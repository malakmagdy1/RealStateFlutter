import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/auth/data/repositories/auth_repository.dart';
import 'package:real/feature/auth/presentation/bloc/update_phone_event.dart';
import 'package:real/feature/auth/presentation/bloc/update_phone_state.dart';

class UpdatePhoneBloc extends Bloc<UpdatePhoneEvent, UpdatePhoneState> {
  final AuthRepository _repository;

  UpdatePhoneBloc({required AuthRepository repository})
      : _repository = repository,
        super(UpdatePhoneInitial()) {
    on<UpdatePhoneSubmitEvent>(_onUpdatePhoneSubmit);
  }

  Future<void> _onUpdatePhoneSubmit(
    UpdatePhoneSubmitEvent event,
    Emitter<UpdatePhoneState> emit,
  ) async {
    emit(UpdatePhoneLoading());
    try {
      final response = await _repository.updatePhone(event.request);
      emit(UpdatePhoneSuccess(response));
    } catch (e) {
      emit(UpdatePhoneError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
