import 'dart:convert';
import 'dart:io';

import 'package:dailyanimelist/generated/l10n.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

/// Every localization key used by the app must exist in every locale file;
/// a missing key makes flutter_intl fall back silently or break generation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final arbDir = Directory('lib/l10n');

  Map<String, Map<String, String>> loadArbs() {
    final arbs = <String, Map<String, String>>{};
    for (final file in arbDir.existsSync()
        ? arbDir.listSync()
        : <FileSystemEntity>[]) {
      if (file is! File || !file.path.endsWith('.arb')) continue;
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      arbs[file.uri.pathSegments.last] = Map.fromEntries(decoded.entries
          .where((e) => !e.key.startsWith('@'))
          .map((e) => MapEntry(e.key, e.value.toString())));
    }
    return arbs;
  }

  test('all locale arb files exist', () {
    expect(arbDir.existsSync(), isTrue,
        reason: 'run tests from the project root');
    expect(loadArbs().length, greaterThanOrEqualTo(11));
  });

  test('every English key exists in every locale with a non-empty value', () {
    final arbs = loadArbs();
    final english = arbs.entries.firstWhere((e) => e.key == 'intl_en.arb');
    for (final locale in arbs.entries) {
      if (locale.key == 'intl_en.arb') continue;
      final missing = english.value.keys
          .where((k) => !locale.value.containsKey(k))
          .toList();
      expect(missing, isEmpty,
          reason: '${locale.key} is missing ${missing.length} keys: '
              '${missing.take(10).join(', ')}');
      final empty = locale.value.entries
          .where((e) => e.value.trim().isEmpty)
          .map((e) => e.key)
          .toList();
      expect(empty, isEmpty, reason: '${locale.key} has empty values');
    }
  });

  test('Ameo and profile keys are generated and resolve in English', () async {
    final ss = await S.load(const Locale('en', 'US'));
    expect(ss.Ameo_Recommendations, 'Ameo Recommendations');
    expect(ss.Ameo_Settings, isNotEmpty);
    expect(ss.Ameo_Username_Label, isNotEmpty);
    expect(ss.Ameo_Model_Label, isNotEmpty);
    expect(ss.Ameo_Predicted_Score, isNotEmpty);
    expect(ss.Ameo_Why_Recommended, isNotEmpty);
    expect(ss.Profile_Load_Failed, isNotEmpty);
    expect(ss.Retry, isNotEmpty);
    expect(ss.API_Endpoints, 'API Endpoints');
    expect(ss.API_Endpoints_desc, isNotEmpty);
    expect(ss.API_Endpoints_Saved, isNotEmpty);
    expect(ss.API_Endpoints_Invalid_URL, isNotEmpty);
    expect(ss.API_Endpoints_Current, isNotEmpty);
    expect(ss.Jikan_Base_URL, isNotEmpty);
    expect(ss.Jikan_Base_URL_desc, isNotEmpty);
    expect(ss.DAL_API_URL, isNotEmpty);
    expect(ss.DAL_API_URL_desc, isNotEmpty);
    expect(ss.DAL_Config_URL, isNotEmpty);
    expect(ss.DAL_Config_URL_desc, isNotEmpty);
    expect(ss.Reset_To_Defaults, isNotEmpty);
    expect(ss.AI_Review_Summary, isNotEmpty);
    expect(ss.AI_Review_Summary_Desc, isNotEmpty);
    // The diagnostic-log switch used to be a hardcoded Indonesian string.
    expect(ss.Log_Diagnostics, 'Log Diagnostics');
    expect(ss.Log_Diagnostics_Desc, isNotEmpty);
    expect(ss.Reset_Notifications, isNotEmpty);
    expect(ss.Reset_Notifications_Desc, isNotEmpty);
    expect(ss.Queued_Notifications, isNotEmpty);
    expect(ss.Queued_Notifications_Desc, isNotEmpty);
    expect(ss.No_Queued_Notifications, isNotEmpty);
    expect(ss.Notifications_Reset_Done, isNotEmpty);
    expect(ss.Backup_Include_History, isNotEmpty);
    expect(ss.Backup_Include_History_Desc, isNotEmpty);
  });
}
