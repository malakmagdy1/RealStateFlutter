import 'package:equatable/equatable.dart';
import 'package:real/feature/company/data/models/company_model.dart';
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
  final List<Company> allCompanies;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  CompanySuccess(
    this.response, {
    required this.allCompanies,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  CompanySuccess copyWith({
    CompanyResponse? response,
    List<Company>? allCompanies,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return CompanySuccess(
      response ?? this.response,
      allCompanies: allCompanies ?? this.allCompanies,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [response, allCompanies, currentPage, hasMore, isLoadingMore];
}

class CompanyError extends CompanyState {
  final String message;

  CompanyError(this.message);

  @override
  List<Object?> get props => [message];
}
