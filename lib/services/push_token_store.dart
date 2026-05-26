import 'package:shared_preferences/shared_preferences.dart';

class PushTokenStore {
  static const _key = "fcm_token";

  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
}
