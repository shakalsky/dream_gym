import 'package:dream_gym/core/database/app_database.dart';
import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/core/ids/uuid.dart';
import 'package:dream_gym/core/providers.dart';
import 'package:dream_gym/features/training/domain/training_entry.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => TrainingRepository(database: ref.watch(appDatabaseProvider)),
);

/// Reads and writes what was actually done in the gym.
class TrainingRepository {
  TrainingRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  /// Every entry, oldest day first.
  ///
  /// The whole log at once is a deliberate choice: a personal training diary is
  /// thousands of rows at most, and having all of it in memory is what lets the
  /// statistics be computed as plain Dart instead of a pile of SQL.
  Stream<List<TrainingEntry>> watchAll() => _selectOrdered().watch().map(_map);

  /// Every entry for one exercise, oldest day first.
  Stream<List<TrainingEntry>> watchForExercise(String exerciseId) {
    final query = _selectOrdered()
      ..where((entry) => entry.exerciseId.equals(exerciseId));

    return query.watch().map(_map);
  }

  /// Writes down one line of a training.
  ///
  /// [day] is rounded to local midnight so that entries made in the morning
  /// and the evening belong to the same session.
  Future<void> log({
    required String exerciseId,
    required DateTime day,
    required int sets,
    required double weightKg,
  }) async {
    await _database
        .into(_database.trainingEntries)
        .insert(
          TrainingEntriesCompanion.insert(
            id: newUuid(),
            exerciseId: exerciseId,
            performedOn: dayOf(day),
            sets: sets,
            weightKg: weightKg,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> deleteEntry(String id) async {
    await (_database.delete(
      _database.trainingEntries,
    )..where((entry) => entry.id.equals(id))).go();
  }

  SimpleSelectStatement<$TrainingEntriesTable, TrainingEntryRow>
  _selectOrdered() {
    return _database.select(_database.trainingEntries)
      ..orderBy([
        (entry) => OrderingTerm(expression: entry.performedOn),
        // Within a day, the order they were written in — a warm-up logged
        // first should read first.
        (entry) => OrderingTerm(expression: entry.createdAt),
      ]);
  }

  List<TrainingEntry> _map(List<TrainingEntryRow> rows) => rows
      .map(
        (row) => TrainingEntry(
          id: row.id,
          exerciseId: row.exerciseId,
          performedOn: row.performedOn,
          sets: row.sets,
          weightKg: row.weightKg,
          createdAt: row.createdAt,
        ),
      )
      .toList(growable: false);
}
