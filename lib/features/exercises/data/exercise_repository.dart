import 'package:dream_gym/core/database/app_database.dart';
import 'package:dream_gym/core/ids/uuid.dart';
import 'package:dream_gym/core/providers.dart';
import 'package:dream_gym/core/storage/photo_store.dart';
import 'package:dream_gym/features/exercises/domain/exercise.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => ExerciseRepository(
    database: ref.watch(appDatabaseProvider),
    photos: ref.watch(photoStoreProvider),
  ),
);

/// Reads and writes exercises.
///
/// Hands out [Exercise], not drift rows: the screens stay unaware of which
/// database is underneath, which is the point of the local-first-then-sync plan.
class ExerciseRepository {
  ExerciseRepository({required AppDatabase database, required PhotoStore photos})
    : _database = database,
      _photos = photos;

  final AppDatabase _database;
  final PhotoStore _photos;

  /// Every exercise, alphabetically, re-emitted on any change.
  Stream<List<Exercise>> watchAll() {
    final query = _database.select(_database.exercises)
      ..orderBy([
        (exercise) => OrderingTerm(expression: exercise.name.lower()),
      ]);

    return query.watch().map(
      (rows) => rows.map(_toExercise).toList(growable: false),
    );
  }

  Stream<Exercise?> watch(String id) {
    final query = _database.select(_database.exercises)
      ..where((exercise) => exercise.id.equals(id));

    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toExercise(row),
    );
  }

  /// Adds an exercise and returns it.
  Future<Exercise> create({required String name, String? photoFileName}) async {
    final exercise = Exercise(
      id: newUuid(),
      name: name.trim(),
      photoFileName: photoFileName,
      // Not rounded to whole seconds. A date-time column holds ISO-8601 text
      // (see `build.yaml`), which round-trips microseconds exactly, so the
      // exercise returned here equals the row that was written.
      createdAt: DateTime.now(),
    );

    await _database
        .into(_database.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: exercise.id,
            name: exercise.name,
            photoFileName: Value(exercise.photoFileName),
            createdAt: exercise.createdAt,
          ),
        );

    return exercise;
  }

  /// Renames an exercise and/or points it at a different photo.
  ///
  /// [photoFileName] is passed as a [Value] so that 'leave the photo alone'
  /// and 'the exercise now has no photo' stay distinguishable.
  Future<void> update(
    String id, {
    required String name,
    Value<String?> photoFileName = const Value.absent(),
  }) async {
    final statement = _database.update(_database.exercises)
      ..where((exercise) => exercise.id.equals(id));

    await statement.write(
      ExercisesCompanion(name: Value(name.trim()), photoFileName: photoFileName),
    );
  }

  /// Removes an exercise, everything logged against it, and its photo.
  ///
  /// The entries are deleted here rather than by a foreign key: sqlite_async
  /// opens a pool of connections and `PRAGMA foreign_keys` is set per
  /// connection, so the cascade cannot be relied on.
  Future<void> delete(String id) async {
    final row = await (_database.select(
      _database.exercises,
    )..where((exercise) => exercise.id.equals(id))).getSingleOrNull();

    if (row == null) return;

    await _database.transaction(() async {
      await (_database.delete(_database.trainingEntries)..where(
            (entry) => entry.exerciseId.equals(id),
          ))
          .go();
      await (_database.delete(
        _database.exercises,
      )..where((exercise) => exercise.id.equals(id))).go();
    });

    // After the rows are gone, so a failed file delete cannot leave an
    // exercise pointing at a photo that is no longer there.
    final photoFileName = row.photoFileName;
    if (photoFileName != null) await _photos.delete(photoFileName);
  }

  Exercise _toExercise(ExerciseRow row) => Exercise(
    id: row.id,
    name: row.name,
    photoFileName: row.photoFileName,
    createdAt: row.createdAt,
  );
}
