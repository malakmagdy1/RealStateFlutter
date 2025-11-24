import 'package:dio/dio.dart';
import 'package:real/core/utils/constant.dart' as constants;

class CompanyService {
  late Dio dio;

  CompanyService() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://aqar.bdcbiz.com/api',
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ));

    // Add interceptor for auth token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (constants.token != null && constants.token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer ${constants.token}';
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
    ));
  }

  /// Fetch all companies from database
  /// Returns a map of company ID to company name for filter dropdown
  Future<Map<String, String>> getCompanies() async {
    try {
      print('[COMPANY SERVICE] Fetching companies from API...');

      // Call companies API endpoint
      final response = await dio.get('/companies');

      print('[COMPANY SERVICE] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Build map of company ID -> company name
        Map<String, String> companies = {};

        if (data is Map && data['data'] is List) {
          final companiesList = data['data'] as List;

          for (var company in companiesList) {
            if (company is Map) {
              final id = company['id']?.toString();
              final name = company['name']?.toString();

              if (id != null && name != null && name.isNotEmpty) {
                companies[id] = name;
              }
            }
          }
        }

        // Sort companies by name
        final sortedCompanies = Map.fromEntries(
          companies.entries.toList()..sort((a, b) => a.value.compareTo(b.value))
        );

        print('[COMPANY SERVICE] ✓ Found ${sortedCompanies.length} companies');
        print('[COMPANY SERVICE] Companies: ${sortedCompanies.values.take(5).join(", ")}${sortedCompanies.length > 5 ? "..." : ""}');

        return sortedCompanies;
      } else {
        print('[COMPANY SERVICE] ✗ Error: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('[COMPANY SERVICE] ✗ Exception: $e');
      print('[COMPANY SERVICE] Error details: ${e.toString()}');
      return {};
    }
  }
}
