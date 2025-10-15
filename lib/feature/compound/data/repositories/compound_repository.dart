import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/compound/data/models/compound_response.dart';

class CompoundRepository {
  final CompoundWebServices _compoundWebServices;

  CompoundRepository({CompoundWebServices? compoundWebServices})
      : _compoundWebServices = compoundWebServices ?? CompoundWebServices();

  Future<CompoundResponse> getCompounds({int page = 1, int limit = 20}) async {
    try {
      final response = await _compoundWebServices.getCompounds(page: page, limit: limit);
      return response;
    } catch (e) {
      print('Repository Get Compounds Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<CompoundResponse> getCompoundsByCompany({
    required String companyId,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await _compoundWebServices.getCompoundsByCompany(
        companyId: companyId,
        page: page,
        limit: limit,
      );
      return response;
    } catch (e) {
      print('Repository Get Compounds by Company Error: ${e.toString()}');
      rethrow;
    }
  }
}
