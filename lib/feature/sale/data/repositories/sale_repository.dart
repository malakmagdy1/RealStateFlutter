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
    String? compoundId,
    String? unitId,
    bool activeOnly = true,
  }) async {
    try {
      final response = await webServices.getSales(
        page: page,
        limit: limit,
        saleType: saleType,
        companyId: companyId,
        compoundId: compoundId,
        unitId: unitId,
        activeOnly: activeOnly,
      );
      return SaleResponse.fromJson(response);
    } catch (e) {
      throw Exception('Repository Error: $e');
    }
  }

  Future<SaleResponse> getSalesByCompany(String companyId, {int page = 1, int limit = 20}) async {
    try {
      final response = await webServices.getSalesByCompany(companyId, page: page, limit: limit);
      return SaleResponse.fromJson(response);
    } catch (e) {
      throw Exception('Repository Error: $e');
    }
  }

  Future<SaleResponse> getSalesByCompound(String compoundId, {int page = 1, int limit = 20}) async {
    try {
      final response = await webServices.getSalesByCompound(compoundId, page: page, limit: limit);
      return SaleResponse.fromJson(response);
    } catch (e) {
      throw Exception('Repository Error: $e');
    }
  }

  Future<SaleResponse> getSalesByUnit(String unitId, {int page = 1, int limit = 20}) async {
    try {
      final response = await webServices.getSalesByUnit(unitId, page: page, limit: limit);
      return SaleResponse.fromJson(response);
    } catch (e) {
      throw Exception('Repository Error: $e');
    }
  }
}
