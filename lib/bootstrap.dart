import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:dream_gym/env/app_env.dart';
import 'package:flutter/widgets.dart';

/// Logs every bloc change and error.
///
/// Installed only when [AppEnv.verboseLogging] is on, which is development by
/// default — a production build should not narrate its own state transitions.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

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

  if (env.verboseLogging) {
    Bloc.observer = const AppBlocObserver();
  }

  // Add cross-flavor configuration here.

  runApp(await builder(env));
}
