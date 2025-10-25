import 'package:equatable/equatable.dart';
import 'package:real/feature/company/data/models/company_response.dart';

abstract class CompanyState extends Equatable {
  CompanyState();

  @override
  List<Object?> get props => [];
}

class CompanyInitial extends CompanyState {
  CompanyInitial();
}

class CompanyLoading extends CompanyState {
  CompanyLoading();
}

class CompanySuccess extends CompanyState {
  final CompanyResponse response;

  CompanySuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class CompanyError extends CompanyState {
  final String message;

  CompanyError(this.message);

  @override
  List<Object?> get props => [message];
}
