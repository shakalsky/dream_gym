import 'dart:io';

import 'package:dream_gym/app/app.dart';
import 'package:dream_gym/app/view/environment_page.dart';
import 'package:dream_gym/core/database/app_database.dart';
import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:dream_gym/env/app_env.dart';
import 'package:dream_gym/env/flavor.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/exercises/view/exercises_page.dart';
import 'package:dream_gym/features/settings/data/settings_repository.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';
import '../../helpers/test_env.dart';

void main() {
  late AppDatabase database;
  late PhotoStore photos;

  setUp(() {
    database = openTestDatabase();
    final photoDirectory = Directory.systemTemp.createTempSync(
      'dream_gym_photos',
    );
    addTearDown(() => photoDirectory.deleteSync(recursive: true));
    photos = PhotoStore(directory: photoDirectory);
  });

  App buildApp(AppEnv env) => App(
    env: env,
    exercises: ExerciseRepository(database: database, photos: photos),
    training: TrainingRepository(database: database),
    photos: photos,
    settings: SettingsRepository(database: database),
  );

  group('App', () {
    testWidgets('opens on the exercises page', (tester) async {
      await tester.pumpWidget(buildApp(testEnv()));
      await tester.pumpAndSettle();

      final tabs = tester.widget<IndexedStack>(find.byType(IndexedStack));

      expect(tabs.index, 0);
      expect(tabs.children.first, isA<ExercisesPage>());
    });

    testWidgets('banners a development build', (tester) async {
      await tester.pumpWidget(buildApp(testEnv()));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Banner && widget.message == 'DEV',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a development build can read its environment', (tester) async {
      await tester.pumpWidget(buildApp(testEnv()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Env'));
      await tester.pumpAndSettle();

      expect(find.byType(EnvironmentPage), findsOneWidget);
    });

    testWidgets('leaves a production build unbannered', (tester) async {
      await tester.pumpWidget(
        buildApp(testEnv(flavor: Flavor.production, appName: 'Dream Gym')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Banner && widget.message == 'DEV',
        ),
        findsNothing,
      );
      expect(
        find.byType(EnvironmentPage),
        findsNothing,
        reason: 'the environment is a development affordance',
      );
    });
  });
}
