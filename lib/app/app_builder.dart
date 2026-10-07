import 'package:dream_gym/app/app_provider_observer.dart';
import 'package:dream_gym/app/view/app.dart';
import 'package:dream_gym/core/database/open_database.dart';
import 'package:dream_gym/core/providers.dart';
import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:dream_gym/env/app_env.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens local storage and builds the app around it.
///
/// The entrypoints hand this to `bootstrap`, so both flavours wire themselves
/// up the same way and differ only in the [AppEnv] they pass.
///
/// The one [ProviderScope] lives here rather than in `bootstrap`: it is where
/// the opened storage gets handed to the providers, and a second scope nested
/// inside it would need every overridden provider declared as scoped.
Future<Widget> buildApp(AppEnv env) async {
  final database = await openDatabase(env.databaseName);
  final photos = await PhotoStore.open();

  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      photoStoreProvider.overrideWithValue(photos),
    ],
    observers: [if (env.verboseLogging) const AppProviderObserver()],
    child: App(env: env),
  );
}
