import 'package:dream_gym/env/app_env.dart';
import 'package:my_calm_ui_package/my_calm_ui_package.dart';

/// Placeholder home screen: reports which environment the running build was
/// compiled against.
///
/// Here so that a flavour can be verified on a device rather than trusted —
/// replace it with the first real feature.
class EnvironmentPage extends StatelessWidget {
  const EnvironmentPage({required this.env, super.key});

  final AppEnv env;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(env.appName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Row(label: 'Flavor', value: env.flavor.name),
            _Row(label: 'API base URL', value: env.apiBaseUrl),
            _Row(label: 'Supabase URL', value: env.supabaseUrl),
            _Row(
              label: 'Supabase key',
              value: _redact(env.supabasePublishableKey),
            ),
            _Row(label: 'PowerSync URL', value: env.powerSyncUrl),
            _Row(label: 'Local database', value: env.databaseName),
            _Row(label: 'Backend configured', value: '${env.hasBackend}'),
            _Row(label: 'Verbose logging', value: '${env.verboseLogging}'),
          ],
        ),
      ),
    );
  }

  /// Publishable or not, a key does not need to be legible over someone's
  /// shoulder — enough is shown to tell two projects apart.
  static String _redact(String key) {
    if (key.isEmpty) return '—';
    return key.length <= 12 ? key : '${key.substring(0, 12)}…';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelMedium),
          Text(
            value.isEmpty ? '—' : value,
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
