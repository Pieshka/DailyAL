import 'package:dailyanimelist/api/credmal.dart';
import 'package:dailyanimelist/api/dalapi.dart';
import 'package:dal_commons/commons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-configurable API endpoint overrides (Settings -> API Endpoints).
/// Empty/absent values fall back to the compiled defaults from the bundled
/// environment file. Overrides persist across restarts.
class ApiEndpointSettings {
  ApiEndpointSettings._();

  static const String keyJikanBaseUrl = 'api_override_jikan_base_url';
  static const String keyDalApiUrl = 'api_override_dal_api_url';
  static const String keyDalConfigUrl = 'api_override_dal_config_url';

  /// Applies stored overrides at startup. Must run after dotenv.load so the
  /// defaults are already available.
  static Future<void> loadAndApply() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      CredMal.setJikanBaseUrlOverride(prefs.getString(keyJikanBaseUrl));
      CredMal.setApiURLOverride(prefs.getString(keyDalApiUrl));
      CredMal.setAppConfigUrlOverride(prefs.getString(keyDalConfigUrl));
    } catch (e) {
      logDal('Failed to load API endpoint overrides: $e');
    }
  }

  /// Validates and stores one override; empty string clears it.
  /// Returns null when valid, or a human-readable error otherwise.
  static Future<String?> saveOverride(String key, String value) async {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      final uri = Uri.tryParse(trimmed);
      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty) {
        return 'Invalid URL: use http:// or https://';
      }
    }
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, trimmed);
    }
    applyInMemory(key, trimmed.isEmpty ? null : trimmed);
    return null;
  }

  static void applyInMemory(String key, String? value) {
    switch (key) {
      case keyJikanBaseUrl:
        CredMal.setJikanBaseUrlOverride(value);
        break;
      case keyDalApiUrl:
        CredMal.setApiURLOverride(value);
        break;
      case keyDalConfigUrl:
        CredMal.setAppConfigUrlOverride(value);
        break;
    }
    // DAL endpoints may have changed; re-resolve servers and cached lists.
    // Only when the client already exists: constructing it starts network
    // work, which must not happen as a side effect of saving a setting.
    DalApi.initialized?.resetDalConfig();
  }

  /// Clears every override and restores the compiled defaults.
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [keyJikanBaseUrl, keyDalApiUrl, keyDalConfigUrl]) {
      await prefs.remove(key);
      applyInMemory(key, null);
    }
  }

  static Future<Map<String, String?>> stored() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      keyJikanBaseUrl: prefs.getString(keyJikanBaseUrl),
      keyDalApiUrl: prefs.getString(keyDalApiUrl),
      keyDalConfigUrl: prefs.getString(keyDalConfigUrl),
    };
  }
}
