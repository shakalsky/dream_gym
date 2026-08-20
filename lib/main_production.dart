import 'package:dream_gym/app/app_builder.dart';
import 'package:dream_gym/bootstrap.dart';
import 'package:dream_gym/env/app_env.dart';
import 'package:dream_gym/env/flavor.dart';

/// Production entrypoint.
///
/// ```sh
/// flutter build appbundle --flavor production \
///   --target lib/main_production.dart \
///   --dart-define-from-file=env/production.json
/// ```
///
/// Unlike development, this refuses to start without a define file: a release
/// with no backend compiled in would silently be a local-only app.
Future<void> main() async {
  final env = AppEnv.fromDefines(Flavor.production);

  await bootstrap(env: env, builder: buildApp);
}
