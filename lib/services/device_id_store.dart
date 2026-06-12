import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdStore {
  static const _key = "device_id";
  static const _fallbackKey = "installation_id";

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();

    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final platformId = await _platformDeviceId();
    final id = platformId ?? await _fallbackInstallationId(prefs);

    await prefs.setString(_key, id);

    return id;
  }

  static Future<String?> _platformDeviceId() async {
    try {
      final info = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        final id = android.id.trim();

        return id.isNotEmpty ? 'android:$id' : null;
      }

      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        final id = ios.identifierForVendor?.trim();

        return id != null && id.isNotEmpty ? 'ios:$id' : null;
      }
    } catch (_) {
      // 端末IDが取得できない環境では、下のインストールIDへフォールバックする
    }

    return null;
  }

  static Future<String> _fallbackInstallationId(SharedPreferences prefs) async {
    final existing = prefs.getString(_fallbackKey);
    if (existing != null && existing.isNotEmpty) {
      return 'install:$existing';
    }

    final id = const Uuid().v4();
    await prefs.setString(_fallbackKey, id);

    return 'install:$id';
  }
}
