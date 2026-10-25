import 'package:dream_gym/core/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:sqlite_async/sqlite_async.dart';

part 'app_database.g.dart';

/// The local database.
///
/// Drift runs on top of a sqlite_async connection rather than on drift's own
/// native executor. Functionally the two are equivalent today; the difference
/// is what comes next — a PowerSync database is a [SqliteConnection] too, so
/// turning this local-only app into a syncing one is a change to how the
/// connection is opened, not a rewrite of every query.
@DriftDatabase(tables: [Exercises, TrainingEntries, SettingsEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(SqliteConnection connection)
    : super(SqliteAsyncDriftConnection(connection));

  /// For tests, which pass drift's in-memory executor. The parameter is named
  /// after the one in drift's generated superclass, which the analyzer expects
  /// it to match.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // 2 adds the settings row. Nothing is backfilled: every column has a
      // default and the repository treats 'no row' as 'the defaults'.
      if (from < 2) await m.createTable(settingsEntries);
      // 3 adds reps. Older entries stay null — the count was never recorded.
      //
      // Only if missing: drift saves the new version after the upgrade, so
      // an app stopped in between keeps version 2 with the column already
      // added — and adding it again fails every launch after.
      if (from < 3 &&
          !await _hasColumn(trainingEntries, trainingEntries.reps)) {
        await m.addColumn(trainingEntries, trainingEntries.reps);
      }
      // 4 adds the exercise icon. Older exercises stay null and read as the
      // default icon. Guarded for the same reason as reps.
      if (from < 4 && !await _hasColumn(exercises, exercises.iconName)) {
        await m.addColumn(exercises, exercises.iconName);
      }
    },
  );

  Future<bool> _hasColumn(
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    final columns = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    return columns.any((row) => row.read<String>('name') == column.name);
  }
}
