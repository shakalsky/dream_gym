import 'package:dream_gym/env/flavor.dart';
import 'package:equatable/equatable.dart';

/// Build-time configuration for one environment.
///
/// Values come from `--dart-define-from-file`, which the launch
/// configurations and the commands in the README already pass:
///
/// ```sh
/// flutter run --flavor development \
///   --target lib/main_development.dart \
///   --dart-define-from-file=env/development.json
/// ```
///
/// Only publishable values belong in those files. The Supabase publishable key
/// is public and RLS-scoped, so shipping it inside the binary is expected; a
/// secret or service-role key never is.
///
/// A value object rather than a bag of statics, so a test can build an
/// environment without a define in sight — see `test/env/app_env_test.dart`.
final class AppEnv extends Equatable {
  const AppEnv({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.powerSyncUrl,
    required this.databaseName,
    required this.verboseLogging,
  });

  /// Reads the environment the binary was compiled with.
  ///
  /// [flavor] is the one thing not read from a define: it is passed in by the
  /// entrypoint, and checked against the `FLAVOR` the define file declares.
  /// That check is the whole point of carrying `FLAVOR` in the JSON — it is
  /// what makes `main_production.dart` built against `env/development.json`
  /// fail at startup instead of shipping a release pointed at the dev backend.
  factory AppEnv.fromDefines(Flavor flavor) {
    final declared = Flavor.tryParse(_flavor);

    // An absent define file leaves `_flavor` empty. Development tolerates that
    // and runs local-only; production must not, since every backend value is
    // missing along with it.
    if (declared == null && flavor.isProduction) {
      throw StateError(
        'No environment was compiled in. Build with '
        '--dart-define-from-file=env/production.json.',
      );
    }

    if (declared != null && declared != flavor) {
      throw StateError(
        'Flavor mismatch: lib/main_${flavor.name}.dart was built against '
        'env/${declared.name}.json. Pass '
        '--dart-define-from-file=env/${flavor.name}.json.',
      );
    }

    final env = AppEnv(
      flavor: flavor,
      appName: _appName.isEmpty ? _defaultAppName(flavor) : _appName,
      apiBaseUrl: _apiBaseUrl,
      supabaseUrl: _supabaseUrl,
      supabasePublishableKey: _supabasePublishableKey,
      powerSyncUrl: _powerSyncUrl,
      databaseName: _databaseName.isEmpty
          ? 'dream_gym_${flavor.name}.db'
          : _databaseName,
      // Development logs unless the define file says otherwise; production
      // stays quiet unless someone deliberately turns it on. Read as a string
      // rather than through `bool.fromEnvironment` so that "absent" and an
      // explicit "false" stay distinguishable.
      verboseLogging: switch (_verboseLogging) {
        'true' => true,
        'false' => false,
        _ => flavor.isDevelopment,
      },
    );

    // A half-filled production file is worse than an empty one: the build
    // starts, reports no backend, and looks like it is working. Development is
    // allowed to run that way on purpose; production is not.
    if (flavor.isProduction && !env.hasBackend) {
      throw StateError(
        'env/production.json is missing values for '
        '${env._missingBackendKeys.join(', ')}.',
      );
    }

    return env;
  }

  /// The environment this build runs against.
  final Flavor flavor;

  /// The name shown to the reader. Matches the native app label, which the
  /// Gradle flavour and the iOS build configuration set separately.
  final String appName;

  /// Base URL for the Dio client. Everything sync-related goes through
  /// PowerSync instead; this is for the requests that do not.
  final String apiBaseUrl;

  final String supabaseUrl;

  /// Public, RLS-scoped key. Safe in the binary — a secret key is not.
  final String supabasePublishableKey;

  final String powerSyncUrl;

  /// Filename of the local Drift/PowerSync database.
  ///
  /// Per flavour, so a dev build and a production build installed side by side
  /// never read each other's rows.
  final String databaseName;

  /// Whether to log bloc transitions and Dio traffic.
  final bool verboseLogging;

  /// Whether every backend value is present.
  ///
  /// When false the app is expected to run fully offline against the local
  /// database: nothing connects to PowerSync and sign-in is skipped. That is a
  /// normal state for a development run, and an error for a production one —
  /// which is why [AppEnv.fromDefines] refuses to build the latter without a
  /// define file.
  bool get hasBackend => _missingBackendKeys.isEmpty;

  /// Which define keys a backend is waiting on. Named rather than counted, so
  /// the failure above says what to go and fill in.
  List<String> get _missingBackendKeys => [
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
    if (powerSyncUrl.isEmpty) 'POWERSYNC_URL',
  ];

  @override
  List<Object?> get props => [
    flavor,
    appName,
    apiBaseUrl,
    supabaseUrl,
    supabasePublishableKey,
    powerSyncUrl,
    databaseName,
    verboseLogging,
  ];

  // The argument to String.fromEnvironment is the NAME of the define to read.
  // A value passed there is looked up as a key, finds nothing, and silently
  // yields '' — so these stay bare names, and the fallbacks live above.
  static const _flavor = String.fromEnvironment('FLAVOR');
  static const _appName = String.fromEnvironment('APP_NAME');
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _powerSyncUrl = String.fromEnvironment('POWERSYNC_URL');
  static const _databaseName = String.fromEnvironment('DATABASE_NAME');

  // Tri-state on purpose: '' means "let the flavour decide", which is not the
  // same as an explicit 'false'. `bool.fromEnvironment` cannot say which of the
  // two it got, so the raw string is read and matched in the factory above.
  static const _verboseLogging = String.fromEnvironment('VERBOSE_LOGGING');

  static String _defaultAppName(Flavor flavor) =>
      flavor.isProduction ? 'Dream Gym' : '[DEV] Dream Gym';
}
