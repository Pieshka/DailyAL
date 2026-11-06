import 'dart:io';
import 'package:dal_commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CredMal {
  static Map<String, Object> get environment {
    try {
      return dotenv.env;
    } catch (_) {
      // dotenv is not loaded yet (unit tests, very early startup). Falling
      // back to an empty map lets env-only features use their defaults
      // instead of crashing unrelated code paths.
      return const {};
    }
  }

  ///EndPoint
  static final String endPoint = "https://api.myanimelist.net/v2/";

  /// User EndPoint
  static final String userEndPoint = endPoint + "users/";

  /// Me EndPoint
  static final String myEndPoint = userEndPoint + "@me/";

  ///Html EndPoint
  static final String htmlEnd = "https://myanimelist.net/";

  ///Html EndPoint
  static final String dbChangesEnd = "https://myanimelist.net/dbchanges.php";

  ///Character Endpoint
  static final String charaEnd = "${htmlEnd}character.php";

  ///Client Id
  static String get clientId {
    return '${environment['MAL_CLIENT_ID']}';
  }

  ///Client Secret
  static String get clientSecret {
    return '${environment['MAL_CLIENT_SECRET']}';
  }

  /// Redirect Uri - platform-specific for OAuth callback
  /// Android/iOS: custom URL scheme
  /// Linux/Windows/macOS: localhost for flutter_web_auth_2
  static String get redirectUri {
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      return "http://localhost:8585/callback";
    }
    return "com.teen.dailyanimelist://login-callback";
  }

  /// Callback URL scheme for flutter_web_auth_2
  static String get callbackUrlScheme {
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      return "http://localhost:8585";
    }
    return "com.teen.dailyanimelist";
  }

  //oauthEndPoint
  static final String oauthEndPoint =
      "https://myanimelist.net/v1/oauth2/authorize";

  //oTokenEndPoint
  static final String otokenEndPoint =
      "https://myanimelist.net/v1/oauth2/token";

  //TokenEndPoint
  static final String tokenEndPoint =
      "https://api.myanimelist.net/v2/auth/token";

  static final String authority = "myanimelist.net";

  static final String unencodedPath = "/v1/oauth2/authorize";

  //CDN EndPoint
  static final String cdnEndPoint = "https://cdn.myanimelist.net/";

  static final String apiCdnEP = "https://api-cdn-dev1.al.myanimelist.net/";

  //UserImage EndPoint
  static final String userImageEndPoint = "${cdnEndPoint}images/userimages/";

  static final String apiUserAvatar = cdnEndPoint + "images/useravatars/";

  /// Jikan-compatible API base. api.jikan.moe has been unreliable/dead, so
  /// the default is the community replacement (jikan-edge). Order of
  /// precedence: in-app settings override -> JIKAN_BASE_URL env var ->
  /// built-in default. Always ends with a trailing slash.
  static const String defaultJikanBaseUrl = 'https://jikan.lucashdo.com/v1/';
  static String? _jikanBaseUrlOverride;

  /// Notified whenever the effective Jikan base changes (settings page).
  static final ValueNotifier<String> jikanBaseUrlNotifier =
      ValueNotifier(defaultJikanBaseUrl);

  static void setJikanBaseUrlOverride(String? url) {
    final trimmed = url?.trim() ?? '';
    _jikanBaseUrlOverride = trimmed.isEmpty ? null : trimmed;
    // Keep the bundled DAL handlers on the same base URL.
    Constants.jikanV4 = jikanV4;
    jikanBaseUrlNotifier.value = jikanV4;
  }

  static String? get jikanBaseUrlOverride => _jikanBaseUrlOverride;

  static String get jikanV4 {
    var base = _jikanBaseUrlOverride;
    if (base == null || base.isEmpty) {
      final fromEnv = environment['JIKAN_BASE_URL']?.toString().trim();
      if (fromEnv != null && fromEnv.isNotEmpty) base = fromEnv;
    }
    base = (base == null || base.isEmpty) ? defaultJikanBaseUrl : base;
    return base.endsWith('/') ? base : '$base/';
  }

  static const String dalWeb = 'https://dailyanimelist.web.app/';

  static const String webAssetsUrl =
      'https://raw.githubusercontent.com/JICA98/DailyAL/refs/heads/psycho/web_assets/';

  static String get appConfigUrl {
    return '${environment['APP_CONFIG_URL']}';
  }

  static BuildVariant get buildVariant {
    return BuildVariant.fromString(environment['BUILD_VARIANT']);
  }

  static String get errorReportingUrl {
    return '${environment['ERROR_REPORT_URL']}';
  }

  static String get defaultConfig {
    return '''
        {
          "bmacLink": false,
          "errorLogging": false,
          "maxLoad": 20,
          "preferredServers": [],
          "strategy": "load"
        }
''';
  }

  static String get supabaseUrl {
    return '${environment['SUPABASE_URL']}';
  }

  static String get supabaseKey {
    return '${environment['SUPABASE_KEY']}';
  }

  static String get apiURL {
    return '${environment['API_URL']}';
  }

  static String get apiSecret {
    return '${environment['API_SECRET']}';
  }
}
