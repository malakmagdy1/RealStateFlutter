import 'package:real/feature/company/data/models/company_response.dart';
import 'package:real/feature/company/data/web_services/company_web_services.dart';

class CompanyRepository {
  final CompanyWebServices _companyWebServices;

  CompanyRepository({CompanyWebServices? companyWebServices})
    : _companyWebServices = companyWebServices ?? CompanyWebServices();

  Future<CompanyResponse> getCompanies() async {
    try {
      final response = await _companyWebServices.getCompanies();
      return response;
    } catch (e) {
      print('Repository Get Companies Error: ${e.toString()}');
      rethrow;
    }
  }
}
