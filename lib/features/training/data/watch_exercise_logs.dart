import 'package:dream_gym/core/streams/combine_latest.dart';
import 'package:dream_gym/features/exercises/data/exercise_repository.dart';
import 'package:dream_gym/features/training/data/training_repository.dart';
import 'package:dream_gym/features/training/domain/exercise_log.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:dream_gym/features/training/domain/training_entry.dart';

/// Every exercise with its progress, re-emitted whenever either table changes.
///
/// The grouping happens in Dart rather than SQL. A training log is small, and
/// this way the exercises list, the exercise screen and the statistics screen
/// all read the same numbers computed by the same code — which is what keeps
/// 'best' on one screen from disagreeing with 'best' on another.
Stream<List<ExerciseLog>> watchExerciseLogs({
  required ExerciseRepository exercises,
  required TrainingRepository training,
}) {
  return combineLatest2(exercises.watchAll(), training.watchAll(), (
    exerciseList,
    entries,
  ) {
    final byExercise = <String, List<TrainingEntry>>{};
    for (final entry in entries) {
      byExercise.putIfAbsent(entry.exerciseId, () => []).add(entry);
    }

    return [
      for (final exercise in exerciseList)
        ExerciseLog(
          exercise: exercise,
          progress: ExerciseProgress.fromEntries(
            byExercise[exercise.id] ?? const [],
          ),
        ),
    ];
  });
}
