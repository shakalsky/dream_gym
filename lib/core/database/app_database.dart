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
@DriftDatabase(tables: [Exercises, TrainingEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(SqliteConnection connection)
    : super(SqliteAsyncDriftConnection(connection));

  /// For tests, which pass drift's in-memory executor. The parameter is named
  /// after the one in drift's generated superclass, which the analyzer expects
  /// it to match.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}
