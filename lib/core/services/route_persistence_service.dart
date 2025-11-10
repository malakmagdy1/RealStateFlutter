import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist the current route for web refresh support
class RoutePersistenceService {
  static const String _routeKey = 'last_visited_route';
  static const String _routeParamsKey = 'last_route_params';

  /// Save the current route to SharedPreferences
  static Future<void> saveRoute(String route, {Map<String, String>? params}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_routeKey, route);

      if (params != null && params.isNotEmpty) {
        // Convert params map to a simple string format: key1=value1,key2=value2
        final paramsString = params.entries.map((e) => '${e.key}=${e.value}').join(',');
        await prefs.setString(_routeParamsKey, paramsString);
      } else {
        await prefs.remove(_routeParamsKey);
      }

      print('[ROUTE PERSISTENCE] Saved route: $route with params: $params');
    } catch (e) {
      print('[ROUTE PERSISTENCE] Error saving route: $e');
    }
  }

  /// Get the saved route from SharedPreferences
  static Future<String?> getSavedRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final route = prefs.getString(_routeKey);
      print('[ROUTE PERSISTENCE] Retrieved route: $route');
      return route;
    } catch (e) {
      print('[ROUTE PERSISTENCE] Error getting saved route: $e');
      return null;
    }
  }

  /// Get the saved route parameters
  static Future<Map<String, String>?> getSavedRouteParams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paramsString = prefs.getString(_routeParamsKey);

      if (paramsString == null || paramsString.isEmpty) {
        return null;
      }

      // Parse the params string back to a map
      final params = <String, String>{};
      for (final entry in paramsString.split(',')) {
        final parts = entry.split('=');
        if (parts.length == 2) {
          params[parts[0]] = parts[1];
        }
      }

      print('[ROUTE PERSISTENCE] Retrieved params: $params');
      return params;
    } catch (e) {
      print('[ROUTE PERSISTENCE] Error getting saved route params: $e');
      return null;
    }
  }

  /// Clear the saved route (call on logout)
  static Future<void> clearSavedRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_routeKey);
      await prefs.remove(_routeParamsKey);
      print('[ROUTE PERSISTENCE] Cleared saved route');
    } catch (e) {
      print('[ROUTE PERSISTENCE] Error clearing saved route: $e');
    }
  }

  /// Check if a route should be saved (exclude login/signup screens)
  static bool shouldSaveRoute(String route) {
    // Don't save login, signup, or authentication screens
    final excludedRoutes = [
      '/login',
      '/signup',
      '/forgot-password',
      '/email-verification',
    ];

    return !excludedRoutes.contains(route);
  }

  /// Get full route with parameters
  static Future<String?> getFullSavedRoute() async {
    final route = await getSavedRoute();
    print('[ROUTE PERSISTENCE] Retrieved saved route: $route');

    // Route is now saved with actual values, not placeholders
    // So we can return it directly
    return route;
  }
}
