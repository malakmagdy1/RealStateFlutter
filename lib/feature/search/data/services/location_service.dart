import 'package:dio/dio.dart';
import 'package:real/core/utils/constant.dart' as constants;

class LocationService {
  late Dio dio;

  LocationService() {
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

  /// Fetch unique locations (cities/areas) from database
  /// Uses the search-and-filter API to get units and extract unique locations
  Future<List<String>> getLocations() async {
    try {
      print('[LOCATION SERVICE] Fetching locations from search-and-filter API...');

      // Call search-and-filter API with no filters to get all units
      // Use a high limit to get enough units to find all unique locations
      final response = await dio.get('/search-and-filter', queryParameters: {
        'limit': 1000,
      });

      print('[LOCATION SERVICE] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Extract unique locations from units
        Set<String> uniqueLocations = {};

        if (data is Map && data['units'] is List) {
          final units = data['units'] as List;

          for (var unit in units) {
            if (unit is Map) {
              // Try to get location from compound object first
              if (unit['compound'] != null && unit['compound'] is Map) {
                final location = unit['compound']['location'];
                if (location != null && location.toString().isNotEmpty) {
                  uniqueLocations.add(location.toString());
                }
              }
              // Fallback to compound_location field
              else if (unit['compound_location'] != null) {
                final location = unit['compound_location'].toString();
                if (location.isNotEmpty) {
                  uniqueLocations.add(location);
                }
              }
            }
          }
        }

        // Convert to sorted list
        final locations = uniqueLocations.toList()..sort();

        print('[LOCATION SERVICE] ✓ Found ${locations.length} unique locations from ${data['total_units'] ?? 0} units');
        print('[LOCATION SERVICE] Locations: ${locations.join(", ")}');

        return locations;
      } else {
        print('[LOCATION SERVICE] ✗ Error: ${response.statusCode}');
        return _getDefaultLocations();
      }
    } catch (e) {
      print('[LOCATION SERVICE] ✗ Exception: $e');
      print('[LOCATION SERVICE] Error details: ${e.toString()}');
      return _getDefaultLocations();
    }
  }

  /// Fallback: Return empty list if API fails (don't show locations that don't exist)
  List<String> _getDefaultLocations() {
    print('[LOCATION SERVICE] ✗ API failed - returning empty list (no fallback)');
    print('[LOCATION SERVICE] Please check /api/locations endpoint');
    // Return empty list instead of hardcoded locations
    // This ensures we only show locations that actually exist in the database
    return [];
  }
}
