import 'package:equatable/equatable.dart';

abstract class CompanyEvent extends Equatable {
  CompanyEvent();

  @override
  List<Object?> get props => [];
}

class FetchCompaniesEvent extends CompanyEvent {
  final bool refresh;

  FetchCompaniesEvent({this.refresh = true});

  @override
  List<Object?> get props => [refresh];
}

class LoadMoreCompaniesEvent extends CompanyEvent {
  LoadMoreCompaniesEvent();
}
