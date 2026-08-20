import 'package:dream_gym/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// An empty database that lives for one test.
///
/// Drift's own in-memory executor rather than the sqlite_async connection the
/// app opens: the tables and the queries are what is under test here, and those
/// are the same either way.
AppDatabase openTestDatabase() {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(database.close);

  return database;
}
