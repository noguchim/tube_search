// app_version.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../widgets/app_dialog.dart';
import 'app_logger.dart';

/// ===============================
/// constants
/// ===============================
const _dismissedUpdateVersionKey = 'dismissed_update_version';

/// ===============================
/// version utils
/// ===============================
Future<String> getCurrentVersion() async {
  final info = await PackageInfo.fromPlatform();
  logger.i("app current version = ${info.version}");
  return info.version;
}

Future<Map<String, dynamic>?> fetchVersionInfo() async {
  try {
    final res = await http.get(
      Uri.parse('https://nb-factory.jp/api/version.json'),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
  } catch (e) {
    logger.w("version fetch failed: $e");
  }
  return null;
}

int compareVersion(String a, String b) {
  logger.i("compare version: current=$a latest=$b");

  final pa = a.split('.').map(int.parse).toList();
  final pb = b.split('.').map(int.parse).toList();

  for (int i = 0; i < 3; i++) {
    final ai = i < pa.length ? pa[i] : 0;
    final bi = i < pb.length ? pb[i] : 0;
    if (ai != bi) return ai.compareTo(bi);
  }
  return 0;
}

/// ===============================
/// dismissed version persistence
/// ===============================
Future<String?> _getDismissedVersion() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_dismissedUpdateVersionKey);
}

Future<void> _saveDismissedVersion(String version) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_dismissedUpdateVersionKey, version);
  logger.i("dismissed update version saved: $version");
}

/// ===============================
/// main check logic
/// ===============================
Future<void> checkLatestVersion(BuildContext context) async {
  final current = await getCurrentVersion();
  final info = await fetchVersionInfo();
  if (info == null) return;

  final latest = info['latest_version'] as String;
  final dismissed = await _getDismissedVersion();

  // すでに最新 or 同一以上
  if (compareVersion(current, latest) >= 0) {
    return;
  }

  // 「この latest_version で既にあとでを押している」
  if (dismissed == latest) {
    logger.i("update dialog suppressed for version $latest");
    return;
  }

  showUpdateAvailable(
    context,
    latestVersion: latest,
  );
}

/// ===============================
/// dialog
/// ===============================
void showUpdateAvailable(
  BuildContext context, {
  required String latestVersion,
}) {
  final l = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) {
      return AppDialog(
        title: l.updateAvailableTitle,
        message: l.updateAvailableMessage,
        showCloseButton: true,
        onClose: () => Navigator.pop(context),
        actionsAlignment: AppDialogActionsAlignment.end,
        actions: [
          TextButton(
            onPressed: () async {
              await _saveDismissedVersion(latestVersion);
              Navigator.pop(context);
            },
            child: Text(
              l.updateLater,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openStore();
            },
            child: Text(l.updateNow),
          ),
        ],
      );
    },
  );
}

/// ===============================
/// store redirect
/// ===============================
void _openStore() {
  // final url = Platform.isIOS
  //     ? 'https://apps.apple.com/jp/app/tube/id6756842201'
  //     : 'https://play.google.com/store/apps/details?id=your.application.id';

  const url = 'https://apps.apple.com/app/tube/id6756842201';

  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
