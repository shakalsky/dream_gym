import 'dart:developer';

import 'package:dream_gym/env/app_env.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logs every provider change and error.
///
/// Installed only when [AppEnv.verboseLogging] is on, which is development by
/// default — a production build should not narrate its own state transitions.
final class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    log('onChange(${context.provider}, $previousValue → $newValue)');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    log('onError(${context.provider}, $error, $stackTrace)');
  }
}
