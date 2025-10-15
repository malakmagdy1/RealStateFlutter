import '../models/sale_model.dart';
import '../services/sale_web_services.dart';

class SaleRepository {
  final SaleWebServices webServices;

  SaleRepository({required this.webServices});

  Future<SaleResponse> getSales({
    int page = 1,
    int limit = 20,
    String? saleType,
    String? companyId,
    bool activeOnly = true,
  }) async {
    try {
      final response = await webServices.getSales(
        page: page,
        limit: limit,
        saleType: saleType,
        companyId: companyId,
        activeOnly: activeOnly,
      );
      return SaleResponse.fromJson(response);
    } catch (e) {
      throw Exception('Repository Error: $e');
    }
  }
}
