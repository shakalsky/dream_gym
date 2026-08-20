import 'dart:io';

import 'package:dream_gym/core/database/app_database.dart';
import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late Directory photoDirectory;
  late ExerciseRepository repository;
  late TrainingRepository training;

  setUp(() {
    database = openTestDatabase();
    photoDirectory = Directory.systemTemp.createTempSync('dream_gym_photos');
    addTearDown(() => photoDirectory.deleteSync(recursive: true));

    repository = ExerciseRepository(
      database: database,
      photos: PhotoStore(directory: photoDirectory),
    );
    training = TrainingRepository(database: database);
  });

  group('ExerciseRepository', () {
    test('creates an exercise and reads it back', () async {
      final created = await repository.create(name: '  Bench press  ');

      expect(created.name, 'Bench press', reason: 'the name is trimmed');
      expect(created.photoFileName, isNull);

      await expectLater(
        repository.watchAll().first,
        completion(equals([created])),
      );
    });

    test('orders by name, case-insensitively', () async {
      await repository.create(name: 'squat');
      await repository.create(name: 'Bench press');
      await repository.create(name: 'Deadlift');

      final names = (await repository.watchAll().first)
          .map((exercise) => exercise.name)
          .toList();

      expect(names, ['Bench press', 'Deadlift', 'squat']);
    });

    test('renames without touching the photo', () async {
      final photo = File('${photoDirectory.path}/photo.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      final created = await repository.create(
        name: 'Bench',
        photoFileName: 'photo.jpg',
      );

      await repository.update(created.id, name: 'Bench press');

      final updated = await repository.watch(created.id).first;
      expect(updated?.name, 'Bench press');
      expect(updated?.photoFileName, 'photo.jpg');
      expect(photo.existsSync(), isTrue);
    });

    test('clears the photo when asked to', () async {
      final created = await repository.create(
        name: 'Bench',
        photoFileName: 'photo.jpg',
      );

      await repository.update(
        created.id,
        name: 'Bench',
        photoFileName: const Value(null),
      );

      expect((await repository.watch(created.id).first)?.photoFileName, isNull);
    });

    test('deleting takes the entries and the photo file with it', () async {
      final photo = File('${photoDirectory.path}/photo.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      final exercise = await repository.create(
        name: 'Bench',
        photoFileName: 'photo.jpg',
      );
      final other = await repository.create(name: 'Squat');

      await training.log(
        exerciseId: exercise.id,
        day: DateTime(2026, 8, 20),
        sets: 4,
        weightKg: 60,
      );
      await training.log(
        exerciseId: other.id,
        day: DateTime(2026, 8, 20),
        sets: 5,
        weightKg: 100,
      );

      await repository.delete(exercise.id);

      expect(await repository.watchAll().first, equals([other]));
      expect(
        await training.watchForExercise(exercise.id).first,
        isEmpty,
        reason: 'its history goes with it',
      );
      expect(
        (await training.watchAll().first).length,
        1,
        reason: "another exercise's history is untouched",
      );
      expect(photo.existsSync(), isFalse);
    });

    test('deleting something that is already gone is not an error', () async {
      await expectLater(repository.delete('missing'), completes);
    });

    test('watch reports null for an exercise that does not exist', () async {
      expect(await repository.watch('missing').first, isNull);
    });
  });
}
