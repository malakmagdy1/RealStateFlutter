import 'package:equatable/equatable.dart';
import 'package:real/feature/company/data/models/company_response.dart';

abstract class CompanyState extends Equatable {
  const CompanyState();

  @override
  List<Object?> get props => [];
}

class CompanyInitial extends CompanyState {
  const CompanyInitial();
}

class CompanyLoading extends CompanyState {
  const CompanyLoading();
}

class CompanySuccess extends CompanyState {
  final CompanyResponse response;

  const CompanySuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class CompanyError extends CompanyState {
  final String message;

  const CompanyError(this.message);

  @override
  List<Object?> get props => [message];
}
