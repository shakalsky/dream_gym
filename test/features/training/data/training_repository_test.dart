import 'dart:io';

import 'package:dream_gym/core/database/app_database.dart';
import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late TrainingRepository training;
  late String exerciseId;

  setUp(() async {
    database = openTestDatabase();
    training = TrainingRepository(database: database);
    final exercises = ExerciseRepository(
      database: database,
      photos: PhotoStore(directory: Directory.systemTemp),
    );
    exerciseId = (await exercises.create(name: 'Bench')).id;
  });

  group('TrainingRepository.log', () {
    test('identical sets are a single line', () async {
      await training.log(
        exerciseId: exerciseId,
        day: DateTime(2026, 10, 25, 18),
        sets: List.filled(3, (reps: 10, weightKg: 60)),
      );

      final entries = await training.watchForExercise(exerciseId).first;

      expect(entries, hasLength(1));
      expect(entries.single.sets, 3);
      expect(entries.single.reps, 10);
      expect(entries.single.weightKg, 60);
      expect(entries.single.performedOn, DateTime(2026, 10, 25));
      expect(entries.single.volumeKg, 1800);
    });

    test(
      'a change of reps or weight starts a new line, in set order',
      () async {
        await training.log(
          exerciseId: exerciseId,
          day: DateTime(2026, 10, 25),
          sets: [
            (reps: 12, weightKg: 60),
            (reps: 10, weightKg: 70),
            (reps: 10, weightKg: 70),
            (reps: 8, weightKg: 70),
            (reps: 6, weightKg: 80),
          ],
        );

        final entries = await training.watchForExercise(exerciseId).first;

        expect(
          [
            for (final entry in entries)
              (entry.sets, entry.reps, entry.weightKg),
          ],
          [(1, 12, 60.0), (2, 10, 70.0), (1, 8, 70.0), (1, 6, 80.0)],
        );

        final session = ExerciseProgress.fromEntries(entries).latest!;
        expect(session.sets, 5);
        expect(session.reps, isNull, reason: 'the reps differ');
        expect(session.heaviestWeightKg, 80);
        expect(session.setsDone, [
          (reps: 12, weightKg: 60.0),
          (reps: 10, weightKg: 70.0),
          (reps: 10, weightKg: 70.0),
          (reps: 8, weightKg: 70.0),
          (reps: 6, weightKg: 80.0),
        ]);
        expect(session.volumeKg, 12 * 60 + 10 * 70 * 2 + 8 * 70 + 6 * 80);
      },
    );
  });
}
