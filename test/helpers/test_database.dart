import 'package:dream_gym/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// An empty database that lives for one test.
///
/// Drift's own in-memory executor rather than the sqlite_async connection the
/// app opens: the tables and the queries are what is under test here, and those
/// are the same either way.
///
/// `closeStreamsSynchronously` is what makes this usable from a widget test.
/// Normally drift keeps a query stream's cache for one turn of the event loop
/// after its last listener leaves, so that a `StreamBuilder` reconnecting on a
/// rebuild does not re-run the query — and it uses a `Timer` to do it. In a
/// `testWidgets` body that timer is a fake one: it is still pending when the
/// framework tears the tree down, which fails the test with 'Pending timers',
/// and the `database.close()` below then waits forever on a timer whose clock
/// is already gone. Dropping the cache immediately costs a re-query that no
/// test here is measuring.
AppDatabase openTestDatabase() {
  final database = AppDatabase.forTesting(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(database.close);

  return database;
}
