import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:dream_gym/env/app_env.dart';
import 'package:flutter/widgets.dart';

/// Shared startup for every flavour.
///
/// The entrypoints differ only in the [AppEnv] they hand over; anything that
/// belongs to all of them belongs here.
Future<void> bootstrap({
  required AppEnv env,
  required FutureOr<Widget> Function(AppEnv env) builder,
}) async {
  // Opening the database and initializing Supabase both touch platform
  // channels, so the binding has to exist before [builder] runs.
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  // Errors that escape the framework's own zone — a failed future in a
  // repository, say — would otherwise only reach the platform console.
  PlatformDispatcher.instance.onError = (error, stack) {
    log('$error', stackTrace: stack);
    return true;
  };

  // Add cross-flavor configuration here. Provider logging is not: it is
  // installed on the `ProviderScope`, which `buildApp` creates.

  runApp(await builder(env));
}
