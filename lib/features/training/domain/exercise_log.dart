import 'package:dream_gym/features/exercises/domain/exercise.dart';
import 'package:dream_gym/features/training/domain/exercise_progress.dart';
import 'package:equatable/equatable.dart';

/// An exercise together with everything logged against it.
///
/// The pair the screens actually want: a list of exercises is not useful
/// without 'last trained', and a chart is not useful without the name above it.
final class ExerciseLog extends Equatable {
  const ExerciseLog({required this.exercise, required this.progress});

  final Exercise exercise;
  final ExerciseProgress progress;

  /// The most recent session, or null for an exercise that has been added but
  /// never trained.
  TrainingSession? get latest => progress.latest;

  @override
  List<Object?> get props => [exercise, progress];
}
