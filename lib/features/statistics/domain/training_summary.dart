import 'package:dream_gym/core/format/training_format.dart';
import 'package:dream_gym/features/training/domain/exercise_log.dart';
import 'package:equatable/equatable.dart';

/// The whole log reduced to 'how is this week going'.
///
/// Sits above the per-exercise charts because it answers the question a reader
/// has before they have picked an exercise: did I train, and was it more or
/// less than last week.
final class TrainingSummary extends Equatable {
  const TrainingSummary({
    required this.trainingDays,
    required this.sets,
    required this.volumeKg,
    required this.previousVolumeKg,
    required this.busiestExercise,
  });

  /// Reduces [logs] to this week and the one before it.
  ///
  /// [today] is passed in rather than read from the clock so the numbers are
  /// testable, and so a screen left open overnight can be rebuilt against the
  /// new week.
  factory TrainingSummary.fromLogs(
    Iterable<ExerciseLog> logs, {
    required DateTime today,
  }) {
    final thisWeek = weekStartOf(today);
    final lastWeek = thisWeek.subtract(const Duration(days: 7));

    final days = <DateTime>{};
    var sets = 0;
    var volume = 0.0;
    var previousVolume = 0.0;
    final setsByExercise = <String, int>{};
    String? busiest;

    for (final log in logs) {
      for (final session in log.progress.sessions) {
        if (!session.day.isBefore(thisWeek)) {
          days.add(session.day);
          sets += session.sets;
          volume += session.volumeKg;

          final total = (setsByExercise[log.exercise.name] ?? 0) + session.sets;
          setsByExercise[log.exercise.name] = total;
          if (busiest == null || total > setsByExercise[busiest]!) {
            busiest = log.exercise.name;
          }
        } else if (!session.day.isBefore(lastWeek)) {
          previousVolume += session.volumeKg;
        }
      }
    }

    return TrainingSummary(
      trainingDays: days.length,
      sets: sets,
      volumeKg: volume,
      previousVolumeKg: previousVolume,
      busiestExercise: busiest,
    );
  }

  static const empty = TrainingSummary(
    trainingDays: 0,
    sets: 0,
    volumeKg: 0,
    previousVolumeKg: 0,
    busiestExercise: null,
  );

  /// Days trained this week, not sessions — two exercises on one day is one
  /// day in the gym.
  final int trainingDays;

  final int sets;
  final double volumeKg;

  /// Last week's volume, for the comparison.
  final double previousVolumeKg;

  /// The exercise with the most sets this week, or null for a quiet week.
  final String? busiestExercise;

  bool get hasTrained => trainingDays > 0;

  /// This week's volume against last week's, as a fraction.
  ///
  /// Null when there is nothing to compare against — a first week has not got
  /// better or worse, it has just started.
  double? get volumeChange {
    if (previousVolumeKg == 0) return null;
    return (volumeKg - previousVolumeKg) / previousVolumeKg;
  }

  @override
  List<Object?> get props => [
    trainingDays,
    sets,
    volumeKg,
    previousVolumeKg,
    busiestExercise,
  ];
}
