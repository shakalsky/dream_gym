import 'package:dream_gym/app/view/app.dart';
import 'package:dream_gym/core/database/open_database.dart';
import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:dream_gym/env/app_env.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:flutter/widgets.dart';

/// Opens local storage and builds the app around it.
///
/// The entrypoints hand this to `bootstrap`, so both flavours wire themselves
/// up the same way and differ only in the [AppEnv] they pass.
Future<Widget> buildApp(AppEnv env) async {
  final database = await openDatabase(env.databaseName);
  final photos = await PhotoStore.open();

  return App(
    env: env,
    exercises: ExerciseRepository(database: database, photos: photos),
    training: TrainingRepository(database: database),
    photos: photos,
  );
}
