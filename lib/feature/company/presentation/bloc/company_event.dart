import 'package:equatable/equatable.dart';

abstract class CompanyEvent extends Equatable {
  CompanyEvent();

  @override
  List<Object?> get props => [];
}

class FetchCompaniesEvent extends CompanyEvent {
  FetchCompaniesEvent();
}
