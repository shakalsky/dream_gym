import 'package:dream_gym/env/app_env.dart';
import 'package:dream_gym/env/flavor.dart';

/// A fully configured environment for tests.
///
/// Built directly rather than through `AppEnv.fromDefines`, which can only read
/// what the test binary was compiled with — a test needs to choose.
AppEnv testEnv({
  Flavor flavor = Flavor.development,
  String appName = '[DEV] Dream Gym',
  String apiBaseUrl = 'https://dev.api.dream-gym.app',
  String supabaseUrl = 'https://project.supabase.co',
  String supabasePublishableKey = 'sb_publishable_test',
  String powerSyncUrl = 'https://instance.powersync.journeyapps.com',
  String databaseName = 'dream_gym_test.db',
  bool verboseLogging = false,
}) {
  return AppEnv(
    flavor: flavor,
    appName: appName,
    apiBaseUrl: apiBaseUrl,
    supabaseUrl: supabaseUrl,
    supabasePublishableKey: supabasePublishableKey,
    powerSyncUrl: powerSyncUrl,
    databaseName: databaseName,
    verboseLogging: verboseLogging,
  );
}
