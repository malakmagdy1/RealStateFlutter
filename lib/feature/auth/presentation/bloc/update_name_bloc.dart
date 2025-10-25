import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/auth/data/repositories/auth_repository.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_event.dart';
import 'package:real/feature/auth/presentation/bloc/update_name_state.dart';

class UpdateNameBloc extends Bloc<UpdateNameEvent, UpdateNameState> {
  final AuthRepository _repository;

  UpdateNameBloc({required AuthRepository repository})
      : _repository = repository,
        super(UpdateNameInitial()) {
    on<UpdateNameSubmitEvent>(_onUpdateNameSubmit);
  }

  Future<void> _onUpdateNameSubmit(
    UpdateNameSubmitEvent event,
    Emitter<UpdateNameState> emit,
  ) async {
    emit(UpdateNameLoading());
    try {
      final response = await _repository.updateName(event.request);
      emit(UpdateNameSuccess(response));
    } catch (e) {
      emit(UpdateNameError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
