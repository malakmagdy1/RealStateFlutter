import 'package:equatable/equatable.dart';
import 'company_model.dart';

class CompanyResponse extends Equatable {
  final bool success;
  final int count;
  final int total; // Total companies in database
  final List<Company> companies;

  CompanyResponse({
    required this.success,
    required this.count,
    required this.total,
    required this.companies,
  });

  factory CompanyResponse.fromJson(Map<String, dynamic> json) {
    return CompanyResponse(
      success: json['success'] == true || json['success'] == 1,
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      total: int.tryParse(json['total']?.toString() ?? json['count']?.toString() ?? '0') ?? 0,
      companies: (json['data'] as List<dynamic>?)
              ?.map((company) => Company.fromJson(company as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [success, count, total, companies];

  @override
  String toString() {
    return 'CompanyResponse{success: $success, count: $count, total: $total, companies: ${companies.length} companies}';
  }
}
