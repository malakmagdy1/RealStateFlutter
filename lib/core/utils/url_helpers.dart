/// Defensive URL helper to handle both full URLs and relative paths
/// This ensures images load correctly regardless of the format stored in the database
class UrlHelpers {
  // Production base URL
  static String _baseUrl = 'https://aqar.bdcbiz.com';

  /// Fixes image URL to work with production server
  ///
  /// Handles multiple cases:
  /// 1. If URL already has http/https -> uses it as is (after fixing path)
  /// 2. If URL is a relative path -> prepends base URL
  /// 3. If URL is empty/null -> returns empty string
  static String fixImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      print('[URL HELPER] Empty or null URL');
      return '';
    }

    print('[URL HELPER] Original URL: $url');

    // Case 1: URL already has http/https prefix
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Fix incorrect paths
      var fixedUrl = url;

      // Fix /larvel2/ -> /storage/
      if (fixedUrl.contains('/larvel2/')) {
        fixedUrl = fixedUrl.replaceAll('/larvel2/', '/storage/');
        print('[URL HELPER] Fixed /larvel2/ path');
      }

      // Fix /storage/app/public/ -> /storage/
      if (fixedUrl.contains('/storage/app/public/')) {
        fixedUrl = fixedUrl.replaceAll('/storage/app/public/', '/storage/');
        print('[URL HELPER] Fixed /storage/app/public/ path');
      }

      print('[URL HELPER] Final URL: $fixedUrl');
      return fixedUrl;
    }

    // Case 2: Relative path - prepend base URL
    // Remove leading slash if present to avoid double slashes
    String path = url.startsWith('/') ? url.substring(1) : url;

    // Fix /storage/app/public/ -> /storage/ in relative paths
    if (path.contains('storage/app/public/')) {
      path = path.replaceAll('storage/app/public/', 'storage/');
      print('[URL HELPER] Fixed relative path /storage/app/public/');
    }

    // Add /storage/ prefix if the path doesn't already have it
    // Common patterns: company-logos/, compound-images/, unit-images/, etc.
    if (!path.startsWith('storage/') &&
        (path.contains('company-logos/') ||
         path.contains('compound-images/') ||
         path.contains('unit-images/') ||
         path.contains('images/'))) {
      path = 'storage/$path';
      print('[URL HELPER] Added /storage/ prefix to relative path');
    }

    final finalUrl = '$_baseUrl/$path';
    print('[URL HELPER] Final URL (relative): $finalUrl');
    return finalUrl;
  }

  /// Checks if a URL is valid and ready to be used
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
