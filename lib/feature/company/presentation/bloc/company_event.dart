import 'package:equatable/equatable.dart';

abstract class CompanyEvent extends Equatable {
  const CompanyEvent();

  @override
  List<Object?> get props => [];
}

class FetchCompaniesEvent extends CompanyEvent {
  const FetchCompaniesEvent();
}
