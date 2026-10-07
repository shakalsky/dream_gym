import 'package:dream_gym/core/database/app_database.dart';
import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The local database.
///
/// Opening it is asynchronous and has to finish before the first frame, so
/// there is nothing sensible to build here: `buildApp` opens it and overrides
/// this in the root `ProviderScope`, and a test overrides it with an in-memory
/// one. Every repository is built on top of it.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'appDatabaseProvider has to be overridden in the root ProviderScope.',
  ),
);

/// Where exercise photos live. Overridden alongside [appDatabaseProvider], for
/// the same reason.
final photoStoreProvider = Provider<PhotoStore>(
  (ref) => throw UnimplementedError(
    'photoStoreProvider has to be overridden in the root ProviderScope.',
  ),
);

/// What time it is.
///
/// A provider rather than `DateTime.now` called inline, so a test can pin
/// 'today' — the weekly summary and the log form's default day both hang on it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
