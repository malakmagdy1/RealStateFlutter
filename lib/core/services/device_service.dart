import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _deviceIdKey = 'device_unique_id';

  /// Get unique device ID (persists across app sessions)
  /// Uses UUID to ensure true uniqueness per app installation
  static Future<String> getDeviceId() async {
    // Try to get stored device ID first
    String? storedId = await _secureStorage.read(key: _deviceIdKey);
    if (storedId != null && storedId.isNotEmpty) {
      return storedId;
    }

    // Generate a truly unique device ID using UUID + platform prefix
    const uuid = Uuid();
    String deviceId;

    if (kIsWeb) {
      deviceId = 'web_${uuid.v4()}';
    } else if (Platform.isAndroid) {
      // Generate UUID and prefix with android info for debugging
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      final uniquePart = uuid.v4().substring(0, 8);
      deviceId = 'android_${androidInfo.model.replaceAll(' ', '_')}_$uniquePart';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      // Try to use identifierForVendor, fallback to UUID if not available
      if (iosInfo.identifierForVendor != null && iosInfo.identifierForVendor!.isNotEmpty) {
        deviceId = 'ios_${iosInfo.identifierForVendor}';
      } else {
        final uniquePart = uuid.v4().substring(0, 8);
        deviceId = 'ios_${iosInfo.model.replaceAll(' ', '_')}_$uniquePart';
      }
    } else if (Platform.isWindows) {
      deviceId = 'windows_${uuid.v4()}';
    } else if (Platform.isMacOS) {
      deviceId = 'macos_${uuid.v4()}';
    } else {
      deviceId = 'unknown_${uuid.v4()}';
    }

    // Store the device ID for future use
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    print('[DeviceService] Generated new device ID: $deviceId');
    return deviceId;
  }

  /// Get device name (user-friendly)
  static Future<String> getDeviceName() async {
    if (kIsWeb) {
      return 'Web Browser';
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return '${androidInfo.brand} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.name; // e.g., "John's iPhone"
    } else {
      return 'Unknown Device';
    }
  }

  /// Get device type (ios, android, web, etc.)
  static Future<String> getDeviceType() async {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else {
      return 'unknown';
    }
  }

  /// Get OS version
  static Future<String> getOSVersion() async {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return 'Android ${androidInfo.version.release}';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      return 'iOS ${iosInfo.systemVersion}';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macInfo = await _deviceInfo.macOsInfo;
      return 'macOS ${macInfo.osRelease}';
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await _deviceInfo.linuxInfo;
      return 'Linux ${linuxInfo.version ?? ''}';
    } else {
      return 'Unknown';
    }
  }

  /// Get app version
  static Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Get all device info in one call
  static Future<Map<String, String>> getAllDeviceInfo() async {
    return {
      'device_id': await getDeviceId(),
      'device_name': await getDeviceName(),
      'device_type': await getDeviceType(),
      'os_version': await getOSVersion(),
      'app_version': await getAppVersion(),
    };
  }

  /// Clear stored device ID (useful for testing)
  static Future<void> clearDeviceId() async {
    await _secureStorage.delete(key: _deviceIdKey);
  }
}
