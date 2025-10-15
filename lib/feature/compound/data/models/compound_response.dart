import 'package:equatable/equatable.dart';
import 'compound_model.dart';

class CompoundResponse extends Equatable {
  final bool success;
  final int count;
  final String total;
  final int page;
  final int limit;
  final int totalPages;
  final List<Compound> data;

  const CompoundResponse({
    required this.success,
    required this.count,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.data,
  });

  factory CompoundResponse.fromJson(Map<String, dynamic> json) {
    return CompoundResponse(
      success: json['success'] == true || json['success'] == 1,
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      total: json['total']?.toString() ?? '0',
      page: int.tryParse(json['page']?.toString() ?? '1') ?? 1,
      limit: int.tryParse(json['limit']?.toString() ?? '20') ?? 20,
      totalPages: int.tryParse(json['total_pages']?.toString() ?? '1') ?? 1,
      data: (json['data'] as List<dynamic>?)
              ?.map((compound) => Compound.fromJson(compound as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [success, count, total, page, limit, totalPages, data];

  @override
  String toString() {
    return 'CompoundResponse{success: $success, count: $count, total: $total, page: $page, compounds: ${data.length} compounds}';
  }
}
