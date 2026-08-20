import 'package:dream_gym/app/app_builder.dart';
import 'package:dream_gym/bootstrap.dart';
import 'package:dream_gym/env/app_env.dart';
import 'package:dream_gym/env/flavor.dart';

/// Development entrypoint.
///
/// Run with the matching flavour and define file — the launch configurations in
/// `.vscode/launch.json` already do:
///
/// ```sh
/// flutter run --flavor development \
///   --target lib/main_development.dart \
///   --dart-define-from-file=env/development.json
/// ```
Future<void> main() async {
  final env = AppEnv.fromDefines(Flavor.development);

  await bootstrap(env: env, builder: buildApp);
}
