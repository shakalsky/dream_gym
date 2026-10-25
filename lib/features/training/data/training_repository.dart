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

  /// Writes down a run of [sets], in the order they were done.
  ///
  /// Neighbouring sets with the same reps and weight become one line —
  /// '3 × 10 @ 60 kg', not three — and a change of either starts a new one.
  /// All lines are written together or not at all.
  ///
  /// [day] is rounded to local midnight so that entries made in the morning
  /// and the evening belong to the same session.
  Future<void> log({
    required String exerciseId,
    required DateTime day,
    required List<SetResult> sets,
  }) async {
    final performedOn = dayOf(day);
    final now = DateTime.now();
    final lines = <({int sets, int reps, double weightKg})>[];

    for (final set in sets) {
      final last = lines.lastOrNull;
      if (last != null &&
          last.reps == set.reps &&
          last.weightKg == set.weightKg) {
        lines.last = (
          sets: last.sets + 1,
          reps: set.reps,
          weightKg: set.weightKg,
        );
      } else {
        lines.add((sets: 1, reps: set.reps, weightKg: set.weightKg));
      }
    }

    await _database.batch((batch) {
      batch.insertAll(_database.trainingEntries, [
        for (final (index, line) in lines.indexed)
          TrainingEntriesCompanion.insert(
            id: newUuid(),
            exerciseId: exerciseId,
            performedOn: performedOn,
            sets: line.sets,
            reps: Value(line.reps),
            weightKg: line.weightKg,
            // Apart by a microsecond each, so the lines keep the order of the
            // sets when read back.
            createdAt: now.add(Duration(microseconds: index)),
          ),
      ]);
    });
  }

  Future<void> deleteEntry(String id) async {
    await (_database.delete(
      _database.trainingEntries,
    )..where((entry) => entry.id.equals(id))).go();
  }

  SimpleSelectStatement<$TrainingEntriesTable, TrainingEntryRow>
  _selectOrdered() {
    return _database.select(_database.trainingEntries)..orderBy([
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
          reps: row.reps,
          weightKg: row.weightKg,
          createdAt: row.createdAt,
        ),
      )
      .toList(growable: false);
}
