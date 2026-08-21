import 'package:dream_gym/core/database/app_database.dart';
import 'package:dream_gym/features/settings/domain/app_settings.dart';
import 'package:drift/drift.dart';

/// Reads and writes the reader's preferences.
///
/// Hands out [AppSettings] rather than a drift row, for the same reason
/// `ExerciseRepository` hands out exercises: the screens should not know which
/// database is underneath.
class SettingsRepository {
  SettingsRepository({required AppDatabase database}) : _database = database;

  /// The one row the table holds.
  static const _rowId = 0;

  final AppDatabase _database;

  /// The current settings, re-emitted on any change.
  ///
  /// An absent row is not an error: a fresh install has none, and the defaults
  /// are what it should read.
  Stream<AppSettings> watch() {
    final query = _database.select(_database.settingsEntries)
      ..where((row) => row.id.equals(_rowId));

    return query.watchSingleOrNull().map(
      (row) => row == null ? const AppSettings() : _toSettings(row),
    );
  }

  Future<AppSettings> read() async {
    final row = await (_database.select(
      _database.settingsEntries,
    )..where((row) => row.id.equals(_rowId))).getSingleOrNull();

    return row == null ? const AppSettings() : _toSettings(row);
  }

  /// Writes the whole object.
  ///
  /// Upsert rather than update-then-insert: the row may not exist yet, and two
  /// writes racing on a first run should not be able to create two of it.
  Future<void> save(AppSettings settings) {
    return _database
        .into(_database.settingsEntries)
        .insertOnConflictUpdate(
          SettingsEntriesCompanion.insert(
            id: const Value(_rowId),
            weightUnit: Value(settings.unit.name),
            themeChoice: Value(settings.theme.name),
            trainingReminder: Value(settings.trainingReminder),
            reminderMinutes: Value(settings.reminderMinutes),
            weeklySummary: Value(settings.weeklySummary),
          ),
        );
  }

  AppSettings _toSettings(SettingsRow row) => AppSettings(
    unit: WeightUnit.parse(row.weightUnit),
    theme: ThemeChoice.parse(row.themeChoice),
    trainingReminder: row.trainingReminder,
    reminderMinutes: row.reminderMinutes,
    weeklySummary: row.weeklySummary,
  );
}
