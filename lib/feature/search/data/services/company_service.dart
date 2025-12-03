import 'package:dio/dio.dart';
import 'package:real/core/utils/constant.dart' as constants;

/// Simple class to hold company filter data with localization
class CompanyFilterItem {
  final String id;
  final String name;
  final String nameEn;
  final String nameAr;

  CompanyFilterItem({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameAr,
  });

  /// Get localized name based on locale
  String getLocalizedName(bool isArabic) {
    if (isArabic) {
      return nameAr.isNotEmpty ? nameAr : name;
    }
    return nameEn.isNotEmpty ? nameEn : name;
  }
}

class CompanyService {
  late Dio dio;

  // Static cache for companies to avoid re-fetching
  static List<CompanyFilterItem>? _cachedCompanies;
  static DateTime? _cacheTime;
  static const _cacheExpiry = Duration(minutes: 30);

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

  /// Clear the cache (useful when user logs out or data changes)
  static void clearCache() {
    _cachedCompanies = null;
    _cacheTime = null;
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    if (_cachedCompanies == null || _cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheExpiry;
  }

  /// Fetch all companies from database
  /// Returns a map of company ID to company name for filter dropdown (legacy)
  Future<Map<String, String>> getCompanies() async {
    final items = await getCompaniesWithLocalization();
    return Map.fromEntries(
      items.map((item) => MapEntry(item.id, item.name))
    );
  }

  /// Fetch all companies with localization support
  /// Returns a list of CompanyFilterItem with both English and Arabic names
  Future<List<CompanyFilterItem>> getCompaniesWithLocalization() async {
    // Return cached data if valid
    if (_isCacheValid()) {
      print('[COMPANY SERVICE] ✓ Returning ${_cachedCompanies!
          .length} cached companies');
      return _cachedCompanies!;
    }

    try {
      print('[COMPANY SERVICE] Fetching companies from API...');

      // Call companies API endpoint
      final response = await dio.get('/companies');

      print('[COMPANY SERVICE] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Build list of company items
        List<CompanyFilterItem> companies = [];

        if (data is Map && data['data'] is List) {
          final companiesList = data['data'] as List;

          for (var company in companiesList) {
            if (company is Map) {
              final id = company['id']?.toString();
              final name = company['name']?.toString() ?? '';
              final nameEn = company['name_en']?.toString() ?? company['name']?.toString() ?? '';
              final nameAr = company['name_ar']?.toString() ?? company['name']?.toString() ?? '';

              if (id != null && name.isNotEmpty) {
                companies.add(CompanyFilterItem(
                  id: id,
                  name: name,
                  nameEn: nameEn,
                  nameAr: nameAr,
                ));
              }
            }
          }
        }

        // Sort companies by name
        companies.sort((a, b) => a.name.compareTo(b.name));

        print('[COMPANY SERVICE] ✓ Found ${companies.length} companies');

        // Cache the results
        _cachedCompanies = companies;
        _cacheTime = DateTime.now();

        return companies;
      } else {
        print('[COMPANY SERVICE] ✗ Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[COMPANY SERVICE] ✗ Exception: $e');
      print('[COMPANY SERVICE] Error details: ${e.toString()}');
      return [];
    }
  }
}
