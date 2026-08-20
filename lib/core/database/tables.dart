import 'package:drift/drift.dart';

/// A movement the reader trains — 'Bench press', with an optional photo.
@DataClassName('ExerciseRow')
class Exercises extends Table {
  /// A UUID rather than an autoincrementing integer.
  ///
  /// Rows are created on a device, not by a server, so the id has to be
  /// generatable offline — and the same choice is what a later PowerSync sync
  /// expects.
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// File name inside the photo directory — not a full path.
  ///
  /// The documents directory is re-created on reinstall and can move between
  /// iOS updates, so an absolute path stored here would eventually point at
  /// nothing. See `PhotoStore`.
  TextColumn get photoFileName => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One thing the reader wrote down after a set of an exercise: how many sets,
/// at what weight, on which day.
@DataClassName('TrainingEntryRow')
@TableIndex(name: 'training_entries_by_exercise', columns: {#exerciseId})
class TrainingEntries extends Table {
  TextColumn get id => text()();

  /// The exercise this belongs to.
  ///
  /// The reference documents the relationship, but nothing is relied on to
  /// enforce it: `PRAGMA foreign_keys` is per-connection, and sqlite_async
  /// opens a pool of them. Deleting an exercise removes its entries
  /// explicitly — see `ExerciseRepository.delete`.
  TextColumn get exerciseId => text().references(Exercises, #id)();

  /// The training day, normalised to local midnight.
  ///
  /// Day granularity is what the reader thinks in ('Monday I did 4×60'), and
  /// it is what lets several entries collapse into one session.
  DateTimeColumn get performedOn => dateTime()();

  IntColumn get sets => integer()();

  RealColumn get weightKg => real()();

  /// When the row was written, as opposed to the day it describes. Keeps
  /// same-day entries in the order they were entered.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
