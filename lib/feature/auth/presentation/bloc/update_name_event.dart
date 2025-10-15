import 'package:equatable/equatable.dart';
import 'package:real/feature/auth/data/models/update_name_request.dart';

abstract class UpdateNameEvent extends Equatable {
  const UpdateNameEvent();

  @override
  List<Object?> get props => [];
}

class UpdateNameSubmitEvent extends UpdateNameEvent {
  final UpdateNameRequest request;

  const UpdateNameSubmitEvent(this.request);

  @override
  List<Object?> get props => [request];
}
