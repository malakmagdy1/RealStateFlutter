import '../models/unit_model.dart';
import '../web_services/unit_web_services.dart';

class UnitRepository {
  final UnitWebServices webServices;

  UnitRepository({required this.webServices});

  Future<UnitResponse> getUnitsByCompound({
    required String compoundId,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      return await webServices.getUnitsByCompound(
        compoundId: compoundId,
        page: page,
        limit: limit,
      );
    } catch (e) {
      rethrow;
    }
  }
}
