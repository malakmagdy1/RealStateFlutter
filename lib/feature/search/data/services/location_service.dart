import 'package:dio/dio.dart';
import 'package:real/core/utils/constant.dart' as constants;

/// Simple class to hold location filter data with localization
class LocationFilterItem {
  final String location;
  final String locationEn;
  final String locationAr;

  LocationFilterItem({
    required this.location,
    required this.locationEn,
    required this.locationAr,
  });

  /// Get localized location based on locale
  String getLocalizedName(bool isArabic) {
    if (isArabic) {
      return locationAr.isNotEmpty ? locationAr : location;
    }
    return locationEn.isNotEmpty ? locationEn : location;
  }
}

class LocationService {
  late Dio dio;

  // Static cache for locations to avoid re-fetching
  static List<LocationFilterItem>? _cachedLocations;
  static DateTime? _cacheTime;
  static const _cacheExpiry = Duration(minutes: 30);

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

  /// Clear the cache (useful when user logs out or language changes)
  static void clearCache() {
    _cachedLocations = null;
    _cacheTime = null;
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    if (_cachedLocations == null || _cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheExpiry;
  }

  /// Fetch unique locations (cities/areas) from database (legacy)
  /// Uses the search-and-filter API to get units and extract unique locations
  Future<List<String>> getLocations() async {
    final items = await getLocationsWithLocalization();
    return items.map((item) => item.location).toList();
  }

  /// Fetch unique locations with localization support
  /// Returns a list of LocationFilterItem with both English and Arabic names
  /// Fetches from companies API to get compounds with localized location data
  Future<List<LocationFilterItem>> getLocationsWithLocalization() async {
    // Return cached data if valid
    if (_isCacheValid()) {
      print('[LOCATION SERVICE] ✓ Returning ${_cachedLocations!
          .length} cached locations');
      return _cachedLocations!;
    }

    try {
      print('[LOCATION SERVICE] Fetching locations from companies API...');

      // Call companies API to get compounds with localized locations
      final response = await dio.get('/companies');

      print('[LOCATION SERVICE] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Extract unique locations from compounds (use Map to store localized versions)
        Map<String, LocationFilterItem> uniqueLocations = {};

        // Get companies array from response
        List<dynamic> companies = [];
        if (data is Map && data['companies'] is List) {
          companies = data['companies'] as List;
        } else if (data is Map && data['data'] is List) {
          companies = data['data'] as List;
        } else if (data is List) {
          companies = data;
        }

        print('[LOCATION SERVICE] Processing ${companies.length} companies...');

        for (var company in companies) {
          if (company is Map && company['compounds'] is List) {
            final compounds = company['compounds'] as List;

            for (var compound in compounds) {
              if (compound is Map) {
                final location = compound['location']?.toString() ?? '';
                final locationEn = compound['location_en']?.toString() ?? '';
                final locationAr = compound['location_ar']?.toString() ?? '';

                // Use location as the key to avoid duplicates
                if (location.isNotEmpty && !uniqueLocations.containsKey(location)) {
                  uniqueLocations[location] = LocationFilterItem(
                    location: location,
                    locationEn: locationEn.isNotEmpty ? locationEn : location,
                    locationAr: locationAr.isNotEmpty ? locationAr : location,
                  );
                  print('[LOCATION SERVICE] Added location: $location (EN: $locationEn, AR: $locationAr)');
                }
              }
            }
          }
        }

        // Convert to sorted list
        final locations = uniqueLocations.values.toList()
          ..sort((a, b) => a.location.compareTo(b.location));

        print('[LOCATION SERVICE] ✓ Found ${locations.length} unique locations');

        // Cache the results
        _cachedLocations = locations;
        _cacheTime = DateTime.now();

        return locations;
      } else {
        print('[LOCATION SERVICE] ✗ Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[LOCATION SERVICE] ✗ Exception: $e');
      print('[LOCATION SERVICE] Error details: ${e.toString()}');
      return [];
    }
  }
}
