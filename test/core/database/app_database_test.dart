import 'package:dream_gym/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The version 2 schema, before reps, with one exercise and one entry.
const _v2Schema = '''
CREATE TABLE exercises (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
  photo_file_name TEXT NULL, created_at INTEGER NOT NULL);
CREATE TABLE training_entries (id TEXT NOT NULL PRIMARY KEY,
  exercise_id TEXT NOT NULL, performed_on INTEGER NOT NULL,
  sets INTEGER NOT NULL, weight_kg REAL NOT NULL, created_at INTEGER NOT NULL);
CREATE TABLE settings_entries (id INTEGER NOT NULL PRIMARY KEY);
INSERT INTO exercises VALUES ('e1', 'Squat', NULL, '2026-10-02T20:00:00.000 +03:00');
INSERT INTO training_entries VALUES ('t1', 'e1', '2026-10-02T00:00:00.000 +03:00', 3,
  60.0, '2026-10-02T20:00:00.000 +03:00');
PRAGMA user_version = 2;
''';

/// A version 2 database, plus [extraSql] run on it before the app opens it.
AppDatabase _openV2({String extraSql = ''}) {
  final database = AppDatabase.forTesting(
    NativeDatabase.memory(
      setup: (raw) => raw
        ..execute(_v2Schema)
        ..execute(extraSql),
    ),
  );
  addTearDown(database.close);
  return database;
}

Future<int> _userVersion(AppDatabase database) async {
  final row = await database.customSelect('PRAGMA user_version').getSingle();
  return row.read<int>('user_version');
}

void main() {
  group('migration from 2', () {
    test('adds reps and keeps the rows', () async {
      final database = _openV2();

      final entries = await database.select(database.trainingEntries).get();

      expect(entries.single.weightKg, 60);
      expect(entries.single.reps, isNull);
      expect(await _userVersion(database), 4);
    });

    test('recovers a database cut off before the version was saved', () async {
      // The column is already there, but the version still says 2.
      final database = _openV2(
        extraSql: 'ALTER TABLE training_entries ADD COLUMN reps INTEGER NULL;',
      );

      final exercises = await database.select(database.exercises).get();

      expect(exercises.single.name, 'Squat');
      expect(await _userVersion(database), 4);
    });

    test('adds the icon, null for existing exercises', () async {
      final database = _openV2();

      final exercises = await database.select(database.exercises).get();

      expect(exercises.single.iconName, isNull);
    });

    test('recovers when the icon column is already there', () async {
      final database = _openV2(
        extraSql: '''
ALTER TABLE training_entries ADD COLUMN reps INTEGER NULL;
ALTER TABLE exercises ADD COLUMN icon_name TEXT NULL;
PRAGMA user_version = 3;
''',
      );

      final exercises = await database.select(database.exercises).get();

      expect(exercises.single.name, 'Squat');
      expect(await _userVersion(database), 4);
    });
  });
}
