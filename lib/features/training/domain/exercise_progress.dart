import 'dart:math' as math;

import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/features/training/domain/training_entry.dart';
import 'package:equatable/equatable.dart';

/// Everything one exercise's entries add up to.
///
/// Pure: it takes rows and returns numbers, with no database and no widgets in
/// sight, so the arithmetic the statistics screen shows can be tested directly.
final class ExerciseProgress extends Equatable {
  const ExerciseProgress._(this.sessions);

  /// Groups entries into one session per training day, oldest first.
  factory ExerciseProgress.fromEntries(Iterable<TrainingEntry> entries) {
    final byDay = <DateTime, List<TrainingEntry>>{};

    for (final entry in entries) {
      // Normalised again here rather than trusted: an entry could have been
      // written before the day-rounding existed, or by a future sync.
      byDay.putIfAbsent(dayOf(entry.performedOn), () => []).add(entry);
    }

    final days = byDay.keys.toList()..sort();

    return ExerciseProgress._([
      for (final day in days)
        TrainingSession(
          day: day,
          entries: List.unmodifiable(
            byDay[day]!..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
          ),
        ),
    ]);
  }

  /// An exercise that has never been trained.
  static const empty = ExerciseProgress._([]);

  /// One entry per training day, oldest first.
  final List<TrainingSession> sessions;

  bool get isEmpty => sessions.isEmpty;

  bool get isNotEmpty => sessions.isNotEmpty;

  int get sessionCount => sessions.length;

  /// The most recent training, or null if there has not been one.
  TrainingSession? get latest => sessions.isEmpty ? null : sessions.last;

  DateTime? get lastTrainedOn => latest?.day;

  int get totalSets =>
      sessions.fold(0, (total, session) => total + session.sets);

  double get totalVolumeKg =>
      sessions.fold(0, (total, session) => total + session.volumeKg);

  /// The heaviest weight ever logged, and the day it happened.
  TrainingSession? get personalBest {
    if (sessions.isEmpty) return null;

    return sessions.reduce(
      (best, session) =>
          session.heaviestWeightKg > best.heaviestWeightKg ? session : best,
    );
  }

  double? get personalBestKg => personalBest?.heaviestWeightKg;

  /// The hardest single training, by total work done.
  double? get bestSessionVolumeKg => sessions.isEmpty
      ? null
      : sessions.map((session) => session.volumeKg).reduce(math.max);

  /// How much the top weight has moved since the first recorded session.
  ///
  /// Null until there are two sessions to compare — a single training is a
  /// starting point, not progress.
  double? get weightGainKg {
    if (sessions.length < 2) return null;
    return sessions.last.heaviestWeightKg - sessions.first.heaviestWeightKg;
  }

  /// The chart series for [metric], oldest first.
  List<ProgressPoint> series(ProgressMetric metric) => [
    for (final session in sessions)
      ProgressPoint(day: session.day, value: metric.of(session)),
  ];

  @override
  List<Object?> get props => [sessions];
}

/// Everything logged for one exercise on one day.
///
/// [entries] is never empty — a day with nothing written down is not a session,
/// and the getters below have nothing to reduce over.
final class TrainingSession extends Equatable {
  const TrainingSession({required this.day, required this.entries});

  final DateTime day;
  final List<TrainingEntry> entries;

  int get sets => entries.fold(0, (total, entry) => total + entry.sets);

  /// The top weight of the day. Warm-ups are part of the volume but they are
  /// not what the reader is trying to beat.
  double get heaviestWeightKg =>
      entries.map((entry) => entry.weightKg).reduce(math.max);

  double get volumeKg =>
      entries.fold(0, (total, entry) => total + entry.volumeKg);

  @override
  List<Object?> get props => [day, entries];
}

/// Which number the statistics screen is plotting.
enum ProgressMetric {
  /// The heaviest set of each day.
  weight('Weight', 'kg'),

  /// Sets times weight, summed over the day.
  volume('Volume', 'kg'),

  /// How many sets were done.
  sets('Sets', '');

  const ProgressMetric(this.label, this.unit);

  final String label;
  final String unit;

  double of(TrainingSession session) => switch (this) {
    ProgressMetric.weight => session.heaviestWeightKg,
    ProgressMetric.volume => session.volumeKg,
    ProgressMetric.sets => session.sets.toDouble(),
  };

  /// How a value of this metric reads on an axis or a tooltip.
  String format(double value) => switch (this) {
    ProgressMetric.weight => formatWeight(value),
    ProgressMetric.volume => formatWeight(value),
    ProgressMetric.sets => value.round().toString(),
  };
}

/// One point of a progress series.
final class ProgressPoint extends Equatable {
  const ProgressPoint({required this.day, required this.value});

  final DateTime day;
  final double value;

  @override
  List<Object?> get props => [day, value];
}
