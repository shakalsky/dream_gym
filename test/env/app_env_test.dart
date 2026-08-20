import 'package:dream_gym/env/app_env.dart';
import 'package:dream_gym/env/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_env.dart';

void main() {
  group('AppEnv', () {
    test('is equal by value', () {
      expect(testEnv(), equals(testEnv()));
      expect(
        testEnv(flavor: Flavor.production),
        isNot(equals(testEnv())),
      );
    });

    test('reports a backend when every value is present', () {
      expect(testEnv().hasBackend, isTrue);
    });

    test('reports no backend when any value is missing', () {
      expect(testEnv(supabaseUrl: '').hasBackend, isFalse);
      expect(testEnv(supabasePublishableKey: '').hasBackend, isFalse);
      expect(testEnv(powerSyncUrl: '').hasBackend, isFalse);
    });
  });

  group('AppEnv.fromDefines', () {
    // The tests run without --dart-define-from-file, so FLAVOR is absent —
    // which is exactly the case each rule below is about.
    test('builds a development environment with nothing compiled in', () {
      final env = AppEnv.fromDefines(Flavor.development);

      expect(env.flavor, Flavor.development);
      expect(env.appName, '[DEV] Dream Gym');
      expect(env.databaseName, 'dream_gym_development.db');
      expect(env.verboseLogging, isTrue);
      expect(env.hasBackend, isFalse);
    });

    test('refuses to build a production environment', () {
      expect(
        () => AppEnv.fromDefines(Flavor.production),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Flavor', () {
    test('parses its own names and nothing else', () {
      expect(Flavor.tryParse('development'), Flavor.development);
      expect(Flavor.tryParse('production'), Flavor.production);
      expect(Flavor.tryParse('staging'), isNull);
      expect(Flavor.tryParse(''), isNull);
    });
  });
}
