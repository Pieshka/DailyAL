import 'package:dailyanimelist/api/api_endpoint_settings.dart';
import 'package:dailyanimelist/api/credmal.dart';
import 'package:dailyanimelist/constant.dart';
import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/pages/settings/customsettings.dart';
import 'package:flutter/material.dart';

/// Lets the user point the app at alternative API servers (for example a
/// self-hosted Jikan mirror or DAL instance). Empty fields fall back to the
/// compiled defaults.
class ApiEndpointsSettingsPage extends StatefulWidget {
  const ApiEndpointsSettingsPage({super.key});

  @override
  State<ApiEndpointsSettingsPage> createState() =>
      _ApiEndpointsSettingsPageState();
}

class _ApiEndpointsSettingsPageState extends State<ApiEndpointsSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _jikanController = TextEditingController();
  final _dalApiController = TextEditingController();
  final _dalConfigController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stored = await ApiEndpointSettings.stored();
    if (!mounted) return;
    setState(() {
      _jikanController.text =
          stored[ApiEndpointSettings.keyJikanBaseUrl] ?? '';
      _dalApiController.text =
          stored[ApiEndpointSettings.keyDalApiUrl] ?? '';
      _dalConfigController.text =
          stored[ApiEndpointSettings.keyDalConfigUrl] ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final entries = {
      ApiEndpointSettings.keyJikanBaseUrl: _jikanController.text,
      ApiEndpointSettings.keyDalApiUrl: _dalApiController.text,
      ApiEndpointSettings.keyDalConfigUrl: _dalConfigController.text,
    };
    String? error;
    for (final entry in entries.entries) {
      error = await ApiEndpointSettings.saveOverride(entry.key, entry.value);
      if (error != null) break;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    showToast(error == null
        ? S.current.API_Endpoints_Saved
        : error);
  }

  Future<void> _resetAll() async {
    await ApiEndpointSettings.resetAll();
    if (!mounted) return;
    setState(() {
      _jikanController.text = '';
      _dalApiController.text = '';
      _dalConfigController.text = '';
    });
    showToast(S.current.API_Endpoints_Saved);
  }

  String? _validateUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return S.current.API_Endpoints_Invalid_URL;
    }
    return null;
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String helper,
    required String effective,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        autocorrect: false,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: label,
          helperText: '$helper\n${S.current.API_Endpoints_Current}: $effective',
          border: const OutlineInputBorder(),
        ),
        validator: _validateUrl,
      ),
    );
  }

  @override
  void dispose() {
    _jikanController.dispose();
    _dalApiController.dispose();
    _dalConfigController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingSliverScreen(
      titleString: S.current.API_Endpoints,
      child: SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(S.current.API_Endpoints_desc),
                      SB.h20,
                      _field(
                        controller: _jikanController,
                        label: S.current.Jikan_Base_URL,
                        helper: S.current.Jikan_Base_URL_desc,
                        effective: CredMal.defaultJikanBaseUrl,
                      ),
                      _field(
                        controller: _dalApiController,
                        label: S.current.DAL_API_URL,
                        helper: S.current.DAL_API_URL_desc,
                        effective: CredMal.defaultApiURL,
                      ),
                      _field(
                        controller: _dalConfigController,
                        label: S.current.DAL_Config_URL,
                        helper: S.current.DAL_Config_URL_desc,
                        effective: CredMal.defaultAppConfigUrl,
                      ),
                      SB.h20,
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save),
                        label: Text(S.current.Save),
                      ),
                      SB.h10,
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _resetAll,
                        icon: const Icon(Icons.restore),
                        label: Text(S.current.Reset_To_Defaults),
                      ),
                      SB.h80,
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
