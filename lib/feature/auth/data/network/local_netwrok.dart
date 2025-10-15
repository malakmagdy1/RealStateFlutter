import 'package:shared_preferences/shared_preferences.dart';

class CasheNetwork {
  static late SharedPreferences sharedPref;

  static Future casheInitialization() async {
    sharedPref = await SharedPreferences.getInstance();
  }

  static Future<bool> insertToCashe({
    required String key,
    required String value,
  }) async {
    return await sharedPref.setString(key, value);
  }

  static String getCasheData({required String key}) {
    return sharedPref.getString(key) ?? "";
  }

  static Future<bool> deletecasheItem({required String key}) async {
    return await sharedPref.remove(key);
  }
}
